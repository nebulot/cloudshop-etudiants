# Matrice WAF CloudShop

> Version du 9 octobre 2026. Cette matrice décrit l'architecture cible documentée dans `docs/architecture.png` ; elle ne prétend pas décrire des ressources déjà déployées.

| Pilier WAF | Choix retenus | Risques résiduels | Impact coût |
|---|---|---|---|
| **Excellence opérationnelle** | Infrastructure as Code Bicep/Terraform ; CI/CD GitHub Actions avec OIDC ; séparation dev/prod ; Azure Monitor, Log Analytics et Application Insights ; alertes sur disponibilité, erreurs API et saturation SQL. | Déploiement initial encore incomplet ; runbooks et astreinte à formaliser ; une mauvaise règle d'alerte peut générer du bruit. | Log Analytics et Application Insights sont facturés à l'ingestion et à la rétention. Les pipelines et OIDC ont un coût Azure nul ou négligeable, mais demandent du temps d'exploitation. |
| **Sécurité** | Identités managées et Entra ID ; aucun secret dans Git ; Storage avec Azure AD/RBAC et HTTPS ; Private Endpoint pour SQL ; réseau contrôlé ; Defender for Cloud selon le budget ; journalisation des accès. | Configuration IAM trop large, compromission d'un compte GitHub ou absence de rotation des certificats ; le frontend statique est public par conception ; les coûts peuvent retarder l'activation de Defender. | Private Endpoints, pare-feu, Defender for Cloud, Key Vault et journaux supplémentaires augmentent le coût fixe et la consommation réseau. |
| **Fiabilité** | Container Apps avec plusieurs réplicas et probes ; SQL Database Business Critical zone-redundant ; stockage GZRS ; sauvegardes SQL et restauration testée ; Front Door pour l'entrée globale en production. | Une seule région reste un domaine de panne pour l'API et SQL ; dépendance aux quotas Azure et à la région choisie ; sauvegarde != reprise instantanée. | Réplication par zones et GZRS coûtent plus qu'un stockage LRS. Une seconde région active-active est le principal saut de coût pour viser 99,9 % de bout en bout. |
| **Efficacité des performances** | CDN/Front Door pour les fichiers statiques ; cache HTTP ; API stateless et autoscaling Container Apps ; index SQL et limites de requêtes ; tests de charge avant production. | Un scale-to-zero peut ajouter de la latence ; les mauvais index ou une explosion des logs peuvent dégrader les performances ; le cache doit être invalidé lors des versions. | Le CDN et les sorties réseau sont variables selon le trafic ; plusieurs réplicas permanents augmentent le coût de calcul mais réduisent la latence de réveil. |
| **Optimisation des coûts** | Consumption/scale-to-zero en dev ; extinction dev hors horaires ; budgets et alertes ; tags `environment`, `owner`, `cost-center` ; rétention de logs limitée ; revue Infracost dans les pull requests. | Le scale-to-zero dégrade le premier appel ; les estimations ne couvrent pas toujours les frais réseau ; les alertes ne bloquent pas une dépense. | Dev reste peu coûteux. En prod, le multi-région, les réplicas minimaux, Front Door et la rétention longue augmentent le coût récurrent ; le coût exact dépend du trafic et de la région. |
|
| **Durabilité** | Données persistantes séparées du compute ; Storage GZRS ; sauvegardes SQL avec politique de rétention ; tests périodiques de restauration ; données synthétiques en dev. | Perte possible entre deux sauvegardes ; suppression logique ou corruption applicative répliquée ; GZRS ne remplace pas une stratégie de restauration testée. | GZRS, sauvegardes longues et réplication inter-région augmentent le stockage et les transactions ; les exercices de restauration consomment du compute temporaire. |

## Priorités de mise en œuvre

1. Déployer l'IaC avec identités managées, RBAC minimal et diagnostics activés.
2. Ajouter des probes et une alerte de disponibilité API avant toute mise en production.
3. Tester une restauration SQL et un scénario de panne de zone.
4. Mesurer le trafic réel avant de choisir le nombre minimal de réplicas et le niveau de réplication.

## Hypothèses

- La région primaire est `West Europe`, avec `North Europe` comme région de secours.
- Le frontend est un site statique Storage ; l'API est conteneurisée dans Azure Container Apps.
- Les chiffres de SLA sont des engagements publiés, pas une garantie de disponibilité applicative complète : le code, le DNS, les dépendances et les opérations restent dans le périmètre de risque.
