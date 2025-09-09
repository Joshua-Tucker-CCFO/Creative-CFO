# Fivetran dbt Project - Setup Guide

## Project Overview
This dbt project transforms raw data from Fivetran into production-ready models for Power BI reporting. It integrates data from three sources:
- **Xero**: Accounting and invoicing data
- **Cin7 Core**: Inventory management and sales orders
- **Shopify**: E-commerce transactions

## Project Structure

```
fivetran_dbt_project/
├── models/
│   ├── staging/           # Raw data cleanup and type casting
│   │   ├── xero/          # Xero staging models
│   │   ├── cin7_core/     # Cin7 Core staging models
│   │   └── shopify/       # Shopify staging models
│   ├── intermediate/      # Business logic and joins
│   └── marts/            # Final models for BI consumption
│       ├── fct_daily_sales.sql    # Daily sales fact table
│       ├── dim_customers.sql      # Customer dimension
│       └── dim_products.sql       # Product dimension
```

## Quick Start

### 1. Configure Database Connection
Update `profiles.yml` with your Azure SQL Database credentials:

```yaml
fivetran_azure:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 17 for SQL Server'
      server: your-server.database.windows.net
      port: 1433
      database: your-database-name
      schema: dbt_dev
      user: your-username
      password: your-password
```

### 2. Update Project Variables
Edit `dbt_project.yml` to set your database name:

```yaml
vars:
  fivetran_database: 'your_database_name'
```

### 3. Install Dependencies
```bash
pip install dbt-sqlserver
```

### 4. Test Connection
```bash
dbt debug
```

### 5. Run the Models
```bash
# Run all models
dbt run

# Run specific model types
dbt run --models staging.*     # Run all staging models
dbt run --models +fct_daily_sales  # Run fact table and dependencies
```

### 6. Test Data Quality
```bash
dbt test
```

## Power BI Connection

### Connect to the Data Models
1. Open Power BI Desktop
2. Get Data → Azure SQL Database
3. Enter your server and database details
4. Navigate to the `marts` schema
5. Import these tables:
   - `fct_daily_sales` - Main fact table for sales analysis
   - `dim_customers` - Customer attributes
   - `dim_products` - Product attributes

### Recommended Relationships in Power BI
- `fct_daily_sales.source_system` → Filter for multi-source analysis
- `fct_daily_sales.sale_date` → Date dimension
- Join `dim_customers` on `unique_customer_key` for customer analysis
- Join `dim_products` on `unique_product_key` for product analysis

## Key Models

### Fact Table: fct_daily_sales
Daily aggregated sales metrics with:
- Transaction counts and revenue by source system
- Customer counts
- Tax and shipping amounts
- Payment completion rates
- Time-based dimensions (year, quarter, month, week)

### Dimension: dim_customers
Customer master data with:
- Unified customer records across systems
- Lifetime value and order metrics
- Segmentation (VIP, High Value, etc.)
- Activity status (Active, At Risk, Dormant)

### Dimension: dim_products
Product catalog with:
- Unified product records
- Pricing and margin analysis
- Stock levels
- Price tier classification

## Data Freshness
All models include `last_synced_at` timestamps to track data currency. The fact table includes `report_generated_at` for audit purposes.

## Model Materialization Strategy
- **Staging models**: Views (for fresh data)
- **Intermediate models**: Views (for flexibility)
- **Mart models**: Tables (for performance in Power BI)

## Testing
All primary keys have uniqueness and not-null tests. Run tests with:
```bash
dbt test --models model_name
```

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Verify firewall rules allow your IP in Azure
   - Check ODBC driver is installed
   - Confirm credentials in profiles.yml

2. **Source Data Missing**
   - Verify Fivetran connectors are running
   - Check source schema names match configuration
   - Review Fivetran sync logs

3. **Performance Issues**
   - Consider adding indexes (already configured in fact/dim tables)
   - Review Power BI query folding
   - Monitor Azure SQL Database DTU usage

## Next Steps
1. Schedule dbt runs after Fivetran syncs complete
2. Set up alerts for test failures
3. Create Power BI refresh schedule
4. Document business rules for finance team
5. Add incremental loading for large fact tables

## Support
For issues or questions:
- Check dbt logs: `logs/dbt.log`
- Review model documentation: `dbt docs generate && dbt docs serve`
- Validate source data: `dbt run --models staging.* --full-refresh`