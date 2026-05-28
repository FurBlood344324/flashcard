#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

API_URL=$(minikube service flashcard-api -n flashcard --url)
echo "API URL: $API_URL"

k6 run -e BASE_URL="$API_URL" "$PROJECT_DIR/perf/load-test.js"
