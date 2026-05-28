#!/usr/bin/env bash
set -euo pipefail

echo "Starting port forwards..."

kubectl port-forward svc/argocd-server 8080:80 -n argocd > /dev/null 2>&1 &
PF_ARGOCD=$!
echo "Argo CD:    http://localhost:8080 (PID $PF_ARGOCD)"

kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n infrastructure > /dev/null 2>&1 &
PF_PROMETHEUS=$!
echo "Prometheus: http://localhost:9090 (PID $PF_PROMETHEUS)"

kubectl port-forward svc/monitoring-grafana 3000:80 -n infrastructure > /dev/null 2>&1 &
PF_GRAFANA=$!
echo "Grafana:    http://localhost:3000 (PID $PF_GRAFANA)"
