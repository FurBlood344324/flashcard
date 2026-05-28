#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] Killing port forward processes..."
pkill -f "kubectl port-forward svc/argocd-server" 2>/dev/null || true
pkill -f "kubectl port-forward svc/flashcard-api" 2>/dev/null || true

echo "[2/4] Deleting Argo CD applications (cascade deletes managed resources)..."
kubectl delete application app-of-apps -n argocd --cascade=foreground 2>/dev/null || true

echo "[3/4] Uninstalling Argo CD + Sealed Secrets..."
helm uninstall argocd -n argocd 2>/dev/null || true
helm uninstall sealed-secrets -n infrastructure 2>/dev/null || true

echo "[4/4] Deleting Minikube cluster..."
minikube delete
