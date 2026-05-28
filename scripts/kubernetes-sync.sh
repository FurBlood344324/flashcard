#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/2] Syncing all applications..."

if ! command -v argocd &>/dev/null; then
  echo "  ERROR: argocd CLI not installed."
  echo "  Install it first: sudo pacman -S argocd"
  exit 1
fi

ARGOCD_PASS=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)
argocd login --insecure --username admin --password "$ARGOCD_PASS" localhost:8080 &>/dev/null || {
  kubectl port-forward svc/argocd-server 8080:80 -n argocd &>/dev/null &
  sleep 2
  argocd login --insecure --username admin --password "$ARGOCD_PASS" localhost:8080
}

argocd app sync app-of-apps --timeout 300

echo "  Syncing child applications..."
for child in postgres localstack monitoring flashcard-api; do
  echo "    Syncing $child..."
  argocd app sync "$child" --timeout 300 || echo "    Warning: $child sync completed with errors (may be transient)"
done

echo "[2/2] Checking status..."
"$SCRIPT_DIR/kubernetes-check.sh"

echo ""
echo "All synced. Run ./scripts/kubernetes-forward.sh to open port forwards."
echo "Run ./scripts/kubernetes-result.sh to see URLs and credentials."
echo "Run ./scripts/kubernetes-smoke-test.sh to verify /health."
