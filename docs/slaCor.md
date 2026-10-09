# SLA composite de CloudShop

> Calcul basé sur la page officielle Microsoft des SLA, consultée le 9 octobre 2026 : [Service Level Agreements for Online Services](https://azure.microsoft.com/en-us/support/legal/sla/). Les valeurs doivent être revérifiées au moment du déploiement, car Microsoft peut modifier les conditions ou les SKU.

## Périmètre retenu

Le chemin critique de production est :

`Client -> Azure Storage Static Website -> Azure Container Apps API -> Azure SQL Database`

Le stockage objet métier est répliqué en GZRS mais n'est pas appelé pour chaque requête ; il est donc traité comme une dépendance de durabilité, pas comme un composant de disponibilité du chemin HTTP. Azure Monitor est également hors chemin critique.

## Valeurs publiées utilisées

| Composant | Configuration cible | SLA publié retenu |
|---|---|---:|
| Azure Storage Static Website | compte Standard, LRS, site statique | 99,9 % |
| Azure Container Apps | environnement de production avec plusieurs réplicas | 99,95 % |
| Azure SQL Database | niveau Business Critical, zone redundant | 99,995 % |

Les garanties s'appliquent aux conditions détaillées dans les documents Microsoft (région, SKU, configuration et définition de disponibilité). Elles ne garantissent pas l'application complète.

## Calcul

Pour des dépendances séquentielles indépendantes, on utilise le produit des disponibilités :

$$
SLA_{composite} = 0{,}999 \times 0{,}9995 \times 0{,}99995
                  = 0{,}9984506
                  \approx 99{,}845\,%
$$

Le budget d'indisponibilité théorique sur 30 jours vaut donc environ **67 minutes** :

$$
30 \times 24 \times 60 \times (1 - 0{,}9984506) \approx 66{,}9\ \text{minutes}
$$

### Conclusion sur l'objectif 99,5 %

Oui. **99,845 % est supérieur à 99,5 %**, avec une marge théorique de 0,345 point. Le résultat reste un calcul de capacité théorique : une erreur de déploiement, une panne DNS, un bug ou une dépendance externe peut faire baisser le SLA observé.

## Atteindre 99,9 %

Le composant limitant est le site statique LRS à 99,9 %. Une cible plus robuste est :

- Azure Front Door Standard pour l'entrée globale et le routage vers des origines saines ;
- frontend publié dans deux régions avec stockage redondant inter-région (GZRS/RA-GZRS selon le besoin de lecture) ;
- API Container Apps déployée dans `West Europe` et `North Europe`, avec réplicas minimaux non nuls ;
- réplication et stratégie de bascule SQL documentées et testées.

Avec, à titre de borne de calcul, Front Door à 99,99 %, API à 99,95 % et SQL à 99,995 % :

$$
0{,}9999 \times 0{,}9995 \times 0{,}99995
= 0{,}9993503
\approx 99{,}935\,%
$$

Cette architecture dépasse donc 99,9 % sur le papier, sous réserve que le mécanisme de bascule soit lui-même opérationnel.

## Estimation de coût additionnel

Il n'est pas possible de donner un prix exact sans région de facturation, trafic, stockage, nombre de réplicas et durée d'exécution. Ordre de grandeur mensuel **hors volume de données et hors licence éventuelle** :

| Ajout pour la cible 99,9 % | Estimation mensuelle |
|---|---:|
| Front Door Standard, domaine et règles de routage | 35 à 60 EUR + requêtes et sortie réseau |
| Second environnement Container Apps, minimum 1 réplique | 30 à 150 EUR selon CPU, mémoire et trafic |
| Stockage GZRS/RA-GZRS au lieu de LRS | environ +20 à +60 % sur la partie Storage |
| Réplication/fonctionnalités SQL multi-région ou secondaire | environ 300 à 900 EUR selon niveau et taille |
| **Surcoût total de planification** | **environ 400 à 1 200 EUR/mois** |

Cette fourchette est une enveloppe de décision, pas un devis. Le prix doit être confirmé avec le [calculateur Azure](https://azure.microsoft.com/en-us/pricing/calculator/) et une estimation réelle de trafic. Pour un projet étudiant, le compromis recommandé est de démontrer 99,5 % avec une seule région et de chiffrer le multi-région comme évolution de production.
