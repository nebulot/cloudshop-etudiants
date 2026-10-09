**Calcul du SLA composite actuel**

\=> Le calcul du SLA composite nécessite de multiplier les SLA individuels de chaque composant de l'architecture de production (App Service pour l'application et le Storage Account en mode LRS pour les données/blobs persistants).

- Azure App Service (niveaux Standard/Premium) : 99,95 %.
- Azure Storage Account (Standard_LRS - Blobs chauds/froids) : 99,90 % pour les requêtes d'écriture/lecture.

SLA Composite=99,95%×99,90%=𝟗𝟗,𝟖𝟓%

\=> L'objectif de 99,5 % est-il atteint ?  
Oui, l'objectif initial de 99,5 % est largement atteint, car l'architecture actuelle offre contractuellement une disponibilité théorique de 99,85 % (soit environ 1 heure et 5 minutes d'indisponibilité maximale tolérée par mois).

\=> Que faudrait-il pour atteindre 99,9 % ?

Pour élever le SLA composite à au moins 99,9 %, il faut impérativement éliminer le point faible actuel : la réplication locale (LRS) du compte de stockage, qui stagne à 99,90 % et tire l'ensemble vers le bas.

\=> Évolution technique requise

Il est nécessaire de passer le compte de stockage de Standard_LRS à Standard_ZRS (Stockage redondant de zone). Le passage en ZRS fait grimper le SLA du stockage Azure à 99,99 % pour les écritures et lectures.

Le nouveau calcul devient :  
Nouveau sla composite = 99,95 % (App Service) x 99 ,99% (Storage ZRS) = 99,94 %

Ce changement permet de dépasser l'objectif cible et d'atteindre 99,94 % de disponibilité globale.

Combien cela coûterait-il ?

**1\. Tableau détaillé : Option Mono-Région (West Europe)**

_Cette option s'appuie sur la redondance de zone (Zone-Redundant). Elle couvre largement l'objectif initial de 99,5 % avec un SLA composite théorique de_ **_99,925 %_**_._

| **Service Azure**        | **Configuration / Métrique**                                        | **Coût Mensuel Estimé** | **Part du Budget** |
| ------------------------ | ------------------------------------------------------------------- | ----------------------- | ------------------ |
| **Azure SQL Database**   | Business Critical, 2 vCores provisionnés, Redondance de zone        | **410 €**               | 77,1 %             |
| **Azure Container Apps** | Mode Consumption, 2 réplicas permanents pour éviter le _cold start_ | **45 €**                | 8,5 %              |
| **Sécurité & Réseau**    | 2 Private Endpoints, Azure Key Vault, Règles réseau                 | **25 €**                | 4,7 %              |
| **Azure Front Door**     | Niveau Standard (Inclut la base fixe + 100 Go de trafic sortant)    | **32 €**                | 6,0 %              |
| **Azure Storage**        | 100 Go de Blobs + Site Statique en Stockage GZRS                    | **10 €**                | 1,9 %              |
| **Azure Monitor**        | Log Analytics & Application Insights (Ingestion de logs modérée)    | **10 €**                | 1,8 %              |
| **TOTAL MONO-RÉGION**    | _Disponibilité intra-régionale hautement sécurisée_                 | **~532 € / mois**       | **100 %**          |

**2\. Tableau détaillé : Option Multi-Région Active-Active (West Europe + North Europe)**

_Cette option élimine le risque d'une panne complète de région pour viser un engagement de_ **_99,9 % de bout en bout_**_._

| **Service Azure**        | **Configuration / Impact de la réplication**                            | **Coût Mensuel Estimé** | **Augmentation / Option LRS** |
| ------------------------ | ----------------------------------------------------------------------- | ----------------------- | ----------------------------- |
| **Azure SQL Database**   | 2 bases Business Critical synchronisées (Géo-réplication active)        | **820 €**               | +100 %                        |
| **Azure Container Apps** | Duplication des instances de calcul actives dans les deux régions       | **90 €**                | +100 %                        |
| **Sécurité & Réseau**    | Endpoints doublés + Coût du trafic réseau inter-région (Egress)         | **55 €**                | +120 %                        |
| **Azure Front Door**     | Routage actif/actif vers deux régions (Transactions supplémentaires)    | **42 €**                | +31 %                         |
| **Azure Storage**        | Passage au stockage RA-GZRS (Accès en lecture sur la région secondaire) | **15 €**                | +50 %                         |
| **Azure Monitor**        | Centralisation et ingestion des logs des deux infrastructures           | **25 €**                | +150 %                        |
| **TOTAL MULTI-RÉGION**   | _Résilience absolue contre le sinistre d'une région entière_            | **~1 047 € / mois**     | **+96,8 %**                   |

**Synthèse comparative : Arbitrage SLA vs Budget**

Ce tableau final synthétise les indicateurs clés pour vous aider à arbitrer entre le coût financier et le niveau de résilience requis pour l'application.

| **Indicateur Économique & Technique**  | **Option Standard Target (Mono-Région)**   | **Option Haute Disponibilité (Multi-Région)** |
| -------------------------------------- | ------------------------------------------ | --------------------------------------------- |
| **SLA Composite Théorique**            | **99,925 %**                               | **\> 99,99 %** (Théorique)                    |
| **Garantie Réelle de Bout en Bout**    | ~99,8 % _(sensible aux pannes de régions)_ | **99,9 %** _(couvre la perte d'une région)_   |
| **Temps d'indisponibilité max / mois** | ~33 minutes                                | **~4 minutes**                                |
| **Coût Mensuel Global**                | **532 € / mois**                           | **1 047 € / mois**                            |
| **Coût Annuel Estimé**                 | **6 384 € / an**                           | **12 564 € / an**                             |
| **Surcoût Net pour le 99,9 %**         | _Ligne de base_                            | **+515 € / mois** _(Budget presque doublé)_   |