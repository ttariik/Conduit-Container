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
5. [Automated Deployment](#automated-deployment)
6. [Testing & Verification](#testing--verification)
7. [Security Guidelines](#security-guidelines)
8. [Operational Notes](#operational-notes)


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

## Automated Deployment

The repository includes a GitHub Actions workflow (`.github/workflows/deployment.yaml`) that automates deployment to a cloud VM via SSH.

### Workflow Configuration

The workflow is triggered on:
- Push to `main` or `conduit` branches
- Manual workflow dispatch

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings (`Settings → Secrets and variables → Actions`):

| Secret | Description |
| ------ | ----------- |
| `SSH_PRIVATE_KEY` | Private SSH key for server authentication (contents of your private key file). |
| `VM_HOST` | Cloud VM IP address or hostname. |
| `VM_USER` | SSH username for the cloud VM. |
| `ENV_FILE` | Complete contents of your production `.env` file. |

### Workflow Steps

1. **Checkout**: Fetches the repository code including submodules.
2. **SSH Setup**: Configures SSH authentication using the provided private key.
3. **File Transfer**: Syncs all necessary files to the VM using `rsync` (excluding build artifacts, logs, node_modules).
4. **Environment Setup**: Transfers the production `.env` configuration.
5. **Build**: Builds Docker images on the VM (not in GitHub Actions).
6. **Deploy**: Starts services in detached mode via `docker compose up -d`.
7. **Health Check**: Waits for services to become healthy and verifies endpoints.
8. **Verification**: Confirms backend API and frontend are accessible.
9. **Cleanup on Failure**: Collects logs and stops containers if deployment fails.

### Manual Deployment

For manual deployment without CI/CD:

```bash
# Transfer files to VM
rsync -avz --exclude='.git' --exclude='node_modules' \
  ./ user@YOUR_VM_IP:~/conduit-deployment/

# SSH into VM
ssh user@YOUR_VM_IP

# Navigate to deployment directory
cd ~/conduit-deployment

# Build and start services
docker compose up -d --build

# Verify services
docker compose ps
curl http://127.0.0.1:8000/api/tags/
curl http://127.0.0.1:8282/
```

## Testing & Verification

Before submitting the project, confirm:

- `http://<VM-IP>:8282` loads the Conduit UI and you can navigate through feed,
  article editor, profile, etc.
- `http://<VM-IP>:8000/api/tags/` responds (health-check uses the same endpoint).
- Killing either container (`docker kill conduit-backend`) triggers an automatic
  restart because of `restart: unless-stopped`.
- Logs can be tailed and persisted via `docker logs` or the mounted volumes.

## Security Guidelines

### Credential Management

- **Never commit secrets** to the repository. All sensitive data (passwords, tokens, API keys, SSH keys) must be stored as environment variables or GitHub Secrets.
- **Use `.env` files** for local development. The `.env` file is ignored by Git and must be created manually on each deployment target.
- **GitHub Secrets** are used for CI/CD workflows. Store production credentials securely in repository settings.

### Environment Variables

All environment variables follow the naming convention: `UPPER_CASE_WITH_UNDERSCORE`

When referencing variables in shell scripts or Docker Compose, always use the `${VARIABLE_NAME}` notation to prevent interpretation errors.

### Network Security

- **No hardcoded IP addresses** in the repository. Use environment variables for host configurations.
- **CORS configuration** restricts allowed origins. Update `CORS_ALLOWED_ORIGINS` in `.env` for production domains.
- **ALLOWED_HOSTS** in Django must be explicitly configured for production deployments.

### Docker Security

- **Multi-stage builds** minimize attack surface by excluding build dependencies from runtime images.
- **Non-root users** are configured where possible to limit container privileges.
- **Health checks** ensure services are monitored and restarted automatically on failure.

### File Permissions

The `.dockerignore` files prevent sensitive files (credentials, logs, caches) from being copied into Docker images during builds.

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



