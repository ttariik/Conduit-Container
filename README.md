# Conduit Container

Containerized infrastructure for the RealWorld Conduit application. This
repository keeps the Docker assets, documentation, and helper tooling that wrap
the Angular frontend and Django REST backend provided by the
[Developer Akademie](https://github.com/Developer-Akademie-GmbH).

> **Documentation language**: English (per checklist requirement).

## Table of Contents

1. [Repository Layout](#repository-layout)
2. [Prerequisites](#prerequisites)
3. [Quickstart](#quickstart)
4. [Usage](#usage)
   - [Link frontend and backend sources](#link-frontend-and-backend-sources)
   - [Environment configuration](#environment-configuration)
   - [Build and run](#build-and-run)
   - [Logs and persistence](#logs-and-persistence)
5. [Testing & Verification](#testing--verification)
6. [Operational Notes](#operational-notes)


## Repository Layout

| Path | Purpose |
| ---- | ------- |
| `frontend/` | Placeholder for your fork of `conduit-frontend` (Angular). |
| `backend/` | Placeholder for your fork of `conduit-backend` (Django REST). |
| `Dockerfile.frontend` | Multi-stage Angular → NGINX build. |
| `Dockerfile.backend` | Multi-stage Django → Gunicorn build. |
| `docker-compose.yaml` | Orchestrates frontend + backend containers. |
| `docker/` | Service-specific runtime assets (NGINX config, entrypoints, Gunicorn config). |
| `scripts/bootstrap-sources.sh` | Helper to clone/fetch your forked sources. |
| `env.example` | Sample environment file – copy to `.env` and adjust. |

## Prerequisites

- Git (with access to your frontend/backend forks)
- Docker Engine 24+ and Docker Compose v2
- Node.js / Python are **not** required on the host; everything runs inside the
  containers.

## Quickstart

```bash
# 1. Pull in the application sources (update the URLs to your forks)
scripts/bootstrap-sources.sh git@github.com:me/conduit-frontend.git \
                             git@github.com:me/conduit-backend.git

# 2. Provide configuration
cp env.example .env
# edit .env to adjust ports, API URL, Django secrets, etc.

# 3. Build and start the stack
docker compose up --build

# Frontend: http://localhost:8282
# Backend API: http://localhost:8000/api
```

Once the containers are up you can sign in with an existing RealWorld account or
create new ones via the UI.

## Usage

### Link frontend and backend sources

The repository deliberately keeps source code outside of the infrastructure
files. Work with your own forks to keep the Git history intact:

1. Fork `Developer-Akademie-GmbH/conduit-frontend` and `conduit-backend`.
2. Run `scripts/bootstrap-sources.sh <frontend-url> <backend-url> [branch]` to
   clone/update both directories, or add them as Git submodules manually.
3. Commit the resulting submodule references (recommended) or rerun the script
   whenever you need to refresh the sources.

### Environment configuration

`docker-compose.yaml` expects a `.env` file at the repository root. Start by
copying `env.example` and tweak as needed:

| Variable | Description |
| -------- | ----------- |
| `FRONTEND_PORT` | Host port that exposes the Angular UI (default `8282`). |
| `FRONTEND_API_URL` | API base URL the frontend should call. Use `http://backend:8000/api` when running inside Docker. |
| `BACKEND_PORT` | Host port for the Django API (default `8000`). |
| `BACKEND_DATABASE_URL` | Database connection string (defaults to SQLite persisted under `/app/data`). |
| `DJANGO_SECRET_KEY` | Provide your own secret for production use. |
| `DJANGO_SUPERUSER_*` | (Optional) Auto-create an admin user on boot. |
| `GUNICORN_*` | Tune worker timeout and log verbosity. |

### Build and run

Most day-to-day tasks are handled via Docker Compose:

```bash
# Build images
docker compose build

# Start in foreground
docker compose up

# Start detached
docker compose up -d

# Stop services
docker compose down

# Clean up volumes (removes persisted DB/logs)
docker compose down -v
```

The Compose file uses restart policies so both services automatically recover if
the process exits unexpectedly.

### Logs and persistence

- Frontend logs: `frontend_logs` volume (mounted at `/var/log/nginx`).
- Backend app data: `backend_data` volume (mounted at `/app/data`).
- Backend Gunicorn logs: `backend_logs` volume (mounted at `/var/log/conduit`).

Export logs for submission/debugging as required by the checklist:

```bash
docker logs conduit-backend > backend.log
docker logs conduit-frontend > frontend.log
```

## Testing & Verification

Before submitting the project, confirm:

- `http://<VM-IP>:8282` loads the Conduit UI and you can navigate through feed,
  article editor, profile, etc.
- `http://<VM-IP>:8000/api/tags/` responds (health-check uses the same endpoint).
- Killing either container (`docker kill conduit-backend`) triggers an automatic
  restart because of `restart: unless-stopped`.
- Logs can be tailed and persisted via `docker logs` or the mounted volumes.

## Operational Notes

- The backend image starts with an entrypoint that runs migrations, optionally
  collects static files, and then launches Gunicorn (production-grade WSGI).
- The frontend image is built via a multi-stage Node → NGINX pipeline to keep
  the runtime image minimal.
- Customize the Angular environment (`src/environments/environment.prod.ts`) so
  that `api_url` matches the Compose network endpoint (`http://backend:8000/api`)
  before building the image.
- Keep credentials out of Git: store real secrets in `.env`, which is ignored by
  Git and only referenced by Docker at runtime.



