#!/usr/bin/env bash
set -euo pipefail

check() {
  local name="$1"
  local resource="$2"
  local namespace="${3:-}"
  local ns_flag=""
  [ -n "$namespace" ] && ns_flag="-n $namespace"
  printf "%-25s " "$name:"
  kubectl rollout status "$resource" $ns_flag --timeout=120s 2>&1 || echo "not ready yet"
}

echo "--- Rollout Status ---"
check "PostgreSQL" statefulset/postgres-postgresql infrastructure
check "LocalStack" deployment/localstack infrastructure
check "Grafana" deployment/monitoring-grafana infrastructure
check "Prometheus Operator" deployment/monitoring-kube-prometheus-operator infrastructure
check "Flashcard API" deployment/flashcard-api flashcard
echo ""

echo "--- Argo CD Applications ---"
kubectl get applications -n argocd 2>/dev/null || echo "Argo CD not installed"
echo ""

echo "--- Pods ---"
kubectl get pods -A --field-selector=status.phase!=Succeeded 2>/dev/null || kubectl get pods
