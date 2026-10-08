#!/usr/bin/env bash
set -uo pipefail

echo "== Docker =="
docker info >/dev/null 2>&1 && echo "Docker OK" || { echo "Docker is not running. Start Docker Desktop first."; exit 1; }

echo; echo "== Memory =="
free -h | head -2

echo; echo "== Containers =="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E "NAMES|nexvion|minikube" || true

echo; echo "== minikube =="
if ! minikube status >/dev/null 2>&1; then
  echo "Starting minikube..."
  minikube start
fi
kubectl get nodes

echo; echo "== Pods =="
kubectl get pods -n nexvion
kubectl get pods -n monitoring

echo; echo "== Jenkins =="
curl -s -o /dev/null -w "Jenkins HTTP %{http_code}\n" --max-time 8 http://localhost:8082/login

echo; echo "== AWS server =="
aws ec2 describe-instances --instance-ids i-0a162c22440e7ff7b \
  --query "Reservations[].Instances[].[State.Name,PublicIpAddress]" --output text
