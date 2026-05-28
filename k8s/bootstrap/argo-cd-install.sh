#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Argo CD + Sealed Secrets on Minikube
# Run once per cluster. After this, Argo CD manages everything.

echo "[1/5] Adding Helm repos..."
helm repo add argo https://argoproj.github.io/argo-helm --force-update 2>/dev/null || true
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets --force-update 2>/dev/null || true
helm repo update

echo "[2/5] Installing Argo CD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait

echo "[3/5] Installing Sealed Secrets controller..."
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace infrastructure --create-namespace \
  --wait

echo "[4/5] Applying app-of-apps root Application..."
kubectl apply -f "$(dirname "$0")/../argocd/app-of-apps.yaml"

echo "[5/5] Done. Argo CD is ready."
echo ""
echo "Access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server 8080:80 -n argocd"
echo "  URL: http://localhost:8080"
echo "  Admin password:"
echo "  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo"
echo ""
echo "Sync all applications:"
echo "  argocd app sync app-of-apps"
echo ""
echo "Or sync individual apps:"
echo "  argocd app sync postgres"
echo "  argocd app sync localstack"
echo "  argocd app sync monitoring"
echo "  argocd app sync flashcard-api"
echo ""
echo "To trigger redeploy, bump deploy-version annotation in the Application YAML, then sync."
