#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "  Kubernetes cluster info"
echo "=============================================="
echo ""
echo "Flashcard API URL:"
minikube service flashcard-api -n flashcard --url
echo ""
echo "Argo CD:     http://localhost:8080"
echo "Prometheus:  http://localhost:9090"
echo "Grafana:     http://localhost:3000"
echo ""
echo "Argo CD credentials:"
echo "  Username: admin"
echo "  Password: $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo "Grafana credentials:"
echo "  Username: admin"
echo "  Password: $(kubectl get secret monitoring-grafana -n infrastructure -o jsonpath='{.data.adminPassword}' | base64 -d)"
