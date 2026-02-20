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


### Step 5 - Setting Up Nginx as a Load Balancer 

### Step 6 - Implementing Rolling Updates 

## Partie 2 -  VM Orchestration with Packer and OpenTofu 

### Step 1 - Building a VM Image Using Packer 

### Step 2 - Deploying the VM Image Using OpenTofu 

### Step 3 - Deploying an Application Load Balancer (ALB) 

### Step 4 - Implementing Rolling Updates with ASG Instance Refresh 

## Partie 3 - Container Orchestration with Docker and Kubernetes 

### Step 1 - Building and Running the Docker Image Locally 

### Step 2 - Deploying the Application to a Local Kubernetes Cluster 

### Step 3 - Performing a Rolling Update 

## Partie 4 - Deploying Applications Using Serverless Orchestration with AWS Lambda 

### Step 1 - Set Up the Working Directory

### Step 2 - Create the Lambda Function Code 

### Step 3 - Create the Main OpenTofu Configuration 

### Step 4 - Deploy the Lambda Function 

### Step 5 - Verify the Lambda Function 

### Step 6 - Set Up API Gateway to Trigger the Lambda Function 

### Step 7 - Deploy the API Gateway Configuration 

### Step 8 - Test the API Endpoint 

### Step 9 - Update the Lambda Function 

### Step 10 - Verify the Update 

## Clean Up 

## Conclusion 
