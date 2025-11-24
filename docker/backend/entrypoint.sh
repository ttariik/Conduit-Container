#!/usr/bin/env sh
set -eu

cd /app

if [ "${DJANGO_MANAGEPY_MIGRATE:-1}" = "1" ]; then
  echo "[entrypoint] Applying database migrations..."
  python manage.py migrate --noinput
fi

if [ "${DJANGO_MANAGEPY_COLLECTSTATIC:-1}" = "1" ]; then
  echo "[entrypoint] Collecting static files..."
  python manage.py collectstatic --noinput
fi

if [ -n "${DJANGO_SUPERUSER_EMAIL:-}" ] && [ -n "${DJANGO_SUPERUSER_PASSWORD:-}" ]; then
  echo "[entrypoint] Ensuring admin user exists..."
  python manage.py createsuperuser --noinput \
    --email "${DJANGO_SUPERUSER_EMAIL}" \
    --username "${DJANGO_SUPERUSER_USERNAME:-admin}" \
    || true
fi

exec "$@"

