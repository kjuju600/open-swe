#!/usr/bin/env bash
#
# Deploy Open-SWE to Railway — run after `railway login`
#
# Usage:
#   cd /home/kevin/data/open-swe
#   bash deploy-to-railway.sh
#
set -euo pipefail

echo "=== Open-SWE Railway Deployment ==="
echo

# Check Railway CLI is authenticated
if ! railway whoami &>/dev/null; then
    echo "ERROR: Not logged in to Railway. Run: railway login"
    exit 1
fi
echo "✓ Railway CLI authenticated"

# Source the .env file to get credentials
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "✓ Loaded .env file"
else
    echo "ERROR: .env file not found"
    exit 1
fi

# Create project if not linked
if ! railway status &>/dev/null 2>&1; then
    echo "Creating Railway project 'open-swe'..."
    railway init --name open-swe
    echo "✓ Project created"
fi

# Set environment variables
echo "Setting environment variables..."
railway vars set \
    ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    SANDBOX_TYPE="local" \
    LLM_MODEL_ID="anthropic:claude-sonnet-4-20250514" \
    GITHUB_APP_ID="$GITHUB_APP_ID" \
    GITHUB_APP_INSTALLATION_ID="$GITHUB_APP_INSTALLATION_ID" \
    GITHUB_WEBHOOK_SECRET="$GITHUB_WEBHOOK_SECRET" \
    DEFAULT_REPO_OWNER="${DEFAULT_REPO_OWNER:-kjuju600}" \
    DEFAULT_REPO_NAME="${DEFAULT_REPO_NAME:-Buffet-System}" \
    LANGCHAIN_TRACING_V2="${LANGCHAIN_TRACING_V2:-true}" \
    LANGCHAIN_PROJECT="${LANGCHAIN_PROJECT:-open-swe}" \
    TOKEN_ENCRYPTION_KEY="$TOKEN_ENCRYPTION_KEY" \
    2>/dev/null && echo "✓ Basic vars set" || echo "⚠ Some vars may have failed"

# Handle multi-line private key separately
if [ -n "${GITHUB_APP_PRIVATE_KEY:-}" ]; then
    # Railway CLI handles multi-line values via stdin
    echo "$GITHUB_APP_PRIVATE_KEY" | railway vars set GITHUB_APP_PRIVATE_KEY 2>/dev/null \
        && echo "✓ GitHub App private key set" \
        || echo "⚠ Private key may need manual setup in Railway dashboard"
fi

# Set optional vars (only if non-empty)
[ -n "${GOOGLE_API_KEY:-}" ] && railway vars set GOOGLE_API_KEY="$GOOGLE_API_KEY" 2>/dev/null
[ -n "${LANGSMITH_API_KEY_PROD:-}" ] && railway vars set LANGSMITH_API_KEY_PROD="$LANGSMITH_API_KEY_PROD" 2>/dev/null
[ -n "${LANGSMITH_TENANT_ID_PROD:-}" ] && railway vars set LANGSMITH_TENANT_ID_PROD="$LANGSMITH_TENANT_ID_PROD" 2>/dev/null
[ -n "${LANGSMITH_TRACING_PROJECT_ID_PROD:-}" ] && railway vars set LANGSMITH_TRACING_PROJECT_ID_PROD="$LANGSMITH_TRACING_PROJECT_ID_PROD" 2>/dev/null
[ -n "${LANGSMITH_URL_PROD:-}" ] && railway vars set LANGSMITH_URL_PROD="$LANGSMITH_URL_PROD" 2>/dev/null
echo "✓ Optional vars set"

# Deploy
echo
echo "Deploying to Railway..."
railway up --detach
echo "✓ Deployment triggered"

echo
echo "=== Next Steps ==="
echo "1. Watch deployment: railway logs"
echo "2. Get public URL: railway domain (or check dashboard → Networking)"
echo "3. Test health: curl https://YOUR-URL/health"
echo "4. Update GitHub App webhook URL to: https://YOUR-URL/webhooks/github"
echo "5. Test: comment @open-swe on a GitHub issue"
echo
