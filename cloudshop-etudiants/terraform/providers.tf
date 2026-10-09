provider "azurerm" {
  # En local : pris depuis `az login` / ARM_SUBSCRIPTION_ID.
  # En CI : ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID + ARM_USE_OIDC=true.
  subscription_id = var.subscription_id

  # azurerm v5 : plus aucun Resource Provider n'est enregistré par défaut.
  # On n'enregistre que ce dont CloudShop a besoin.
  resource_providers_to_register = [
    "Microsoft.App",
    "Microsoft.OperationalInsights",
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.Consumption",
    "Microsoft.Insights",
  ]

  # Utilise Entra ID (et non les clés d'accès) pour le plan de données Storage
  storage_use_azuread = true

  features {
    resource_group {
      # Sécurité pédagogique : refuse de supprimer un RG contenant des ressources non gérées
      prevent_deletion_if_contains_resources = true
    }
  }
}
