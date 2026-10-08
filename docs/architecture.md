# Nexvion architecture

## Overview

Nexvion is a static storefront served by unprivileged Nginx. The same
container image is used for local Docker Compose, the AWS EC2 deployment,
and the Kubernetes/Helm manifests. Terraform creates the AWS network and
host; Ansible hardens and bootstraps that host.

```mermaid
flowchart TB
    browser[Browser] -->|HTTP :80| sg[AWS security group]
    sg --> eip[Elastic IP]
    eip --> ec2[Ubuntu 24.04 EC2]
    ec2 --> compose[Docker Compose]
    compose --> app[richieit/nexvion]
    app --> nginx[Nginx :8080]
    nginx --> files[Static HTML/CSS/JS]
    nginx --> health[/healthz]

    git[Git repository] --> jenkins[Jenkins pipeline]
    jenkins --> image[Docker Hub image]
    image --> compose

    terraform[Terraform] --> vpc[VPC, subnet, routes, SG, EIP]
    vpc --> ec2
    ansible[Ansible] --> ec2

    subgraph Kubernetes option
      image --> deployment[Deployment]
      deployment --> service[ClusterIP Service]
      service --> ingress[NGINX Ingress]
    end
```

## Runtime paths

- **Local development:** `docker-compose.yml` builds the image and exposes
  the reverse proxy at `http://localhost:8088`.
- **AWS single host:** Terraform provisions the EC2 host, Ansible installs
  Docker and UFW, and `ansible/files/docker-compose.prod.yml` publishes the
  application on port 80.
- **Kubernetes:** `k8s/` contains direct manifests; `helm/nexvion/` provides
  the parameterized chart with rolling updates and non-root containers.
- **CI/CD:** `Jenkinsfile` validates the source, builds and scans the image,
  pushes both the build tag and `latest`, and updates the AWS Compose service.

## Network and security boundaries

Terraform creates a public subnet with an Internet Gateway and an Elastic IP.
The security group allows HTTP from the Internet and SSH only from
`var.admin_cidr`. UFW repeats the host-level HTTP/SSH boundary. SSH password
and root login are disabled, and fail2ban is enabled.

The application is intentionally frontend-only. Browser localStorage is used
for demo cart, account, checkout, and order state. There is no backend,
database, real authentication, or payment processor.

