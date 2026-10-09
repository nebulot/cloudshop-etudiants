# CloudShop — dépôt de départ (étudiants)

Ce dépôt contient le minimum pour démarrer. Vous le compléterez séance après séance :

| Dossier | Fourni | À produire |
|---|---|---|
| `app/` | Frontend statique | — |
| `bootstrap/` | Script d'amorçage (state + OIDC) | — (à lire et comprendre !) |
| `bicep/` | — | TP4 : `main.bicep`, modules, fichiers `.bicepparam` |
| `terraform/` | `versions.tf`, `providers.tf`, backends | TP5–TP8 : racine, modules, tfvars |
| `.github/workflows/` | — | TP7–TP8 : CI, CD, extinction, dérive |
| `finops/` | API Retail Prices + jeu FOCUS fictif | TP3 : analyse + note FinOps |
| `cas-facture-explose/` | Code volontairement coûteux | TP9 : audit + correctifs |

Règle d'or : **toute ressource créée pendant une séance est détruite en fin de séance**
(`terraform destroy`, `az group delete`). Votre crédit Azure for Students est limité.
