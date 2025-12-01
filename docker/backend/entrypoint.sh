#!/usr/bin/env sh
set -eu

cd /app

if [ "${DJANGO_MANAGEPY_MAKEMIGRATIONS:-0}" = "1" ]; then
  echo "[entrypoint] Creating missing migrations..."
  python manage.py makemigrations --noinput
fi

if [ "${DJANGO_MANAGEPY_MIGRATE:-1}" = "1" ]; then
  echo "[entrypoint] Applying database migrations..."
  python manage.py migrate --noinput
fi

if [ "${DJANGO_MANAGEPY_COLLECTSTATIC:-1}" = "1" ]; then
  echo "[entrypoint] Collecting static files..."
  python manage.py collectstatic --noinput
fi

echo "[entrypoint] Ensuring admin user exists..."
python manage.py ensure_superuser

exec "$@"

