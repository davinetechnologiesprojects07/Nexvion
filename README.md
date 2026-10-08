# Nexvion

Nexvion is a static e-commerce storefront packaged as an unprivileged Nginx
container. It supports local Docker Compose, a hardened AWS EC2 deployment,
Jenkins CI/CD, and Kubernetes/Helm deployment.

Repository: [dhuor2001-debug/Nexvion](https://github.com/dhuor2001-debug/Nexvion) —
Nexvion is a production-style e-commerce platform focused on modern DevOps
practices, including containerization, CI/CD, infrastructure automation,
Kubernetes, monitoring, logging, security, and cloud deployment.

> **Important:** Authentication and payment are frontend demonstrations backed
> by browser localStorage. Do not use real passwords, card data, or payment
> credentials. A production store needs a backend, secure authentication,
> persistent storage, and a real payment provider.

## Quick start

```bash
docker compose up -d --build
curl http://localhost:8088/healthz
```

Open <http://localhost:8088>. Stop the stack with `docker compose down`.

## Repository map

| Path | Purpose |
| --- | --- |
| `app/` | Static storefront pages, styles, scripts, and logo |
| `docker/` | Nginx image and server configuration |
| `terraform/` | AWS VPC, EC2, security group, key pair, and Elastic IP |
| `ansible/` | Ubuntu hardening, Docker setup, and production Compose |
| `Jenkinsfile` | Build, scan, publish, deploy, and health-check pipeline |
| `k8s/` | Kubernetes manifests |
| `helm/nexvion/` | Helm chart |
| `monitoring/` | Prometheus and Grafana configuration |
| `logging/` | Filebeat and Logstash configuration |
| `scripts/` | Local operational helper scripts |
| `docs/` | Architecture, implementation, deployment, and troubleshooting |

## Delivery workflow

1. Validate the application and Nginx configuration.
2. Build the image from `docker/Dockerfile`.
3. Run Gitleaks and Trivy checks.
4. Push a build-number tag and `latest` to Docker Hub.
5. Deploy the selected image tag to AWS Compose.
6. Verify `/healthz`.

See [deployment documentation](docs/deployment.md) for AWS, Jenkins, and
Kubernetes instructions.

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation](docs/implementation.md)
- [Deployment](docs/deployment.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Application analysis](docs/application-analysis.md)

The Kubernetes directory also includes blue/green and canary deployment
examples for demonstrating alternative release strategies.

## Operational notes

AWS SSH is intentionally restricted to `terraform.tfvars`'s `admin_cidr`.
Update it when the administrator or Jenkins agent's public IP changes. HTTP
is served on port 80 in production and the local reverse proxy is served on
port 8088.
