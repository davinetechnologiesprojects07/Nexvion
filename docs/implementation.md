# Implementation documentation

## Application

The application is a static storefront:

- `app/index.html` is the home page.
- `app/products.html` provides catalogue, search, filtering, sorting, and cart
  interactions.
- `app/payment.html` provides the demo checkout flow.
- CSS is split by page (`style.css`, `products.css`, and `payment.css`).
- JavaScript stores demo state in `localStorage`.

The authentication and payment screens are demonstrations only. Never use
real passwords, card numbers, or payment credentials with this application.

## Container

`docker/Dockerfile` uses `nginxinc/nginx-unprivileged:1.27-alpine`, applies
available Alpine updates, copies the static site, and listens on port 8080.
The image health check requests `/healthz`.

`docker/nginx.conf` supplies the health endpoint, static-file routing, gzip,
and baseline response headers. `docker/proxy.conf` is used only by the local
Compose reverse proxy.

Build and test the image:

```bash
docker build -f docker/Dockerfile -t nexvion-app:local .
docker run --rm --entrypoint nginx nexvion-app:local -t
docker compose up -d
curl -i http://localhost:8088/healthz
```

## Infrastructure as code

Terraform in `terraform/` creates:

- a VPC, public subnet, route table, and Internet Gateway;
- an Ubuntu 24.04 AMI-backed EC2 instance;
- an SSH key pair and restricted security group;
- an encrypted gp3 root volume;
- an Elastic IP and useful outputs.

Keep `terraform.tfvars` local. It contains the administrator CIDR and should
not be widened to `0.0.0.0/0` just to work around an SSH problem.

## Configuration management

Ansible in `ansible/playbook.yml` installs Docker, Compose, UFW, fail2ban,
unattended upgrades, and a 1 GB swap file. It copies the production Compose
file to `/opt/nexvion`, enables the firewall, hardens SSH, starts the service,
and waits for `/healthz`.

## CI/CD and security checks

The Jenkins pipeline:

1. checks required source files;
2. builds the numbered and `latest` image tags;
3. validates Nginx configuration;
4. runs Gitleaks and Trivy scans;
5. pushes the image to Docker Hub;
6. deploys the selected tag to AWS Compose;
7. verifies the public health endpoint.

The AWS deployment uses the Jenkins credential `nexvion-aws-key` and the
`AWS_HOST` environment value. The Jenkins agent's public IP must be included
in the Terraform SSH allowlist.

## Kubernetes and observability

The Kubernetes manifests provide a two-replica rolling deployment, probes,
resource limits, a ClusterIP service, and NGINX Ingress. The Helm chart adds
the same controls and references an externally-created `nexvion-secret`.

`k8s/bluegreen/` contains a blue/green service-switching demonstration, while
`k8s/canary/` contains an NGINX Ingress canary route. These manifests are
release-strategy examples and are separate from the default
`k8s/deployment.yaml` rollout.

Prometheus and Grafana configuration is under `monitoring/`. Filebeat and
Logstash configuration is under `logging/`. These are optional platform
components; the core application does not require them to serve traffic.
