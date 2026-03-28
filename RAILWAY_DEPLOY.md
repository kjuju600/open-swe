# Railway Deployment Guide for Open-SWE

## What's Already Done
- [x] Forked to kjuju600/open-swe with your customizations
- [x] Dockerfile.railway created (Python 3.12, Node 22, git)
- [x] railway.toml configured (health check, restart policy)
- [x] Railway CLI installed (`railway` command available)

## Step 1: Login to Railway CLI (2 minutes)

Run this in your terminal (will open a browser):
```bash
railway login
```

Or if headless:
```bash
railway login --browserless
```

Verify:
```bash
railway whoami
```

## Step 2: Create Project and Deploy (5 minutes)

```bash
cd /home/kevin/data/open-swe

# Create a new Railway project
railway init --name open-swe

# Link to the GitHub repo for auto-deploy
railway link

# Deploy
railway up
```

**OR via the Railway Dashboard (easier):**
1. Go to https://railway.app/dashboard
2. Click "New Project"
3. Select "Deploy from GitHub Repo"
4. Choose `kjuju600/open-swe`
5. Railway will auto-detect the Dockerfile.railway

## Step 3: Set Environment Variables

In the Railway dashboard (or via CLI), set these env vars:

```bash
# Core (required)
railway vars set ANTHROPIC_API_KEY="sk-ant-api03-..."
railway vars set SANDBOX_TYPE="local"
railway vars set LLM_MODEL_ID="anthropic:claude-sonnet-4-20250514"

# GitHub App (required)
railway vars set GITHUB_APP_ID="3171515"
railway vars set GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n..."
railway vars set GITHUB_APP_INSTALLATION_ID="118605823"
railway vars set GITHUB_WEBHOOK_SECRET="ada2d58b649d93178b19b7fe73d60160e405bf4271c535e794f940018ce43d9c"

# Default repo
railway vars set DEFAULT_REPO_OWNER="kjuju600"
railway vars set DEFAULT_REPO_NAME="Buffet-System"

# LangSmith (observability)
railway vars set LANGSMITH_API_KEY_PROD="lsv2_pt_d83fc9cd..."
railway vars set LANGCHAIN_TRACING_V2="true"
railway vars set LANGCHAIN_PROJECT="open-swe"
railway vars set LANGSMITH_TENANT_ID_PROD="8755a65c-05c7-4dfc-a63c-957c9858e008"
railway vars set LANGSMITH_TRACING_PROJECT_ID_PROD="532a50db-bcc1-49c7-a89d-bcb1b235227a"
railway vars set LANGSMITH_URL_PROD="https://smith.langchain.com"

# Token encryption
railway vars set TOKEN_ENCRYPTION_KEY="+CXQmvZPtW/IWaMRLHuZ7KaQVLCN+tXOU9GtJt5/X3Q="

# Google (optional backup LLM)
railway vars set GOOGLE_API_KEY="AIzaSyD..."
```

**IMPORTANT:** For GITHUB_APP_PRIVATE_KEY, the RSA key must have literal `\n`
converted to actual newlines. In the Railway dashboard, paste the actual
multi-line key. Via CLI, use quotes carefully.

## Step 4: Get the Public URL

After deployment, Railway assigns a URL like:
```
https://open-swe-production-XXXX.up.railway.app
```

Find it in:
- Railway dashboard → your service → Settings → Networking → Public URL
- Or: `railway domain`

**Enable public networking** if not already:
- Dashboard → Service → Settings → Networking → "Generate Domain"

## Step 5: Test Health Endpoint

```bash
curl https://YOUR-RAILWAY-URL/health
# Should return: {"status": "healthy"}
```

## Step 6: Update GitHub App Webhook

1. Go to https://github.com/settings/apps (find your Open-SWE app)
2. Or: https://github.com/organizations/YOUR_ORG/settings/apps
3. Click on the app → General → Webhook URL
4. Change from the old ngrok URL to:
   ```
   https://YOUR-RAILWAY-URL/webhooks/github
   ```
5. Click "Save changes"
6. Test: Go to the "Advanced" tab → "Recent Deliveries" → click "Redeliver" on a recent one

## Step 7: End-to-End Test

1. Go to any open issue on kjuju600/Buffet-System
2. Add a comment: `@open-swe please add a comment to this file explaining what it does`
3. Watch Railway logs: `railway logs`
4. Verify: Open-SWE should create a PR within 5-10 minutes

## Step 8: Disable Local Services (after 2-3 days stable)

```bash
systemctl --user stop ngrok-openswe.service openswe.service
systemctl --user disable ngrok-openswe.service openswe.service openswe-webhook-update.service
```

## Troubleshooting

**Build fails:**
- Check Railway build logs in dashboard
- Ensure Dockerfile.railway is in the repo root

**Webhook not received:**
- Check GitHub App → Advanced → Recent Deliveries for errors
- Ensure Railway service has public networking enabled
- Verify the webhook URL ends with `/webhooks/github`

**Agent fails to clone repo:**
- Check GITHUB_APP_PRIVATE_KEY is correct (no extra escaping)
- Verify GITHUB_APP_INSTALLATION_ID matches your installation

**Logs:**
```bash
railway logs        # Live logs
railway logs -n 100 # Last 100 lines
```
