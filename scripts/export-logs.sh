#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${REPO_ROOT}/logs_${TIMESTAMP}"
mkdir -p "${LOG_DIR}"

echo "📋 Exporting container logs..."
echo ""

# Export backend logs
if docker ps -a --format '{{.Names}}' | grep -q "^conduit-backend$"; then
  echo "Exporting backend logs..."
  docker logs conduit-backend > "${LOG_DIR}/backend.log" 2>&1 || true
  echo "  ✅ Backend logs saved to ${LOG_DIR}/backend.log"
else
  echo "  ⚠️  Backend container not found"
fi

# Export frontend logs
if docker ps -a --format '{{.Names}}' | grep -q "^conduit-frontend$"; then
  echo "Exporting frontend logs..."
  docker logs conduit-frontend > "${LOG_DIR}/frontend.log" 2>&1 || true
  echo "  ✅ Frontend logs saved to ${LOG_DIR}/frontend.log"
else
  echo "  ⚠️  Frontend container not found"
fi

# Export docker compose logs
if [ -f "docker-compose.yaml" ]; then
  echo "Exporting docker compose logs..."
  docker compose logs > "${LOG_DIR}/compose.log" 2>&1 || true
  echo "  ✅ Compose logs saved to ${LOG_DIR}/compose.log"
fi

echo ""
echo "✅ All logs exported to: ${LOG_DIR}"
echo ""
echo "To view logs:"
echo "  cat ${LOG_DIR}/backend.log"
echo "  cat ${LOG_DIR}/frontend.log"

