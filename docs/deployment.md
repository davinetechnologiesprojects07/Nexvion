# Nexvion Deployment Documentation

## Docker
Build: docker build -t nexvion:1.0 .
Run: docker run -d -p 8080:80 nexvion:1.0

## Docker Compose
docker compose up -d

## Kubernetes
kubectl apply -f kubernetes/

## Helm
helm upgrade --install nexvion helm/nexvion --namespace nexvion-helm

## Terraform
cd terraform
terraform init
terraform plan
terraform apply

## Ansible Server Setup
ansible-playbook -i ansible/inventory.ini ansible/server-setup.yml

## AWS Application Deployment
ansible-playbook -i ansible/inventory.ini ansible/deploy-nexvion.yml

Nexvion is exposed through HTTP port 80 on the AWS EC2 instance.
