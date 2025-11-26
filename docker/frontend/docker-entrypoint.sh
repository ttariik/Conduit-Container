#!/bin/sh
set -eu

# Generate env-config.js with runtime environment variables
cat > /usr/share/nginx/html/assets/env-config.js << EOF
window._env = {
  apiUrl: "${API_URL:-http://localhost:8000/api}",
  production: ${PRODUCTION:-true}
};
EOF

echo "[frontend-entrypoint] Generated env-config.js with API_URL=${API_URL:-http://localhost:8000/api}"

# Start nginx
exec "$@"

