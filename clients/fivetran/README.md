# Fivetran to Azure dbt Project

This dbt project transforms data synced from Fivetran into Azure SQL Database.

## Setup Instructions

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Azure Connection
Update the `profiles.yml` file with your Azure SQL Database credentials:
- Server name
- Database name
- Username and password
- Schema names

### 3. Configure Fivetran Source
Update the variables in `dbt_project.yml`:
- `fivetran_database`: Your Azure database name
- `fivetran_schema`: The schema where Fivetran syncs data

### 4. Test Connection
```bash
dbt debug
```

### 5. Run Models
```bash
# Run all models
dbt run

# Run specific models
dbt run --select staging
dbt run --select marts
```

### 6. Test Data Quality
```bash
dbt test
```

## Project Structure

```
├── models/
│   ├── staging/          # Raw data from Fivetran with light transformations
│   ├── intermediate/      # Business logic transformations
│   └── marts/            # Final analytics-ready tables
├── data/                 # CSV seed files
├── tests/                # Custom data tests
├── macros/               # Reusable SQL functions
└── snapshots/            # SCD Type 2 history tracking
```

## Model Descriptions

### Staging Layer
- `stg_customers`: Cleaned customer data from Fivetran
- `stg_orders`: Cleaned order data from Fivetran  
- `stg_products`: Cleaned product catalog data

### Intermediate Layer
- `int_customer_orders`: Aggregated customer order metrics

### Marts Layer
- `customer_analytics`: Customer segmentation and lifetime value analysis
- `daily_revenue`: Daily revenue metrics with running totals

## Fivetran Metadata Columns
The staging models handle Fivetran's system columns:
- `_fivetran_synced`: Timestamp of last sync
- `_fivetran_deleted`: Soft delete flag (filtered out in staging)

## Running in Production
1. Update `profiles.yml` to use production credentials
2. Run with production target: `dbt run --target prod`
3. Consider scheduling with Azure Data Factory or GitHub Actions