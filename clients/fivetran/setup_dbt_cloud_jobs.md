# dbt Cloud Job Scheduling Setup Guide

## Prerequisites
1. Access to dbt Cloud: https://dh804.us1.dbt.com
2. Admin or Developer permissions in your dbt Cloud project

## Setting Up Job Scheduling

### 1. Navigate to Jobs
1. Log into dbt Cloud at https://dh804.us1.dbt.com
2. Select your project: "Fivetran Azure Project" (ID: 70471823470849)
3. Click on "Jobs" in the left sidebar

### 2. Create Production Job
Click "Create Job" and configure:

**General Settings:**
- Job Name: `Production Run`
- Environment: `Production`
- dbt Version: `1.10.latest`
- Target Name: `prod`

**Commands:**
```bash
dbt seed
dbt run
dbt test
dbt snapshot
```

**Triggers:**
- Schedule: `0 6 * * *` (Daily at 6 AM UTC)
- Run on Schedule: ✓ Enabled
- Run on Pull Request: ✗ Disabled

### 3. Create CI/CD Job
Click "Create Job" and configure:

**General Settings:**
- Job Name: `CI Check`
- Environment: `CI`
- dbt Version: `1.10.latest`
- Target Name: `ci`

**Commands:**
```bash
dbt seed --select state:modified+
dbt run --select state:modified+
dbt test --select state:modified+
```

**Triggers:**
- Run on Schedule: ✗ Disabled
- Run on Pull Request: ✓ Enabled
- Defer to Production Job: ✓ Enabled

### 4. Create Hourly Refresh Job
Click "Create Job" and configure:

**General Settings:**
- Job Name: `Hourly Mart Refresh`
- Environment: `Production`
- dbt Version: `1.10.latest`
- Target Name: `prod`

**Commands:**
```bash
dbt run --select marts.fct_sales marts.dim_customers marts.dim_products
dbt test --select marts.fct_sales marts.dim_customers marts.dim_products
```

**Triggers:**
- Schedule: `0 * * * *` (Every hour)
- Run on Schedule: ✓ Enabled

## GitHub Integration

### 1. Set Up GitHub Connection
1. Go to Account Settings → Integrations
2. Connect your GitHub account
3. Select repository: `dbt-clients-monorepo-proper`
4. Set deployment branch: `main`

### 2. Configure Webhooks
The integration will automatically:
- Trigger CI jobs on pull requests
- Update production on merges to main
- Post status checks back to GitHub

## Required GitHub Secrets

Add these secrets to your GitHub repository:

```bash
# In GitHub repo settings → Secrets → Actions
DBT_SYNAPSE_USER=<your_synapse_username>
DBT_SYNAPSE_PASSWORD=<your_synapse_password>
DBT_CLOUD_TOKEN=<your_dbt_cloud_api_token>
DBT_CLOUD_JOB_ID=<production_job_id>
```

## Get Your dbt Cloud API Token

1. In dbt Cloud, click your profile icon
2. Go to "Account Settings"
3. Click "API Access"
4. Generate new token with permissions:
   - Read/Write access to jobs
   - Read access to metadata

## Monitoring & Alerts

### Set Up Notifications
1. Go to Account Settings → Notifications
2. Configure alerts for:
   - Job failures
   - Test failures
   - Long-running jobs (>30 minutes)

### Configure Slack Integration (Optional)
1. Go to Account Settings → Integrations
2. Connect Slack workspace
3. Select channels for:
   - Success notifications: `#data-success`
   - Failure notifications: `#data-alerts`

## Debugging Failed Jobs

### Common Issues & Solutions

1. **Authentication Failures**
   - Verify environment variables in dbt Cloud
   - Check Azure Synapse firewall rules
   - Ensure service account has proper permissions

2. **Model Compilation Errors**
   - Check SQL syntax for Synapse compatibility
   - Verify all referenced models exist
   - Review macro definitions

3. **Test Failures**
   - Check data quality in source systems
   - Review test thresholds
   - Consider adding severity levels to tests

4. **Performance Issues**
   - Enable incremental models for large tables
   - Adjust thread count in profiles
   - Consider table distributions in Synapse

## Best Practices

1. **Use Incremental Models** for large fact tables
2. **Implement Data Tests** at multiple levels
3. **Document Models** with descriptions and column definitions
4. **Tag Models** for selective runs (e.g., `hourly`, `daily`, `weekly`)
5. **Monitor Run Times** and optimize slow models
6. **Use Exposures** to track downstream dependencies