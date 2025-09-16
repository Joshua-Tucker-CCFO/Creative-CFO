# Fix dbt Cloud Git Connection Issue

## Problem Identified
dbt Cloud is trying to access the wrong GitHub repository:
- **Error shows**: `Joshua-Tucker-CCFO/dbt-clients-monorepo.git`
- **Actual repository**: `CreativeCFO/dbt-clients-monorepo.git`

## Solution Steps

### Step 1: Fix Repository URL in dbt Cloud

1. **Go to dbt Cloud**: https://dh804.us1.dbt.com
2. **Navigate to Project Settings**:
   - Click on your project: "Fivetran Azure Project"
   - Go to "Repository" section

3. **Update Repository URL**:
   - Current (wrong): `https://github.com/Joshua-Tucker-CCFO/dbt-clients-monorepo.git`
   - Correct: `https://github.com/CreativeCFO/dbt-clients-monorepo.git`

### Step 2: Re-authenticate GitHub Connection

1. **In dbt Cloud Account Settings**:
   - Go to "Integrations" → "GitHub"
   - Click "Reconnect" or "Add Integration"

2. **Authorize GitHub Access**:
   - Make sure dbt Cloud has access to the `CreativeCFO` organization
   - Grant permissions to the `dbt-clients-monorepo` repository

### Step 3: Check Repository Permissions

#### Option A: Repository Exists but Access Issue
If the repository exists at `CreativeCFO/dbt-clients-monorepo`:

1. **Check repository visibility**:
   - Go to GitHub repository settings
   - Ensure it's either:
     - **Public**, OR
     - **Private** with dbt Cloud app installed

2. **Install dbt Cloud GitHub App**:
   - Go to GitHub → Settings → Applications
   - Find "dbt Cloud" app
   - Grant access to `CreativeCFO/dbt-clients-monorepo`

#### Option B: Repository Doesn't Exist
If you need to create/move the repository:

```bash
# Check if repository exists
curl -s -o /dev/null -w "%{http_code}" https://github.com/CreativeCFO/dbt-clients-monorepo

# If 404, you need to either:
# 1. Create the repository, or
# 2. Update the remote URL to the correct repository
```

### Step 4: Alternative - Create New Repository

If you want to use the current working directory:

1. **Create new repository on GitHub**:
   - Go to GitHub
   - Create new repository: `Joshua-Tucker-CCFO/dbt-clients-monorepo`
   - Make it public or grant dbt Cloud access

2. **Update local remote**:
   ```bash
   git remote set-url origin https://github.com/Joshua-Tucker-CCFO/dbt-clients-monorepo.git
   ```

3. **Push to new repository**:
   ```bash
   git add .
   git commit -m "Initial commit for dbt Cloud integration"
   git push -u origin feature/elt-architecture-v2
   ```

### Step 5: Update dbt Cloud Configuration

1. **In dbt Cloud Project Settings**:
   - Repository URL: `https://github.com/Joshua-Tucker-CCFO/dbt-clients-monorepo.git`
   - Branch: `feature/elt-architecture-v2` (or `main`)
   - Project subfolder: `clients/fivetran` (if applicable)

2. **Test Connection**:
   - Click "Test Connection" in repository settings
   - Should show green checkmark

### Step 6: Fix Environment Configuration

1. **Go to Environments**:
   - Select your environment (Dev/Production)
   - Under "Repository", ensure:
     - Correct repository is selected
     - Branch is set correctly
     - dbt project subfolder: `clients/fivetran`

## Quick Fix Commands

### Option 1: Use Existing Repository Location
```bash
# If CreativeCFO/dbt-clients-monorepo exists
# Just update dbt Cloud to point to correct URL:
# https://github.com/CreativeCFO/dbt-clients-monorepo.git
```

### Option 2: Create Repository Under Your Account
```bash
# Push to your personal account repository
git remote set-url origin https://github.com/Joshua-Tucker-CCFO/dbt-clients-monorepo.git

# Add and commit all files
git add .
git commit -m "Setup dbt project for Cloud integration

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to GitHub
git push -u origin feature/elt-architecture-v2

# Then update dbt Cloud repository settings
```

## Verification Steps

1. **Test Git Integration**:
   - In dbt Cloud IDE, try to refresh git
   - Should see your latest files

2. **Test Job Execution**:
   - Run a simple dbt command: `dbt debug`
   - Should complete without git errors

3. **Check File Access**:
   - In IDE, verify you can see all your model files
   - Make a small change and commit

## Common Issues & Solutions

### Issue: "Repository not found"
- **Cause**: Wrong repository URL or no access
- **Fix**: Update URL in dbt Cloud project settings

### Issue: "Authentication failed"
- **Cause**: GitHub app not installed or permissions revoked
- **Fix**: Reinstall dbt Cloud GitHub app

### Issue: "Branch not found"
- **Cause**: Default branch mismatch
- **Fix**: Set correct branch in dbt Cloud environment settings

### Issue: "Project subfolder not found"
- **Cause**: Incorrect subfolder path
- **Fix**: Set path to `clients/fivetran` if using monorepo structure

## Final Checklist

- [ ] Repository URL updated in dbt Cloud
- [ ] GitHub app permissions granted
- [ ] Branch settings correct
- [ ] Project subfolder configured (if needed)
- [ ] Test connection shows green
- [ ] Git refresh works in IDE
- [ ] Jobs can execute without git errors

## Next Steps After Fix

1. **Run dbt debug** to verify connection
2. **Execute a job** to test full pipeline
3. **Make a test commit** to verify CI/CD integration
4. **Set up job scheduling** for production runs

The key is ensuring dbt Cloud can access the correct repository with proper permissions. Once fixed, all git operations and job executions should work normally.