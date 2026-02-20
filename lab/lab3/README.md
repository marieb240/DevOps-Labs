# Lab 3 - Server Orchestration with Ansible

## Objectifs

Dans ce lab, l’objectif est de tester plusieurs méthodes d’orchestration : 

- Orchestration serveur avec Ansible
- Orchestration VM avec Packer + OpenTofu
- Orchestration conteneur avec Docker + Kubernetes
- Orchestration serverless avec AWS Lambda

L’idée est de comprendre les différences entre chaque approche et voir comment gérer le déploiement d’une application de manière progressive et automatisée.

Important : toute l’infrastructure a été déployée dans la région eu-north-1, avec l’AMI : 

```
ami-0836abe45b78b6960
```

## Partie 1 – Server Orchestration with Ansible 

### Step 1 - Set Up the Ansible Environment
Nous instalons la collection AWS avec la commande suivante : 

```
ansible-galaxy collection install amazon.aws
```

![Exécution locale](/lab/lab3/screenshots/upload_amazonaws.png) 

Cela permet à Ansible d’utiliser les modules AWS (EC2, security group, etc).

Puis nous avons utilisé la configuration via AWS CLI :

```
aws configure
```
Ce qui nous donne : 

![Exécution locale](/lab/lab3/screenshots/aws_configure.png) 


### Step 2 - Creating EC2 Instances with Ansible 

On crée un fichier de variables `sample-app-vars.yml`, où l'on déploie 3 instances pour simuler une application distribuée, puis nous lançons le playbook avec la commande : 

```
ansible-playbook -v create_ec2_instances_playbook.yml --extra-vars "@sample-app-vars.yml"
```
![Exécution locale](/lab/lab3/screenshots/playbook.png) 

Et on peut les voir dans note console EC2 : 

![Exécution locale](/lab/lab3/screenshots/console_EC2.png) 

### Step 3 - Configuring Dynamic Inventory 

Nous créons les fichiers comme précisés dans le PDF qui vont nous permettre d'utiliser un inventaire dynamique. 
Cet inventaire a pour but d'éviter d’écrire les IP à la main et que si les instances changent, Ansible les détecte automatiquement via les tags.

Pour tester cet inventaire, on utilise la commande test donnée par Copilot : 
```
ansible-inventory -i inventory.aws_ec2.yml --graph
``` 
![Exécution locale](/lab/lab3/screenshots/inventory.png) 

On voit bien le groupe `@sample_app_instances`.


### Step 4 - Deploying the Sample Node.js Application 

Lors du déploiement, une erreur est apparue pendant la tâche `Copy sample app`.
Ansible affichait un message lié à un problème de permissions sur les fichiers temporaires (`chmod: invalid mode: 'A+user:app-user:rx:allow'`).

Ce problème venait de l’utilisation de `become_user: app-user`, combiné à la gestion des fichiers temporaires d’Ansible sur notre environnement local (WSL/Ubuntu).

Pour corriger cela, nous avons ajouté un fichier `ansible.cfg` dans le dossier du lab avec la configuration suivante :

```
[defaults]
allow_world_readable_tmpfiles = True
remote_tmp = /tmp/.ansible-${USER}

[ssh_connection]
pipelining = True
```
Après cela, nous avons bine nos 3 instances qui tournent :

![Exécution locale](/lab/lab3/screenshots/playbook_pm2.png) 

### Step 5 - Setting Up Nginx as a Load Balancer 

Cette fois-ci, on va créer une nouvelle instance dédiée à Nginx que l'on construit à l'aide de la commande : 
```
ansible-playbook -v create_ec2_instances_playbook.yml --extra-vars "@nginx-vars.yml"
ansible-playbook -v -i inventory.aws_ec2.yml configure_nginx_playbook.yml
```
![Exécution locale](/lab/lab3/screenshots/nginx_instance.png) 

et on la voit bien sur notre console EC2 :
![Exécution locale](/lab/lab3/screenshots/nginx_ec2.png)  

Cela nous montre qu’Ansible génère la config automatiquement. 
Après, nous avons récupéré l’adresse IP publique de l’instance Nginx `51.20.92.251` via cette commande : 
```
aws ec2 describe-instances --filters "Name=tag:Ansible,Values=nginx_instances" --query "Reservations[*].Instances[*].PublicIpAddress" --output text
```
 et en filtrant sur le tag Ansible=nginx_instances. L’instance a bien été créée et est accessible publiquement ! 

![Exécution locale](/lab/lab3/screenshots/hello_nginx.png)  



### Step 6 - Implementing Rolling Updates 

Après avoir modifié le fichier `app.js` comme demandé dans le PDF, nous relançons le playbook de configuration :
```
ansible-playbook -v -i inventory.aws_ec2.yml configure_sample_app_playbook.yml
```
Les instances sont bien construites et mises à jour une par une : 
![Exécution locale](/lab/lab3/screenshots/update_6.png)  

Pour vérifier que le service reste disponible pendant la mise à jour, nous envoyons des requêtes en continu vers l’IP du load balancer : 
```
while true; do curl http://51.20.92.251; sleep 1; done
``` 
On observe que la réponse change progressivement vers la nouvelle version sans interruption du service.
![Exécution locale](/lab/lab3/screenshots/rolling_update.png)  


Cela confirme que la stratégie de rolling update fonctionne correctement.
## Partie 2 -  VM Orchestration with Packer and OpenTofu 
Dans cette partie, on change complètement d’approche. 

Avec Ansible, on configurait des serveurs après leur création. 
Ici, on va créer une image machine déjà prête, puis déployer des instances à partir de cette image. 

### Step 1 - Building a VM Image Using Packer 

On initialise avec :
```
packer build sample-app.pkr.hcl
```

Puis on construit avec : 

```
packer build sample-app.pkr.hcl
```
À la fin, Packer retourne un AMI ID : 

![Exécution locale](/lab/lab3/screenshots/AMI_ID.png)  

On note l'identifiant de l'AMI : `eu-north-1: ami-0ad551d131629bedf`

### Step 2 - Deploying the VM Image Using OpenTofu 

Dans ce step, on configure un Launch Template avec l’AMI du Step 1 puis un Auto Scaling Group (ASG) qui va lancer 3 instances automatiquement (desired capacity = 3). 

Ensuite on exécute :
```
tofu init 
tofu apply 
```
À la fin, les instances ne sont pas créées “à la main” : c’est l’ASG qui les démarre et les garde au bon nombre. 

### Step 3 - Deploying an Application Load Balancer (ALB) 
Dans la partie Ansible, on utilisait Nginx. Ici, on utilise un vrai service AWS : ALB.

![Exécution locale](/lab/lab3/screenshots/alb_tofu.png)  

On a à la fin de la compilation de `tofu apply`, on a : `alb_dns_name = "sample-app-alb-2045686205.eu-north-1.elb.amazonaws.com"`

Puis on l'utilise ave la commande : 

```
curl http://sample-app-alb-2045686205.eu-north-1.elb.amazonaws.com

```

![Exécution locale](/lab/lab3/screenshots/curl_alb.png)  

### Step 4 - Implementing Rolling Updates with ASG Instance Refresh 
On fait les modifications dans `main.tf` et `app.js` puis on relance `packer ` avec la commande : 

```
packer build sample-app.pkr.hcl
```
Pour avoir une nouvelle AMI : `ami-050af5ef237e622e0`, que l'on ajoutera à la place de l'ancienne dans `main.tf`. 

Puis on va utiliser pour suivre le changement : 
```
while true; do curl "sample-app-alb-2045686205.eu-north-1.elb.amazonaws.com"\; sleep 1; done
```
## Partie 3 - Container Orchestration with Docker and Kubernetes 

Dans cette partie, on change d’approche : l’application est encapsulée dans un conteneur et c’est Kubernetes qui gère automatiquement le déploiement, le scaling et l’orchestration. 

### Step 1 - Building and Running the Docker Image Locally 
On commence par transformer notre application Node.js en image Docker. 
On la construit avec la commande : 
```
docker build -t sample-app:v1 .
docker run -p 8080:8080 sample-app:v1
```
Puis on effectue le test avec : 
```
curl http://localhost:8080
```
On retrouve bien : 

![Exécution locale](/lab/lab3/screenshots/docker_local.png)  

### Step 2 - Deploying the Application to a Local Kubernetes Cluster 
Docker exécute un conteneur alors que Kubernetes gère plusieurs conteneurs automatiquement. 
On va donc créer un deployment avec 3 replicas pour simuler un système distribué avec haute disponibilité. 

Avec les 2 commandes suivantes : 
```
kubectl apply -f sample-app-deployment.yaml
kubectl get pods
``` 
![Exécution locale](/lab/lab3/screenshots/pods.png)   

On voit bien 3 pods en running. 
On crée le fichier  `sample-app-services.yaml` qui permet de configurer le Service, pour exposer les pods via un point d’entrée unique. 
La commande suivante nous permet de lancer le service : 
```
kubectl apply -f sample-app-service.yaml
``` 
et 
```
curl http://localhost
```
d'afficher la sortie 

![Exécution locale](/lab/lab3/screenshots/hello_service.png)  

On ne s’occupe plus des IP individuelles.

### Step 3 - Performing a Rolling Update 

On modifie l'application : `  res.end('DevOps Base!\n');`. 
Puis on build une nouvelle image : 
```
docker build -t sample-app:v2 .
```
On met à jour le Deployement : `image: sample-app:v2` 

![Exécution locale](/lab/lab3/screenshots/v2.png)  

## Partie 4 - Deploying Applications Using Serverless Orchestration with AWS Lambda 

Dans cette partie, on va :

- Créer une fonction Lambda 
- Déployer avec OpenTofu 
- Exposer via API Gateway 
- Faire une mise à jour 
- Observer la différence avec les approches précédentes

L’objectif est de comprendre le modèle serverless. 

### Step 1 - Set Up the Working Directory 

Le dossier est bien créé. 

### Step 2 - Create the Lambda Function Code 

On crée le fichier `index.js` avec le contenu donné dans le PDF. 
La fonction : reçoit une requête, renvoie un code 200 et renvoie un texte. 

### Step 3 - Create the Main OpenTofu Configuration 

Le fichier `main.tf` est créé dans le dossier `lambda-sample`, nous l'ajustons avec nos valeurs, c'est-à-dire, la région : `eu-north-1` 

### Step 4 - Deploy the Lambda Function 

On lance le déploiement avec les commandes : 
```
tofu init
tofu apply
```

![Exécution locale](/lab/lab3/screenshots/tofu_lambda.png) 



### Step 5 - Verify the Lambda Function 

![Exécution locale](/lab/lab3/screenshots/aws_lambda_console.png) 

La fonction n’est exécutée que lorsqu’elle est appelée. Il n’y a : aucune VM permanente, aucun conteneur à maintenir et aucun scaling à configurer. 

### Step 6 - Set Up API Gateway to Trigger the Lambda Function 

Nous créons le fichier `outputs.tf` puis ajoutons le `api-gateway` module à `main.tf`.

### Step 7 - Deploy the API Gateway Configuration 

On lance avec la commande : 
```
tofu init
tofu apply
``` 
Ensuite, OpenTofu affiche un output `api_endpoint` pour nous : "https://g0inpsfu63.execute-api.eu-north-1.amazonaws.com" 

![Exécution locale](/lab/lab3/screenshots/api_tofu.png) 

### Step 8 - Test the API Endpoint 

### Step 9 - Update the Lambda Function 

### Step 10 - Verify the Update 

## Clean Up 

## Conclusion 
