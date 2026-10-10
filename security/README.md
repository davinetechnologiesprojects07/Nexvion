# Nexvion Security Controls

## Dependency Scanning
Nexvion is a static HTML/CSS/JavaScript application and has no package.json,
requirements.txt, pom.xml, or other dependency manifest. Dependency scanning
is therefore not applicable to the current application source.

## Secret Detection
Trivy filesystem secret scanning is integrated into the Jenkins CI/CD pipeline.

## Container Image Scanning
Docker images are scanned with Trivy for HIGH and CRITICAL vulnerabilities
during the Jenkins pipeline.

## Kubernetes Security
- Secrets are created at runtime and are not committed to Git.
- Privilege escalation is disabled.
- Linux capabilities are restricted.
- RuntimeDefault seccomp profile is enabled.
- Resource requests and limits are configured.

## AWS Hardening
- SSH access is restricted to the administrator public IP /32.
- EC2 metadata service requires IMDSv2.
- Root EBS volume is encrypted.
- Security groups expose only required ports.
