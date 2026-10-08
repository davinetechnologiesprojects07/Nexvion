# Deployment documentation

## Prerequisites

- Docker and Docker Compose v2 for local use.
- Terraform and AWS credentials for infrastructure.
- An SSH key pair at `~/.ssh/nexvion-key` and `.pub`.
- Ansible with `community.general`.
- A Docker Hub account if publishing images.
- `kubectl`, Helm, and an NGINX Ingress controller for Kubernetes.

## Local deployment

```bash
docker compose up -d --build
curl -fsS http://localhost:8088/healthz
docker compose ps
docker compose logs -f
```

Stop the stack with `docker compose down`.

## AWS deployment

1. Copy the example variables and set an administrator CIDR:

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Set admin_cidr to the current public IP in CIDR notation, such as x.x.x.x/32.
   terraform init
   terraform plan
   terraform apply
   ```

2. Retrieve the address and confirm HTTP:

   ```bash
   IP=$(terraform output -raw public_ip)
   curl -i http://$IP/healthz
   ```

3. Configure the server:

   ```bash
   cd ../ansible
   cp inventory.ini.example inventory.ini
   # Put the Terraform public IP in inventory.ini.
   ansible-playbook playbook.yml
   ```

4. Confirm the image and service:

   ```bash
   ssh -i ~/.ssh/nexvion-key ubuntu@$IP \
     "docker inspect nexvion-app --format '{{.Config.Image}}'"
   ssh -i ~/.ssh/nexvion-key ubuntu@$IP \
     "docker compose -f /opt/nexvion/docker-compose.yml ps"
   ```

The production Compose file publishes container port 8080 on host port 80.
Only port 80 is public; SSH is restricted by both the AWS security group and
UFW.

## Jenkins deployment

Create these Jenkins credentials before running the pipeline:

- `dockerhub-creds`: Docker Hub username and token/password;
- `nexvion-aws-key`: SSH private key and username `ubuntu`.

The pipeline's `AWS_HOST` must match the current Terraform Elastic IP. If the
Jenkins agent runs from a different public address than the administrator,
include that address in the SSH security-group rule before deployment.

## Kubernetes deployment

Create the namespace, configuration, and secret first:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.example.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl -n nexvion rollout status deployment/nexvion
```

For Helm:

```bash
kubectl create namespace nexvion
kubectl -n nexvion create secret generic nexvion-secret \
  --from-literal=APP_API_KEY='replace-me'
helm upgrade --install nexvion ./helm/nexvion -n nexvion
kubectl -n nexvion rollout status deployment/nexvion
```

Do not commit real secret values. Change the image tag in the chart values or
pass it at deploy time with `--set image.tag=<tag>`.

