# Debugging dbt Cloud Failures Guide

## Access Your dbt Cloud Project
URL: https://dh804.us1.dbt.com/dashboard/70471823462734/projects/70471823470849

## Common Failure Points & Solutions

### 1. Check Recent Run History
Navigate to: **Run History** tab in your project

Look for:
- Red failed runs
- Yellow partial success runs
- Error messages in the run logs

### 2. Authentication & Connection Issues

#### Azure Synapse Connection
Your project connects to: `oldschoolbi.database.windows.net`

**Common fixes:**
1. **Check Environment Variables in dbt Cloud:**
   - Go to **Environments** → Select your environment
   - Verify these are set:
     - `DBT_SYNAPSE_USER`
     - `DBT_SYNAPSE_PASSWORD`

2. **Azure Firewall Settings:**
   - Add dbt Cloud IP addresses to Azure SQL firewall
   - dbt Cloud IPs for US region:
     ```
     52.45.144.63
     54.81.134.249
     52.22.161.231
     ```

3. **Test Connection:**
   ```sql
   -- Run this in dbt Cloud IDE to test connection
   select 1 as test_connection
   ```

### 3. Model-Specific Failures

#### Check Model Dependencies
```sql
-- Add this to failing models to debug
{{ config(
    enabled=false  -- Temporarily disable to isolate issues
) }}
```

#### Common SQL Issues for Azure Synapse

1. **IDENTITY columns not supported in CTAS:**
   ```sql
   -- Instead of IDENTITY, use ROW_NUMBER()
   ROW_NUMBER() OVER (ORDER BY some_column) as id
   ```

2. **String aggregation differences:**
   ```sql
   -- Use STRING_AGG instead of GROUP_CONCAT
   STRING_AGG(column_name, ',') WITHIN GROUP (ORDER BY column_name)
   ```

3. **Date functions:**
   ```sql
   -- Use DATEADD instead of DATE_ADD
   DATEADD(day, 1, date_column)
   ```

### 4. Source Data Issues

#### Check Fivetran Sync Status
1. Log into Fivetran dashboard
2. Check connector status for:
   - `cin7core`
   - `shopify`
   - `xero`

#### Validate Source Tables Exist
```sql
-- Run in dbt Cloud IDE
SELECT TOP 10 * FROM [OldSchool-Dev-DB].cin7core.sale;
SELECT TOP 10 * FROM [OldSchool-Dev-DB].shopify.customer;
SELECT TOP 10 * FROM [OldSchool-Dev-DB].xero.contacts;
```

### 5. Incremental Model Issues

#### Reset Incremental Models
```bash
# In dbt Cloud job commands
dbt run --full-refresh --select model_name
```

#### Check for Late-Arriving Data
```sql
-- Add to incremental models
{{ config(
    lookback_days=3  -- Process last 3 days of data
) }}
```

### 6. Test Failures

#### Adjust Test Severity
```yaml
# In schema.yml
models:
  - name: fct_sales
    columns:
      - name: sale_id
        tests:
          - not_null:
              severity: warn  # Change from error to warn
```

#### Add Where Clauses to Tests
```yaml
tests:
  - unique:
      column_name: order_id
      where: "order_date >= '2024-01-01'"  # Only test recent data
```

### 7. Performance Issues

#### Add Distributions for Large Tables
```sql
{{ config(
    materialized='table',
    dist='customer_id',  -- Hash distribute on join key
    index='CLUSTERED COLUMNSTORE INDEX'
) }}
```

#### Optimize Thread Count
In `profiles.yml` or dbt Cloud connection:
```yaml
threads: 4  # Reduce if hitting connection limits
```

### 8. Quick Debugging Commands

Run these in dbt Cloud IDE:

```bash
# Compile without running
dbt compile --select failing_model

# Run with verbose logging
dbt run --select failing_model --debug

# Test specific model
dbt test --select failing_model

# Show dependencies
dbt ls --select +failing_model+

# Run upstream models first
dbt run --select +failing_model
```

## Setting Up Job Notifications

1. Go to **Account Settings** → **Notifications**
2. Configure alerts for:
   - Job failures
   - Long-running jobs (>30 min)
   - Test warnings

3. Add Slack webhook:
   ```json
   {
     "channel": "#data-alerts",
     "username": "dbt Cloud",
     "icon_emoji": ":dbt:"
   }
   ```

## Emergency Fixes

### Rollback to Previous Version
```bash
# In job configuration
dbt run --select model_name --vars '{"rollback_date": "2024-01-01"}'
```

### Disable Failing Models Temporarily
```yaml
# In dbt_project.yml
models:
  fivetran_azure_project:
    marts:
      problem_model:
        +enabled: false
```

### Create Maintenance Job
Job Name: `Emergency Fix`
Commands:
```bash
# Only run critical models
dbt run --select tag:critical
dbt test --select tag:critical --severity error
```

## Monitor Model Performance

### Add Logging
```sql
{{ log("Starting model: " ~ this.name, info=true) }}
{{ log("Row count: " ~ row_count, info=true) }}
```

### Track Run Times
```sql
-- Add to model
{{ config(
    pre_hook="INSERT INTO audit.model_runs VALUES ('{{ this.name }}', GETDATE(), 'start')",
    post_hook="INSERT INTO audit.model_runs VALUES ('{{ this.name }}', GETDATE(), 'end')"
) }}
```

## Get Help

1. **dbt Cloud Support**: support@getdbt.com
2. **dbt Slack Community**: https://getdbt.slack.com
3. **Documentation**: https://docs.getdbt.com
4. **Azure Synapse specifics**: https://docs.getdbt.com/reference/warehouse-setups/synapse-setup