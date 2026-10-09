# Étude de cas : « La facture qui explose » (TP9)

Ce code Terraform décrit l'environnement **dev** de l'application *Catalogue* d'une
entreprise fictive. La facture mensuelle de ce seul environnement dépasse le budget
de l'équipe. **Ne le déployez pas** : l'analyse se fait avec `infracost breakdown`
et par revue de code.

Mission :
1. Estimer le coût actuel : `infracost breakdown --path . --format table`
2. Identifier au moins 10 sources de gaspillage (revue de code + checklist du cours)
3. Corriger le code dans une branche, puis mesurer : `infracost diff --path . --compare-to base.json`
4. Rédiger le rapport FinOps (modèle dans le cahier de TP)

Contraintes métier à respecter : l'environnement sert à 6 développeurs, du lundi au
vendredi, de 8 h à 19 h. Il n'y a aucune exigence de disponibilité ni de reprise
après sinistre en dev. Les données sont synthétiques.
