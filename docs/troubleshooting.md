# Troubleshooting

## HTTP works but SSH times out

HTTP and SSH are separate security-group rules. Check the current public IP:

```bash
curl -s https://checkip.amazonaws.com
```

Set that address as `admin_cidr` with `/32`, then apply Terraform:

```bash
cd terraform
terraform plan
terraform apply
```

The original incident was caused by a stale rule for `117.195.75.4/32` while
the client was using `117.194.74.190`. A timeout indicates network filtering;
it is not an SSH-key authentication error.

## SSH reports an unknown or changed host key

Elastic IP reassignment or instance replacement can make a known address map
to a new host key. Verify the instance replacement in AWS before removing a
key. Then remove only the affected entry and reconnect:

```bash
ssh-keygen -R 54.147.106.107
ssh -i ~/.ssh/nexvion-key ubuntu@54.147.106.107
```

## Jenkins cannot deploy to AWS

Check all of the following:

```bash
terraform output public_ip
ssh -i ~/.ssh/nexvion-key ubuntu@$IP
```

The Jenkins credential must contain the matching private key and `ubuntu`
username. The Jenkins agent's egress IP must be allowed by `admin_cidr`.
Also update the hardcoded `AWS_HOST` in `Jenkinsfile` after an Elastic IP
change. The pipeline catches this stage as `UNSTABLE`, so inspect the stage
log rather than relying only on the overall build result.

## Health check fails

Check the container and logs:

```bash
docker ps
docker inspect nexvion-app --format '{{json .State.Health}}'
docker logs nexvion-app
curl -i http://127.0.0.1/healthz
```

The image listens on port 8080. A Compose mapping must target `8080`, not
port 80 inside the container. Rebuild if the Nginx configuration or app files
changed:

```bash
docker compose up -d --build
```

## Compose proxy is unhealthy or unavailable

The local proxy is exposed at port 8088 and depends on the app health check.
Use `docker compose ps` and `docker compose logs proxy app`. Port 8088 may
already be occupied; change only the host side of the mapping if necessary.

Port 8088 is deliberate: Jenkins uses port 8080 in the development setup, so
mapping the local proxy to 8080 creates a host-port conflict.

## Nginx returns 502 or upstream connection errors

Inspect both sides of the proxy:

```bash
docker compose ps
docker compose logs --tail=100 proxy app
docker inspect nexvion-app --format '{{json .State.Health}}'
```

The proxy must resolve the Compose service name `app`, and the application
must listen on port 8080. If the app was recently recreated, wait for its
health check or restart the stack:

```bash
docker compose up -d --force-recreate
```

The incident report recorded repeated `connect() failed` upstream errors and
HTTP gateway failures. Correlate the first error with the last container
recreation; if the errors began after a release, roll back to the previous
image tag before investigating further.

## Kubernetes pods do not become Ready

```bash
kubectl -n nexvion get pods
kubectl -n nexvion describe pod <pod-name>
kubectl -n nexvion logs deployment/nexvion
kubectl -n nexvion get secret nexvion-secret
```

Verify that the image exposes 8080, the readiness path is `/healthz`, the
secret exists, and the NGINX Ingress controller is installed. An
`ImagePullBackOff` usually means the image tag is wrong or the registry
requires credentials.

## Terraform apply errors

Run formatting and validation before applying:

```bash
cd terraform
terraform fmt -check
terraform validate
terraform plan
```

Confirm AWS credentials, region, the public-key path, and that `admin_cidr`
is valid CIDR notation. Never edit `terraform.tfstate` manually.

## Jenkins does not start

The Jenkins image is based on Java 21. If a local Jenkins container is
replaced with an older Java base image, Jenkins may fail during startup.
Check the container logs and use the repository's `jenkins/Dockerfile` rather
than substituting a system Java runtime:

```bash
docker compose -f jenkins/docker-compose.yml logs jenkins
```

## Gitleaks reports a test secret

The security gate is expected to fail on real secrets. Known test fixtures
must remain clearly fake and be handled by the repository's existing
Gitleaks configuration; never add a real credential to an allowlist. Rotate
any credential that appears in a scan before rerunning the pipeline.

## Container fails after enabling a read-only filesystem

The production image is designed to run as an unprivileged user with a
read-only root filesystem. The static site should not write to the image
filesystem. In Kubernetes, use the existing `/tmp` `emptyDir` mount for
temporary writes and remove code that attempts to modify the document root.

## Demo data or login appears to disappear

Cart, account, checkout, and order data live in browser localStorage. It is
per-browser demo state, not server-side data. Clearing site data, changing
browsers, or using private browsing removes it.
