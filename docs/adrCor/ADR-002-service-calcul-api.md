# ADR-002 : choix du service de calcul de l'API

- **Statut** : accepté
- **Date** : 2026-10-09
- **Décideurs** : groupe CloudShop

## Contexte

L'API CloudShop doit être déployable par CI/CD, fonctionner sans serveur administré par l'équipe, pouvoir revenir à zéro en dev et monter en charge en production. Le dépôt prépare déjà un fournisseur Azure et l'application est destinée à être conteneurisée. Le crédit Azure for Students impose de ne pas maintenir un serveur ou plusieurs réplicas en permanence.

## Décision

Nous choisissons **Azure Container Apps** pour héberger l'API HTTP conteneurisée.

L'image sera construite par GitHub Actions puis publiée dans Azure Container Registry. Container Apps recevra une identité managée, des probes HTTP, une règle d'autoscaling et des variables de configuration sans secrets dans l'image. Le profil Azure Student utilise la consommation et le scale-to-zero ; plusieurs réplicas permanents sont réservés à une production financée après estimation du coût.

## Raisons

- abstraction serveur adaptée à une petite équipe ;
- déploiement de révisions et retour arrière simples ;
- autoscaling et scale-to-zero adaptés au budget étudiant ;
- intégration native avec logs, identité managée et réseau Azure ;
- modèle de conteneur portable si le service doit évoluer.

## Alternatives écartées

- **Azure Functions** : excellent pour des traitements événementiels, mais moins naturel pour une API conteneurisée avec contrôle des révisions et du runtime.
- **Azure App Service** : option valide et simple, mais moins adaptée au scale-to-zero et aux déploiements de conteneurs révisables visés ici.
- **VM/VM Scale Set** : contrôle maximal, mais coût fixe, patching, haute disponibilité et exploitation disproportionnés pour un abonnement étudiant.
- **AKS** : trop complexe et coûteux pour la taille du projet ; la gestion du cluster deviendrait une charge principale.

## Conséquences

- Le premier appel dev peut subir la latence d'un réveil après scale-to-zero.
- Le conteneur doit être stateless ; les données vont dans SQL/Storage.
- Les performances et le coût dépendront du nombre de réplicas, du CPU/mémoire et du trafic.
- Une panne régionale n'est pas couverte par une seule Container App : le multi-région reste une évolution documentée dans `docs/sla.md`.
