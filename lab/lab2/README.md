# Lab 2 — Managing Infrastructure as Code (IaC)

## TD2 — Bash

### Fichiers
- `td2/scripts/bash/user-data.sh`
- `td2/scripts/bash/deploy-ec2-instance.sh`

### Questions / Réponses
## Exercice 1 — Que se passe-t-il si on exécute le script une seconde fois ?

Lors de la seconde exécution du script, celui-ci échoue lors de la création du *Security Group*.

AWS retourne une erreur indiquant qu’un *Security Group* avec le même nom existe déjà.

Cela s’explique par le fait que certaines ressources AWS, comme les *Security Groups*, doivent avoir un **nom unique dans un même VPC**.
Dans le script, le nom est fixé en dur :

```bash
--group-name "sample-app" 
```

## Exercice 2 — Déployer plusieurs instances EC2

Pour déployer plusieurs instances EC2, le script peut être modifié afin de lancer plusieurs instances simultanément.

Une première approche consiste à définir une variable indiquant le nombre d'instances :

```bash
COUNT=3
```

Puis à utiliser l'option `--count` de la commande AWS CLI :

```bash
aws ec2 run-instances --count $COUNT
```

Une autre solution consiste à utiliser une boucle, par exemple une boucle `for`, afin de lancer plusieurs instances successivement.

**Points importants :**
- Le Security Group doit être créé une seule fois et partagé entre toutes les instances.
- Le script doit également récupérer et afficher les valeurs `InstanceId` et `PublicIpAddress` de chaque instance déployée.

Un Security Group doit avoir un nom unique dans un même VPC.

Conclusion

Le script Bash n’est pas idempotent.
Il ne vérifie pas l’existence préalable des ressources.

## Exercice 2 — Déployer plusieurs instances EC2

Deux solutions sont possibles :

Solution 1 — Utiliser `--count`

```bash
aws ec2 run-instances --count 3
```

Solution 2 — Utiliser une boucle

```bash
for i in {1..3}; do
	aws ec2 run-instances ...
done
```

Points importants

Le Security Group doit être créé une seule fois.

Il faut récupérer les `InstanceId` et `PublicIpAddress` de chaque instance.

## Section 3 — Ansible

Un playbook Ansible a été utilisé pour :

- Créer un Security Group
- Créer une Key Pair
- Déployer une instance EC2
- Configurer l’instance via un rôle

L’inventory dynamique `amazon.aws.aws_ec2` a été utilisé.

## Exercice 3 — Que se passe-t-il si on exécute la configuration deux fois ?

Lorsque le playbook est exécuté une seconde fois :

- Les ressources existantes ne sont pas recréées.
- Les tâches déjà appliquées sont ignorées.
- Aucun doublon n’est généré.

Conclusion

Ansible est idempotent par conception.
Contrairement à Bash, il vérifie l’état avant d’appliquer les modifications.

## Section 4 — Packer

Packer a été utilisé pour créer une AMI personnalisée.

Commandes exécutées

```bash
packer init sample-app.pkr.hcl
packer build sample-app.pkr.hcl
```

Résultat

AMI créée :

```text
ami-087fd4fcbe3c24a8b
```

Région : eu-north-1

## Exercice 4 — Que se passe-t-il si on exécute packer build deux fois ?

Chaque exécution crée une nouvelle AMI.

Cela s’explique par :

```hcl
ami_name = "sample-app-packer-${uuidv4()}"
```

Le `uuidv4()` garantit un nom unique à chaque build.

Conclusion

Packer produit une infrastructure immutable :
chaque build génère une nouvelle image.

## Section 5 — OpenTofu

OpenTofu a été utilisé pour :

- Déployer une instance EC2
- Utiliser l’AMI créée avec Packer
- Créer un Security Group
- Exposer la `public_ip` via un output

## Exercice 5 — Déployer l’infrastructure

Initialisation

```bash
tofu init
```

Application

```bash
tofu apply
```

AMI utilisée :

```text
ami-087fd4fcbe3c24a8b
```

## Exercice 6 — Tester le déploiement

Récupération de l’IP

```bash
tofu output
```

Résultat :

```text
public_ip = "51.20.105.56"
```

Test HTTP

```text
http://51.20.105.56:8080
```

Résultat :

Connection refused

Explication

Le Security Group autorise bien le port 8080.
Aucun service n’écoute sur ce port.
L’AMI contient le fichier applicatif mais ne lance pas automatiquement Node.js.
L’infrastructure est correcte, mais l’application n’est pas démarrée.

## Exercice 7 — Mettre à jour la configuration

Un nouveau tag a été ajouté :

```hcl
tags = {
	Name = "sample-app-tofu"
	Test = "update"
}
```

Après :

```bash
tofu apply
```

OpenTofu effectue une mise à jour in place.

Conclusion

OpenTofu fonctionne de manière déclarative :
il compare l’état souhaité à l’état actuel.

## Exercice 8 — Détruire l’infrastructure

```bash
tofu destroy
```

Toutes les ressources ont été supprimées correctement.

## Section 6 — Modules

## Exercice 9 — Créer et utiliser un module

La configuration EC2 a été transformée en module réutilisable.

Exemple :

```hcl
module "sample_app_1" {
	source = "./modules/ec2"
}

module "sample_app_2" {
	source = "./modules/ec2"
}
```

Avantages

Réutilisation du code

Meilleure organisation

Scalabilité

