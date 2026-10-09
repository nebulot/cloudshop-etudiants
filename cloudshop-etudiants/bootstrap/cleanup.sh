#!/usr/bin/env bash
# Supprime TOUT ce que CloudShop a créé (fin de module). Irréversible.
set -euo pipefail
for rg in $(az group list --query "[?tags.project=='cloudshop'].name" -o tsv); do
  echo "Suppression de $rg"; az group delete -n "$rg" --yes --no-wait
done
echo "Suppressions lancées (asynchrones). Vérifier : az group list -o table"
