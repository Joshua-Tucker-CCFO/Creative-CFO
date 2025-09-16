# dbt Cloud Setup Instructions

## Current Status
✅ dbt CLI installed and configured  
✅ Project linked to dbt Cloud (Project ID: 70471823501225)  
✅ Credentials file created at `~/.dbt/dbt_cloud.yml`  
⚠️ Development credentials need to be configured in dbt Cloud

## Next Steps to Complete Setup

### 1. Set up Development Credentials in dbt Cloud
1. Go to [dbt Cloud](https://cloud.getdbt.com/)
2. Navigate to **Account Settings** → **Credentials**
3. Set up your Azure SQL Database connection:
   - **Type**: SQL Server
   - **Server**: `your-server.database.windows.net`
   - **Port**: `1433`
   - **Database**: `your-database-name`
   - **Authentication**: SQL Server Authentication
   - **Username**: `your-username`
   - **Password**: `your-password`
   - **Schema**: `dbt_dev` (or your preferred dev schema)

### 2. Initialize Your dbt Cloud Repository
1. In dbt Cloud, go to your "Creative BI" project
2. Connect to a Git repository (GitHub, GitLab, etc.) or use dbt Cloud's managed repository
3. Upload/sync your local files to the repository

### 3. Test the Connection
Once credentials are set, you can test locally:
```bash
cd ~/fivetran_dbt_project
dbt debug
```

### 4. Compile and Run Models
```bash
# Compile models to check syntax
dbt compile

# Run staging models first
dbt run --models staging.*

# Run all models
dbt run

# Run tests
dbt test
```

## Important Configuration Updates Needed

### Update Database Variables
Edit `dbt_project.yml` and replace these placeholders:
```yaml
vars:
  fivetran_database: 'your_actual_database_name'  # Replace this
  fivetran_schema: 'your_schema_prefix'           # Replace this
```

### Example with Real Values:
```yaml
vars:
  fivetran_database: 'BusinessDataWarehouse'
  fivetran_schema: 'raw'  # If your Fivetran schemas are: raw_xero, raw_cin7_core, raw_shopify
```

## Alternative: Use dbt Cloud IDE
If you prefer to work directly in dbt Cloud:

1. Go to your dbt Cloud project
2. Click **Develop** 
3. Create new files or upload the models we created
4. Use the built-in IDE to run and test models

## Project Structure Summary
Your project now includes:

### Sources (in `models/staging/fivetran_sources.yml`)
- **xero**: invoices, line_items, contacts, accounts, items
- **cin7_core**: sales_orders, sales_order_lines, products, customers, stock_movements  
- **shopify**: orders, order_lines, customers, products, product_variants, transactions

### Staging Models (13 models)
- **Xero**: `stg_xero_invoices`, `stg_xero_line_items`, `stg_xero_contacts`, `stg_xero_items`
- **Cin7**: `stg_cin7_sales_orders`, `stg_cin7_sales_order_lines`, `stg_cin7_products`, `stg_cin7_customers`
- **Shopify**: `stg_shopify_orders`, `stg_shopify_order_lines`, `stg_shopify_customers`, `stg_shopify_products`

### Intermediate Models (3 models)
- `int_sales_transactions`: Unified sales data from all sources
- `int_unified_customers`: Deduplicated customers across systems  
- `int_unified_products`: Consolidated product catalog

### Mart Models (3 models)
- `fct_daily_sales`: Daily sales fact table for Power BI
- `dim_customers`: Customer dimension with segmentation
- `dim_products`: Product dimension with profitability metrics

## Power BI Connection
Once models are built, connect Power BI to these tables in your database:
- `marts.fct_daily_sales` (main fact table)
- `marts.dim_customers` 
- `marts.dim_products`

## Troubleshooting

### Connection Issues
- Ensure your IP is whitelisted in Azure SQL Database firewall
- Verify credentials work with tools like Azure Data Studio or SSMS
- Check that all schema names match your actual Fivetran setup

### Source Data Issues  
- Verify Fivetran connectors are running and syncing data
- Check that table names match what Fivetran creates
- Review column names in actual tables vs our model definitions

### Model Failures
- Run models incrementally: staging → intermediate → marts
- Check logs for specific error details
- Verify source tables exist and have data

## Next Actions Required
1. ✅ Set development credentials in dbt Cloud
2. ✅ Update database/schema variables in `dbt_project.yml`
3. ✅ Upload project to Git repository (if using Git integration)
4. ✅ Run `dbt debug` to test connection  
5. ✅ Execute `dbt run` to build all models
6. ✅ Connect Power BI to the mart tables