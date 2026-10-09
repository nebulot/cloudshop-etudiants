#!/usr/bin/env bash
# =============================================================================
# CloudShop - Bootstrap (à exécuter UNE fois, en local, après `az login`)
#   1. Enregistre les Resource Providers nécessaires
#   2. Crée le stockage du state Terraform (RG + Storage Account + container)
#   3. Crée une identité managée (UAMI) pour GitHub Actions + credentials OIDC
#   4. Attribue les rôles (moindre privilège "raisonnable" pour un lab)
#
# Usage : ./bootstrap.sh <region> <github_owner/repo>
#   ex.  ./bootstrap.sh swedencentral jdupont/cloudshop
# =============================================================================
set -euo pipefail

LOCATION="${1:?Région requise (ex. swedencentral)}"
REPO="${2:?Dépôt GitHub requis (ex. jdupont/cloudshop)}"

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
ME=$(az ad signed-in-user show --query id -o tsv)
SUFFIX=$(echo -n "$SUB_ID" | sha1sum | cut -c1-4)

RG_STATE="rg-cloudshop-tfstate"
ST_STATE="stcloudshoptf${SUFFIX}"
UAMI="id-cloudshop-github"
TAGS="project=cloudshop environment=shared owner=$(az account show --query user.name -o tsv) cost-center=4OLEN managed-by=bootstrap"

echo ">> Souscription : $SUB_ID  | Région : $LOCATION"

echo ">> 1/4 Enregistrement des Resource Providers"
for rp in Microsoft.App Microsoft.OperationalInsights Microsoft.Sql Microsoft.Storage \
          Microsoft.ManagedIdentity Microsoft.Consumption Microsoft.Insights; do
  az provider register --namespace "$rp" --output none
done

echo ">> 2/4 Stockage du state Terraform"
az group create -n "$RG_STATE" -l "$LOCATION" --tags $TAGS --output none
az storage account create -n "$ST_STATE" -g "$RG_STATE" -l "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false \
  --tags $TAGS --output none
ST_ID=$(az storage account show -n "$ST_STATE" -g "$RG_STATE" --query id -o tsv)

# Versioning = filet de sécurité si le state est corrompu
az storage account blob-service-properties update --account-name "$ST_STATE" \
  -g "$RG_STATE" --enable-versioning true --output none

# Owner n'inclut PAS les droits "data plane" : on se donne Storage Blob Data Contributor
az role assignment create --assignee "$ME" --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUB_ID" --output none || true
echo "   (attente propagation RBAC 30 s)"; sleep 30
az storage container create -n tfstate --account-name "$ST_STATE" --auth-mode login --output none

echo ">> 3/4 Identité managée pour GitHub Actions (OIDC, sans secret)"
az identity create -n "$UAMI" -g "$RG_STATE" -l "$LOCATION" --tags $TAGS --output none
CLIENT_ID=$(az identity show -n "$UAMI" -g "$RG_STATE" --query clientId -o tsv)
PRINCIPAL_ID=$(az identity show -n "$UAMI" -g "$RG_STATE" --query principalId -o tsv)

declare -A SUBJECTS=(
  [gh-main]="repo:${REPO}:ref:refs/heads/main"
  [gh-pr]="repo:${REPO}:pull_request"
  [gh-env-dev]="repo:${REPO}:environment:dev"
  [gh-env-prod]="repo:${REPO}:environment:prod"
)
for name in "${!SUBJECTS[@]}"; do
  az identity federated-credential create -n "$name" --identity-name "$UAMI" -g "$RG_STATE" \
    --issuer "https://token.actions.githubusercontent.com" \
    --subject "${SUBJECTS[$name]}" --audiences "api://AzureADTokenExchange" --output none
done

echo ">> 4/4 Rôles de l'identité GitHub"
for role in "Contributor" "Resource Policy Contributor" "Storage Blob Data Contributor"; do
  az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
    --role "$role" --scope "/subscriptions/$SUB_ID" --output none
done

cat <<OUT

=====================================================================
 Bootstrap terminé. À reporter :

 terraform/env/*.backend.hcl
   storage_account_name = "$ST_STATE"

 GitHub > Settings > Secrets and variables > Actions > Variables
   AZURE_CLIENT_ID       = $CLIENT_ID
   AZURE_TENANT_ID       = $TENANT_ID
   AZURE_SUBSCRIPTION_ID = $SUB_ID
   TFSTATE_STORAGE       = $ST_STATE
=====================================================================
OUT
