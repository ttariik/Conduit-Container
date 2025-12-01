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

#### 1. SSH_PRIVATE_KEY

Private SSH key for server authentication.

Obtain the key:
```bash
cat ~/.ssh/v_server_key
```

Copy the entire output including the header and footer:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

**Security note:** Never commit this key to the repository.

#### 2. VM_HOST

Cloud VM IP address or hostname (e.g., `203.0.113.42`).

#### 3. VM_USER

SSH username for the cloud VM (e.g., `tsabanovic`).

#### 4. ENV_FILE

Complete contents of your production `.env` file. Copy `env.example` as a template and update all values:

```bash
# Frontend configuration
FRONTEND_PORT=8282
API_URL=http://YOUR_VM_IP:8000/api
FRONTEND_BUILD_CONFIGURATION=production
FRONTEND_PRODUCTION=true

# Backend configuration
BACKEND_PORT=8000
BACKEND_PYTHON_VERSION=3.11-slim
DJANGO_ALLOWED_HOSTS=YOUR_VM_IP,127.0.0.1,localhost
DJANGO_SECRET_KEY=YOUR_SECURE_RANDOM_SECRET_KEY
DJANGO_DEBUG=False
DJANGO_MANAGEPY_MAKEMIGRATIONS=0
DJANGO_MANAGEPY_MIGRATE=1
DJANGO_MANAGEPY_COLLECTSTATIC=1
DJANGO_SUPERUSER_EMAIL=YOUR_ADMIN_EMAIL
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_PASSWORD=YOUR_SECURE_PASSWORD

# CORS configuration
CORS_ALLOWED_ORIGINS=http://YOUR_VM_IP:8282

# Database configuration
POSTGRES_DB=conduit
POSTGRES_USER=conduit
POSTGRES_PASSWORD=YOUR_SECURE_DB_PASSWORD
POSTGRES_PORT=5432
DATABASE_URL=postgresql://conduit:YOUR_SECURE_DB_PASSWORD@db:5432/conduit

# Logging
GUNICORN_LOG_LEVEL=info
GUNICORN_TIMEOUT=30
```

**Production security checklist:**
- Replace `YOUR_VM_IP` with actual VM IP address
- Generate a strong `DJANGO_SECRET_KEY` (min. 50 random characters): `python3 -c "import secrets; print(secrets.token_urlsafe(50))"`
- Set secure passwords for `DJANGO_SUPERUSER_PASSWORD` and `POSTGRES_PASSWORD` (min. 16 characters)
- Verify `DJANGO_DEBUG=False` for production
- Update `DJANGO_ALLOWED_HOSTS` with your actual VM IP
- Update `CORS_ALLOWED_ORIGINS` with your actual frontend URL
- Set `GITHUB_REPOSITORY` to your repository (lowercase, e.g., `ttariik/conduit-container`)
- Set `IMAGE_TAG` to match your branch name (e.g., `conduit` or `main`)

### Workflow Steps

**Build Job (runs in GitHub Actions):**
1. **Checkout**: Fetches the repository code including submodules.
2. **Docker Buildx Setup**: Configures multi-platform build support.
3. **Registry Login**: Authenticates to GitHub Container Registry (ghcr.io).
4. **Build Backend**: Builds backend Docker image with caching.
5. **Push Backend**: Pushes backend image to registry.
6. **Build Frontend**: Builds frontend Docker image with caching.
7. **Push Frontend**: Pushes frontend image to registry.

**Deploy Job (runs on Cloud VM):**
1. **Checkout**: Fetches deployment configuration.
2. **SSH Setup**: Configures SSH authentication using the provided private key.
3. **File Transfer**: Syncs necessary files to the VM using `rsync`.
4. **Environment Setup**: Transfers the production `.env` configuration.
5. **Registry Login**: Authenticates VM to GitHub Container Registry.
6. **Pull Images**: Downloads pre-built images from registry (no build on VM).
7. **Deploy**: Starts services in detached mode via `docker compose up -d`.
8. **Health Check**: Waits for services to become healthy and verifies endpoints.
9. **Verification**: Confirms backend API and frontend are accessible.
10. **Cleanup on Failure**: Collects logs and stops containers if deployment fails.

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

### Container Registry Setup

The workflow uses GitHub Container Registry (ghcr.io) to store Docker images. After the first deployment:

1. Go to your repository on GitHub
2. Navigate to `Packages` (on the right sidebar)
3. For each package (`conduit-container-backend` and `conduit-container-frontend`):
   - Click on the package
   - Go to `Package settings`
   - Scroll to `Danger Zone` → `Change package visibility`
   - Set to `Public` (or grant VM access to private packages)

**Note:** The `GITHUB_TOKEN` secret has `packages: write` permission automatically in GitHub Actions.

### Triggering Deployments

**Automatic trigger:**
- Push a commit to the `conduit` or `main` branch
- The workflow builds images in GitHub Actions (not on VM)
- Pre-built images are pushed to GitHub Container Registry
- VM pulls and deploys the pre-built images

**Manual trigger:**
1. Go to `Actions` tab
2. Select `Deploy Conduit to Cloud VM` workflow
3. Click `Run workflow`
4. Select the branch and click `Run workflow`

### Troubleshooting Deployment Issues

**SSH Connection Failed:**
- Verify `SSH_PRIVATE_KEY` is correctly copied (including header/footer)
- Verify `VM_HOST` and `VM_USER` are correct
- Ensure firewall allows SSH connections (port 22)

**Build Failed:**
- Check Docker is installed on the VM
- Verify sufficient disk space on VM
- Review build logs in the Actions tab

**Services Unhealthy:**
- Check backend logs: `docker logs conduit-backend`
- Verify database is running: `docker ps`
- Check environment variables are correctly set
- Verify ports 8000 and 8282 are not already in use

**Deployment Verification Failed:**
- Ensure firewall allows traffic on ports 8000 and 8282
- Check services are running: `docker compose ps`
- Test endpoints manually from VM: `curl http://127.0.0.1:8000/api/tags/`

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

### Security Best Practices

1. **Rotate secrets regularly** (every 90 days minimum)
2. **Use strong passwords** (min. 16 characters, mixed case, numbers, symbols)
3. **Limit SSH key access** (use dedicated deployment key, not personal key)
4. **Monitor deployment logs** for suspicious activity
5. **Keep dependencies updated** regularly for security patches

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



