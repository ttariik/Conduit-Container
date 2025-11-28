# Deployment Setup Guide

This guide explains how to configure GitHub Secrets for automated deployment to your cloud VM.

## Required GitHub Secrets

Navigate to your repository on GitHub:
1. Go to `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret`
3. Add each of the following secrets:

### 1. SSH_PRIVATE_KEY

Your private SSH key for authenticating to the cloud VM.

**How to obtain:**
```bash
cat ~/.ssh/v_server_key
```

Copy the entire output including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

**Security note:** Never commit this key to the repository.

### 2. VM_HOST

The IP address or hostname of your cloud VM.

**Example:**
```
YOUR_VM_IP_ADDRESS
```

### 3. VM_USER

The SSH username for connecting to your cloud VM.

**Example:**
```
tsabanovic
```

### 4. ENV_FILE

The complete contents of your production `.env` file.

**How to create:**

1. Copy `env.example` as a template
2. Update all values for production:

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

**Security checklist:**
- [ ] Replace `YOUR_VM_IP` with actual VM IP address
- [ ] Generate a strong `DJANGO_SECRET_KEY` (min. 50 random characters)
- [ ] Set a secure `DJANGO_SUPERUSER_PASSWORD`
- [ ] Set a secure `POSTGRES_PASSWORD`
- [ ] Verify `DJANGO_DEBUG=False` for production
- [ ] Update `DJANGO_ALLOWED_HOSTS` with your actual VM IP
- [ ] Update `CORS_ALLOWED_ORIGINS` with your actual frontend URL

**How to generate a secure Django secret key:**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

## Testing the Workflow

After configuring all secrets:

1. Push a commit to the `conduit` or `main` branch
2. Go to `Actions` tab in your GitHub repository
3. Watch the deployment workflow execution
4. Check the logs for any errors

## Manual Trigger

You can manually trigger the deployment workflow:

1. Go to `Actions` tab
2. Select `Deploy Conduit to Cloud VM` workflow
3. Click `Run workflow`
4. Select the branch and click `Run workflow`

## Troubleshooting

### SSH Connection Failed

- Verify `SSH_PRIVATE_KEY` is correctly copied (including header/footer)
- Verify `VM_HOST` and `VM_USER` are correct
- Ensure firewall allows SSH connections (port 22)

### Build Failed

- Check Docker is installed on the VM
- Verify sufficient disk space on VM
- Review build logs in the Actions tab

### Services Unhealthy

- Check backend logs: `docker logs conduit-backend`
- Verify database is running: `docker ps`
- Check environment variables are correctly set
- Verify ports 8000 and 8282 are not already in use

### Deployment Verification Failed

- Ensure firewall allows traffic on ports 8000 and 8282
- Check services are running: `docker compose ps`
- Test endpoints manually from VM:
  ```bash
  curl http://127.0.0.1:8000/api/tags/
  curl http://127.0.0.1:8282/
  ```

## Security Best Practices

1. **Rotate secrets regularly** (every 90 days minimum)
2. **Use strong passwords** (min. 16 characters, mixed case, numbers, symbols)
3. **Limit SSH key access** (use dedicated deployment key, not personal key)
4. **Monitor deployment logs** for suspicious activity
5. **Keep dependencies updated** regularly for security patches

