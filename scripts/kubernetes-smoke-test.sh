#!/usr/bin/env bash
set -euo pipefail

# Smoke test for flashcard API on Kubernetes
# Usage:
#   ./scripts/kubernetes-smoke-test.sh                 # auto-detect cluster
#   ./scripts/kubernetes-smoke-test.sh --url <URL>      # pass URL directly (CI)
#   K8S_SMOKE_ARGO_CHECK=0 ./scripts/kubernetes-smoke-test.sh  # skip Argo CD check
#
# Exit: 0 = healthy, 1 = unhealthy

NAMESPACE="${K8S_NAMESPACE:-flashcard}"
TIMEOUT_SEC="${K8S_SMOKE_TIMEOUT:-60}"
API_URL="${K8S_SMOKE_URL:-}"
ARGO_CHECK="${K8S_SMOKE_ARGO_CHECK:-1}"
SKIP_ARGO="${K8S_SMOKE_SKIP_ARGO:-0}"
HEALTH_PATH="/health"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
    local desc="$1"
    if eval "$2" &>/dev/null; then
        echo -e "  ${GREEN}[PASS]${NC} $desc"
        ((PASS++)) || true
    else
        echo -e "  ${RED}[FAIL]${NC} $desc"
        ((FAIL++)) || true
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url) API_URL="$2"; shift 2 ;;
        --namespace) NAMESPACE="$2"; shift 2 ;;
        --skip-argo) SKIP_ARGO=1; shift ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

echo "=== Flashcard API Smoke Test ==="
echo ""

# --- Cluster detection ---
echo "--- Cluster ---"
if command -v minikube &>/dev/null && minikube status &>/dev/null 2>&1; then
    echo "  Cluster: minikube"
elif command -v kind &>/dev/null && kind get clusters 2>/dev/null | grep -q .; then
    echo "  Cluster: kind ($(kind get clusters | head -1))"
elif kubectl cluster-info &>/dev/null 2>&1; then
    echo "  Cluster: generic kubectl"
else
    echo -e "  ${RED}No Kubernetes cluster found${NC}"
    exit 1
fi

# --- Argo CD status ---
if [ "$ARGO_CHECK" = "1" ] && [ "$SKIP_ARGO" = "0" ] && \
   kubectl get ns argocd &>/dev/null 2>&1; then
    echo ""
    echo "--- Argo CD Applications ---"
    if command -v argocd &>/dev/null; then
        argocd app list 2>/dev/null || echo "  (argocd CLI present but not logged in)"
    fi
    for app in flashcard-api postgres localstack monitoring; do
        status=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "N/A")
        sync=$(kubectl get application "$app" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "N/A")
        if [ "$status" = "Healthy" ] && [ "$sync" = "Synced" ]; then
            echo -e "  ${GREEN}[OK]${NC} $app: $status / $sync"
        else
            echo -e "  ${YELLOW}[--]${NC} $app: $status / $sync"
        fi
    done
else
    echo ""
    echo "--- Argo CD: skipped (not installed or disabled) ---"
fi

# --- API URL ---
if [ -z "$API_URL" ]; then
    if command -v minikube &>/dev/null; then
        API_URL=$(minikube service flashcard-api -n "$NAMESPACE" --url 2>/dev/null || echo "")
    fi
    if [ -z "$API_URL" ]; then
        echo ""
        echo -n "Starting port-forward to flashcard-api... "
        kubectl port-forward svc/flashcard-api 15000:5000 -n "$NAMESPACE" &>/dev/null &
        PF_PID=$!
        sleep 2
        API_URL="http://127.0.0.1:15000"
        echo "PID $PF_PID"
        trap "kill $PF_PID 2>/dev/null || true" EXIT
    fi
fi

echo ""
echo "--- Endpoint: $API_URL$HEALTH_PATH ---"

# --- Pod status ---
echo ""
echo "--- Pods ($NAMESPACE) ---"
kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | while read -r line; do
    name=$(echo "$line" | awk '{print $1}')
    ready=$(echo "$line" | awk '{print $2}')
    status=$(echo "$line" | awk '{print $3}')
    if [ "$status" = "Running" ] && [[ "$ready" == *"/"* ]] && [ "${ready%/*}" = "${ready#*/}" ]; then
        echo -e "  ${GREEN}[OK]${NC} $name ($ready, $status)"
    else
        echo -e "  ${YELLOW}[--]${NC} $name ($ready, $status)"
    fi
done

# --- /health check with retries ---
echo ""
echo "--- Health check ---"
START=$(date +%s)
while true; do
    if curl -fsS --max-time 5 "$API_URL$HEALTH_PATH" 2>/dev/null; then
        echo ""
        check "API /health returns 200" "curl -fsS --max-time 5 $API_URL$HEALTH_PATH"
        break
    fi
    ELAPSED=$(($(date +%s) - START))
    if [ "$ELAPSED" -ge "$TIMEOUT_SEC" ]; then
        echo ""
        check "API /health returns 200 (timed out after ${TIMEOUT_SEC}s)" "false"
        break
    fi
    echo -n "."
    sleep 2
done

# --- Summary ---
echo ""
echo "=== Result: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
