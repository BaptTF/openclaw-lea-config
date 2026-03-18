# Infrastructure et Déploiement (GitOps)

**AVIS DE MIGRATION : Les fichiers de configuration de l'infrastructure ne sont plus hébergés dans ce dépôt.**

Afin de nous conformer aux meilleures pratiques de l'approche GitOps (principe de la source de vérité unique) et de centraliser la gestion de notre infrastructure, l'ensemble de la configuration de déploiement de l'application **Openclaw** a été migré.

## Localisation de la configuration

L'état désiré de l'infrastructure et les manifestes de déploiement (fichiers YAML) associés à ce projet sont désormais gérés de manière centralisée. Vous pouvez les consulter et les modifier dans le dépôt dédié à l'infrastructure :

* **Dépôt d'infrastructure :** [BaptTF/vps-infra](https://github.com/BaptTF/vps-infra)
* **Répertoire cible :** [`workloads/openclaw`](https://github.com/BaptTF/vps-infra/tree/HEAD/workloads/openclaw)
* **Branche de référence :** `HEAD`

## Procédure de modification

Toute intervention sur la configuration nécessitant, à titre non exhaustif :
- La modification des variables d'environnement
- L'ajustement des allocations de ressources (CPU/RAM)
- La modification des règles de routage (Ingress) ou des services réseaux

Doit impérativement faire l'objet d'une soumission (Commit / Pull Request) directement dans le répertoire `workloads/openclaw` du dépôt `vps-infra`.

---
*Note concernant le déploiement continu (CD) : Le pipeline CI/CD construit et pousse automatiquement les nouvelles images avec le tag `latest`. L'infrastructure étant configurée pour pointer vers ce tag, aucune mise à jour des fichiers YAML n'est requise dans le dépôt d'infrastructure lors d'un nouveau déploiement.*