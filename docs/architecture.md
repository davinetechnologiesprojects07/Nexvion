# Nexvion DevOps Architecture

## Architecture Diagram

GitHub Repository
        |
        v
Jenkins CI/CD
        |
        v
Validation + Trivy Security Scan
        |
        v
Docker Image --> Docker Hub
        |
        +---------------------> AWS EC2
        |                         ^
        |                         |
        v                    Ansible
Kubernetes / Kind                ^
        |                         |
        v                    Terraform
Helm Deployment
        |
        +--> Ingress
        |
        +--> Prometheus --> Grafana
        |
        +--> Logstash --> Elasticsearch --> Kibana
        |
        +--> AI-Assisted Incident Analysis

## Architecture Summary

Nexvion is a ready-made static e-commerce application.

The DevOps implementation includes GitHub, Bash, Docker, Docker Compose, Jenkins, Terraform, Ansible, Kubernetes, Helm, Prometheus, Grafana, ELK, security scanning, AI-assisted incident analysis, and AWS EC2 deployment.
