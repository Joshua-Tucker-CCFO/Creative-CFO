# OldSchool ELT Architecture

## Overview
This dbt project implements a modern ELT (Extract, Load, Transform) architecture for the OldSchool Business Intelligence Platform, integrating data from Cin7 Core, Xero, and Shopify.

## Architecture Layers

### 1. Extract Layer (`sql/extract/`)
**Purpose**: Raw data processing via stored procedures

**Components**:
- `create_extract_tables.sql` - Creates extract schema and tables
- `stored_procedures/sp_extract_*.sql` - Data extraction procedures

**Process**:
- Stored procedures pull from Fivetran raw tables
- Basic data quality checks applied
- Data loaded into `extract.*` schema tables
- Extraction timestamp added for lineage

**Schedule**: Run stored procedures every 6 hours or as needed

### 2. Staging Layer (`models/staging/`)
**Purpose**: Light transformations and standardization

**Components**:
- `extract_sources.yml` - Source definitions for extract layer
- `stg_*.sql` - Staging transformation models

**Transformations**:
- Column renaming for consistency
- Data type casting
- Basic filtering (e.g., exclude soft deletes)
- Null handling

**Materialization**: Views (fast, no storage cost)

### 3. Intermediate Layer (`models/intermediate/`)
**Purpose**: Business logic and complex joins

**Components**:
- `int_unified_customers.sql` - Cross-system customer deduplication
- `int_unified_products.sql` - Product catalog unification
- `int_sales_transactions.sql` - Sales data harmonization

**Features**:
- Cross-source data unification
- Complex business rules
- Reusable components
- Data quality enrichment

**Materialization**: Views (can be changed to tables for performance)

### 4. Marts Layer (`models/marts/`)
**Purpose**: Business-ready analytical models

**Components**:
- Fact tables for transactional data
- Dimension tables for master data
- Aggregated summary tables
- Domain-specific marts (finance, sales, inventory)

**Materialization**: Tables (optimized for query performance)

### 5. Reporting Layer (`models/reporting/views/`)
**Purpose**: Power BI optimized views

**Components**:
- `vw_customer_overview.sql` - Customer dashboard
- `vw_sales_performance.sql` - Sales analytics
- `vw_inventory_status.sql` - Inventory management
- `vw_business_summary.sql` - Executive dashboard

**Features**:
- Pre-calculated KPIs
- Power BI friendly field names
- Data quality indicators
- Performance optimizations

## Data Flow

```
Raw Fivetran Data → [Stored Procedures] → Extract Layer
Extract Layer → [dbt Staging] → Staging Layer  
Staging Layer → [dbt Intermediate] → Intermediate Layer
Intermediate Layer → [dbt Marts] → Marts Layer
Marts Layer → [dbt Views] → Reporting Layer → Power BI
```

## Implementation Steps

### Phase 1: Extract Layer Setup
1. Run `sql/extract/create_extract_tables.sql` in Azure Synapse
2. Deploy stored procedures from `sql/extract/stored_procedures/`
3. Schedule stored procedure execution

### Phase 2: dbt Configuration
1. Update `profiles.yml` with Azure Synapse connection
2. Run `dbt deps` to install dependencies
3. Run `dbt seed` if using seed data

### Phase 3: Model Deployment
1. Run `dbt run --models staging` to build staging layer
2. Run `dbt run --models intermediate` to build intermediate layer  
3. Run `dbt run --models marts` to build marts layer
4. Run `dbt run --models reporting` to build reporting views

### Phase 4: Testing & Validation
1. Run `dbt test` to validate data quality
2. Run `dbt docs generate && dbt docs serve` for documentation
3. Validate reporting views in Power BI

## Configuration

### Variables (`dbt_project.yml`)
```yaml
vars:
  fivetran_database: 'OldSchool-Dev-DB'
  fivetran_schema: 'fivetran'
```

### Schemas
- `extract` - Extract layer tables
- `staging` - Staging models  
- `intermediate` - Intermediate models
- `marts` - Final business models
- `reporting` - Power BI optimized views

## Data Sources

### Cin7 Core
- Customers, Products, Sales Orders
- Inventory management data
- ~98K customers, ~8.5K products

### Xero
- Invoices, Contacts, Accounts
- Financial/accounting data
- Integration via Fivetran

### Shopify  
- Orders, Customers, Products
- E-commerce transaction data
- Integration via Fivetran

## Performance Considerations

1. **Extract Layer**: Use incremental loading in stored procedures
2. **Staging**: Keep as views for cost efficiency
3. **Intermediate**: Consider tables for complex models
4. **Marts**: Materialize as tables with appropriate indexing
5. **Reporting**: Views for real-time data access

## Monitoring & Maintenance

1. **Data Quality**: Monitor dbt test results
2. **Freshness**: Check source freshness tests
3. **Performance**: Monitor query execution times
4. **Storage**: Monitor data warehouse storage usage

## Business Impact

- **Single Source of Truth**: Unified customer and product data
- **Real-time Analytics**: Fresh data for decision making  
- **Cost Efficiency**: Optimized for Azure Synapse pricing
- **Scalability**: Architecture supports business growth
- **Governance**: Clear data lineage and documentation

## Next Steps

1. Deploy extract layer stored procedures
2. Test dbt models in development environment
3. Set up automated scheduling (Azure Data Factory)
4. Configure Power BI data refresh
5. Implement monitoring and alerting