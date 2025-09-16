# New Client Onboarding Guide

## Pre-Onboarding Checklist

### Information to Gather:
- [ ] Client name
- [ ] Azure SQL Database name
- [ ] Data sources (Shopify, Cin7, Xero, QuickBooks, etc.)
- [ ] Fivetran connector status (are syncs running?)
- [ ] Business requirements (what reports do they need?)
- [ ] Any custom fields or business logic

## Step-by-Step Onboarding Process

### Step 1: Set Up Project Structure (5 minutes)

```bash
# Clone existing client as template
cd ~/dbt-clients-monorepo-proper/clients
cp -r fivetran new_client_name

# Navigate to new client folder
cd new_client_name
```

### Step 2: Update Configuration Files

#### A. Update `profiles.yml`:
```yaml
new_client:
  target: dev
  outputs:
    dev:
      type: synapse
      driver: 'ODBC Driver 18 for SQL Server'
      server: theirserver.database.windows.net  # Their server
      port: 1433
      database: NewClient-DB                    # Their database
      schema: dbt_dev
      authentication: sql
      user: "{{ env_var('DBT_SYNAPSE_USER') }}"
      password: "{{ env_var('DBT_SYNAPSE_PASSWORD') }}"
```

#### B. Update `dbt_project.yml`:
```yaml
name: 'new_client_project'
vars:
  fivetran_database: 'NewClient-DB'
  fivetran_schema: 'fivetran'

  # Client-specific settings
  client_name: 'new_client'
  vip_threshold: 10000
  tax_rate: 0.08
```

### Step 3: Verify Source Tables

```sql
-- Run this in Azure SQL to see what tables Fivetran created
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('fivetran', 'cin7core', 'shopify', 'xero')
ORDER BY TABLE_SCHEMA, TABLE_NAME
```

### Step 4: Map Source Tables

#### If Same Sources (Cin7, Shopify, Xero):
No changes needed! Skip to Step 5.

#### If Different Sources:
Update `models/staging/fivetran_sources.yml`:

```yaml
version: 2
sources:
  - name: quickbooks  # Instead of xero
    database: "{{ var('fivetran_database') }}"
    schema: quickbooks
    tables:
      - name: customers
      - name: invoices
      - name: items
```

Create staging model `models/staging/quickbooks/stg_quickbooks_customers.sql`:
```sql
{{ config(
    materialized='view'
) }}

SELECT
    id as customer_id,
    display_name as customer_name,
    primary_email_addr_address as email,
    primary_phone_number as phone,
    created_date as created_at
FROM {{ source('quickbooks', 'customers') }}
WHERE active = true
```

### Step 5: Test Connection

```bash
# Set environment variables
export DBT_SYNAPSE_USER="their_username"
export DBT_SYNAPSE_PASSWORD="their_password"

# Test connection
dbt debug --target new_client

# Parse project
dbt parse

# Run a simple model
dbt run --select stg_customers --target new_client
```

### Step 6: Deploy Full Project

```bash
# Run all models
dbt run --target new_client

# Test data quality
dbt test --target new_client

# Generate documentation
dbt docs generate --target new_client
```

### Step 7: Set Up dbt Cloud Job

1. **In dbt Cloud** (https://dh804.us1.dbt.com):
   - Go to Environments → New Environment
   - Name: `new_client_prod`
   - Database: `NewClient-DB`
   - Schema: `dbt_prod`

2. **Create Job**:
   - Name: `New Client Daily Run`
   - Environment: `new_client_prod`
   - Commands:
     ```
     dbt source freshness
     dbt run
     dbt test
     ```
   - Schedule: `0 7 * * *` (7 AM daily)

### Step 8: Create Power BI Connection

1. **In Power BI**:
   - Get Data → Azure SQL Database
   - Server: `theirserver.database.windows.net`
   - Database: `NewClient-DB`
   - Schema: `dbt_prod.marts`

2. **Import Key Tables**:
   - `dim_customers`
   - `dim_products`
   - `fct_sales`
   - `daily_revenue`

## Common Customizations

### Custom Tax Rates
```yaml
# In dbt_project.yml
vars:
  tax_rates:
    new_client: 0.0875  # 8.75% tax
```

### Custom VIP Thresholds
```sql
-- In dim_customers.sql
CASE
    WHEN lifetime_value >= {{ var('vip_threshold', 10000) }} THEN 'VIP'
    WHEN lifetime_value >= 5000 THEN 'Gold'
    ELSE 'Standard'
END as customer_tier
```

### Industry-Specific Metrics
```sql
-- Create models/marts/client_custom/new_client_metrics.sql
{{ config(
    enabled=(var('client_name') == 'new_client')
) }}

-- Add client-specific calculations here
```

## Validation Checklist

### Data Quality Checks:
- [ ] Row counts match source systems
- [ ] No unexpected nulls in key fields
- [ ] Date ranges are correct
- [ ] Financial totals match

### Business Logic:
- [ ] Customer segmentation is accurate
- [ ] Revenue calculations are correct
- [ ] Product categories mapped properly
- [ ] Tax calculations verified

### Performance:
- [ ] Models run in < 5 minutes
- [ ] Incremental models configured
- [ ] Proper indexes created

## Troubleshooting

### Issue: Can't connect to database
```bash
# Check credentials
dbt debug --target new_client

# Verify firewall rules in Azure
# Add dbt Cloud IPs if needed
```

### Issue: Missing source tables
```sql
-- Check what Fivetran actually synced
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'fivetran'
```

### Issue: Different column names
```sql
-- Map columns in staging model
SELECT
    their_customer_id as customer_id,  -- Standardize naming
    their_customer_name as customer_name
FROM {{ source('their_system', 'customers') }}
```

## Quick Commands Reference

```bash
# Deploy to new client
dbt run --target new_client

# Run specific models
dbt run --select staging.shopify --target new_client

# Test everything
dbt test --target new_client

# Generate docs
dbt docs generate --target new_client
dbt docs serve

# Full build
dbt build --target new_client
```

## Time Estimates

- **Identical setup** (same sources): 10-15 minutes
- **Similar setup** (minor differences): 30-60 minutes
- **Different sources** (major changes): 2-4 hours
- **Custom requirements**: Add 1-2 hours

## Next Steps After Onboarding

1. **Schedule daily runs** in dbt Cloud
2. **Connect Power BI** to new marts
3. **Train client** on accessing reports
4. **Monitor** first week of runs
5. **Optimize** slow-running models
6. **Document** any customizations

## Support Contacts

- dbt Cloud issues: support@getdbt.com
- Azure SQL issues: Azure support portal
- Fivetran syncs: support@fivetran.com
- Internal help: #data-engineering Slack channel