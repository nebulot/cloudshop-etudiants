# ADR-001 : choix de la région Azure

- **Statut** : accepté
- **Date** : 2026-10-09
- **Décideurs** : groupe CloudShop

## Contexte

CloudShop doit héberger son environnement principal en Europe, avec une latence raisonnable pour des utilisateurs européens et une offre Azure suffisamment large. L'abonnement Azure for Students impose de limiter les ressources actives, les SKU coûteux et les régions déployées.

## Décision

Nous choisissons **West Europe** comme région primaire. **North Europe** est retenue comme région de reprise potentielle pour la production, sans être déployée dans le socle dev.

Les ressources seront taguées avec leur environnement et leur région. Le profil étudiant utilise une seule région et des réplications LRS ou locales pour le dev. North Europe reste une option de reprise à chiffrer et à activer seulement lorsque le besoin de disponibilité, les quotas et le crédit restant seront vérifiés dans le portail Azure.

## Raisons

- proximité des utilisateurs et latence adaptée à un marché européen ;
- catalogue Azure suffisamment large pour Storage, Container Apps, SQL Database et Monitor ;
- compatibilité avec une stratégie de continuité vers North Europe ;
- conformité et gouvernance plus simples avec des données hébergées dans l'Union européenne.

## Alternatives écartées

- **North Europe primaire** : techniquement viable, mais moins proche de la population cible supposée ; aucun gain fonctionnel suffisant.
- **France Central** : intéressante pour la proximité et la résidence en France, mais disponibilité des SKU, quotas et coût doivent être vérifiés dans l'abonnement étudiant avant de la préférer.
- **Multi-région dès le dev** : coût et complexité disproportionnés, sans exigence de disponibilité dev.

## Conséquences

- Un incident régional peut interrompre la production mono-région.
- Une bascule vers North Europe demandera une réplication testée, du routage global et des runbooks.
- Les tarifs, quotas et SLA doivent être revérifiés pour les SKU réellement choisis.
