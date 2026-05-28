#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/3] Starting Minikube..."
if ! minikube status &>/dev/null; then
  minikube start
else
  echo "  Minikube already running"
fi

echo "[2/3] Building Docker image..."
eval "$(minikube docker-env)"
docker build -t flashcard-api:dev "$PROJECT_DIR"

echo "[3/3] Bootstrapping Argo CD + Sealed Secrets..."
"$PROJECT_DIR/k8s/bootstrap/argo-cd-install.sh"

echo ""
echo "All done. Argo CD UI: http://localhost:8080"
echo "Run ./scripts/kubernetes-sync.sh to sync applications."
echo "Run ./scripts/kubernetes-forward.sh to open port forwards."
echo "Run ./scripts/kubernetes-result.sh to see URLs and credentials."
echo "Run ./scripts/kubernetes-smoke-test.sh to verify /health."
