#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "🔍 Testing Conduit Container Checklist Compliance"
echo "=================================================="
echo ""

ERRORS=0
WARNINGS=0

# Test 1: Check if frontend and backend code exists
echo "1. Checking source code..."
if [ ! -d "frontend/src" ] || [ ! -f "frontend/package.json" ]; then
  echo "   ❌ Frontend code not found"
  ((ERRORS++))
else
  echo "   ✅ Frontend code present"
fi

if [ ! -d "backend/conduit" ] || [ ! -f "backend/manage.py" ]; then
  echo "   ❌ Backend code not found"
  ((ERRORS++))
else
  echo "   ✅ Backend code present"
fi

# Test 2: Check .env file
echo ""
echo "2. Checking environment configuration..."
if [ ! -f ".env" ]; then
  echo "   ⚠️  .env file not found (copy from env.example)"
  ((WARNINGS++))
else
  echo "   ✅ .env file exists"
  if grep -q "please-change-me" .env; then
    echo "   ⚠️  DJANGO_SECRET_KEY still has default value"
    ((WARNINGS++))
  fi
fi

# Test 3: Validate docker-compose.yaml
echo ""
echo "3. Validating docker-compose.yaml..."
if docker compose config > /dev/null 2>&1; then
  echo "   ✅ docker-compose.yaml is valid"
  
  # Check for required services
  if docker compose config 2>/dev/null | grep -q "^  frontend:"; then
    echo "   ✅ Frontend service defined"
  else
    echo "   ❌ Frontend service missing"
    ((ERRORS++))
  fi
  
  if docker compose config 2>/dev/null | grep -q "^  backend:"; then
    echo "   ✅ Backend service defined"
  else
    echo "   ❌ Backend service missing"
    ((ERRORS++))
  fi
else
  echo "   ❌ docker-compose.yaml has errors"
  ((ERRORS++))
fi

# Test 4: Check Dockerfiles
echo ""
echo "4. Checking Dockerfiles..."
for dockerfile in Dockerfile.frontend Dockerfile.backend; do
  if [ -f "${dockerfile}" ]; then
    echo "   ✅ ${dockerfile} exists"
    
    # Check for multi-stage builds
    if grep -q "FROM.*AS" "${dockerfile}"; then
      echo "      ✅ Uses multi-stage build"
    else
      echo "      ⚠️  May not use multi-stage build"
      ((WARNINGS++))
    fi
    
    # Check for EXPOSE
    if grep -q "^EXPOSE" "${dockerfile}"; then
      echo "      ✅ Exposes port"
    else
      echo "      ❌ No EXPOSE directive found"
      ((ERRORS++))
    fi
    
    # Check for ENV variables
    if grep -q "^ENV" "${dockerfile}"; then
      echo "      ✅ Defines environment variables"
    else
      echo "      ⚠️  No ENV variables defined"
      ((WARNINGS++))
    fi
  else
    echo "   ❌ ${dockerfile} missing"
    ((ERRORS++))
  fi
done

# Test 5: Check backend entrypoint uses WSGI (not dev server)
echo ""
echo "5. Checking backend entrypoint..."
if [ -f "docker/backend/entrypoint.sh" ]; then
  if grep -q "gunicorn" "Dockerfile.backend" && ! grep -q "runserver" "Dockerfile.backend"; then
    echo "   ✅ Backend uses Gunicorn (WSGI), not dev server"
  else
    echo "   ❌ Backend may be using dev server"
    ((ERRORS++))
  fi
else
  echo "   ⚠️  Entrypoint script not found"
  ((WARNINGS++))
fi

# Test 6: Check restart policies
echo ""
echo "6. Checking restart policies..."
if docker compose config 2>/dev/null | grep -q "restart: unless-stopped"; then
  echo "   ✅ Restart policy configured"
else
  echo "   ⚠️  Restart policy may be missing"
  ((WARNINGS++))
fi

# Test 7: Check volumes
echo ""
echo "7. Checking volume configurations..."
if docker compose config 2>/dev/null | grep -q "volumes:"; then
  echo "   ✅ Volumes defined"
else
  echo "   ⚠️  No volumes found"
  ((WARNINGS++))
fi

# Test 8: Check README
echo ""
echo "8. Checking README.md..."
if [ -f "README.md" ]; then
  if grep -qi "table of contents\|toc\|inhaltsverzeichnis" README.md; then
    echo "   ✅ README has table of contents"
  else
    echo "   ⚠️  README may be missing table of contents"
    ((WARNINGS++))
  fi
  
  if grep -qi "quickstart" README.md; then
    echo "   ✅ README has Quickstart section"
  else
    echo "   ⚠️  README may be missing Quickstart section"
    ((WARNINGS++))
  fi
  
  if grep -qi "usage" README.md; then
    echo "   ✅ README has Usage section"
  else
    echo "   ⚠️  README may be missing Usage section"
    ((WARNINGS++))
  fi
else
  echo "   ❌ README.md missing"
  ((ERRORS++))
fi

# Summary
echo ""
echo "=================================================="
echo "Summary:"
echo "  Errors:   ${ERRORS}"
echo "  Warnings: ${WARNINGS}"
echo ""

if [ ${ERRORS} -eq 0 ] && [ ${WARNINGS} -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
elif [ ${ERRORS} -eq 0 ]; then
  echo "⚠️  All critical checks passed, but there are warnings"
  exit 0
else
  echo "❌ Some critical checks failed"
  exit 1
fi

