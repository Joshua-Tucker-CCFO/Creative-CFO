# Complete Project Architecture Breakdown

## 🎯 **PROJECT GOAL**
Build a scalable analytics platform that can onboard new clients in minutes, not weeks, by creating reusable data transformation templates that work for 95% of businesses.

---

## 📁 **ROOT STRUCTURE**
```
dbt-clients-monorepo-proper/
├── clients/           # Each client gets their own folder
├── .github/           # CI/CD automation
├── scripts/           # Deployment automation
└── template/          # Master template for new clients
```

### **Why a Monorepo?**
- **Single source of truth** - Fix a bug once, all clients benefit
- **Shared code** - Macros and logic used across all clients
- **Consistent versioning** - All clients on same dbt version
- **Easier maintenance** - One repo to manage, not 100

---

## 📁 **clients/fivetran/** (Your Current Client)

This is ONE client's complete analytics setup. When you get a new client, you copy this entire folder.

### 📄 **Configuration Files**

#### **dbt_project.yml**
```yaml
name: 'fivetran_azure_project'
profile: 'fivetran_azure'
vars:
  fivetran_database: 'OldSchool-Dev-DB'
  fivetran_schema: 'fivetran'
```
**PURPOSE**: Master control file - tells dbt project name, which database to use, global variables
**WHY**: Without this, dbt doesn't know what project this is or where to build models

#### **profiles.yml**
```yaml
fivetran_azure:
  outputs:
    dev:
      type: synapse
      server: oldschoolbi.database.windows.net
      database: OldSchool-Dev-DB
```
**PURPOSE**: Database connection settings
**WHY**: Each client has different database - this is the ONLY file you change for new clients
**BUSINESS VALUE**: Deploy to new client = change 3 lines here

#### **packages.yml**
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
```
**PURPOSE**: Import reusable functions (like Excel formulas for SQL)
**WHY**: Don't reinvent the wheel - use battle-tested utilities
**EXAMPLE**: `dbt_utils.generate_surrogate_key()` creates unique IDs

---

## 📁 **models/** (The Heart of Your System)

### **The Data Flow Philosophy**
```
Raw (Messy) → Staging (Clean) → Intermediate (Combined) → Marts (Business-Ready)
```

Each layer has a specific job in the assembly line.

---

### 📁 **models/staging/**
**PURPOSE**: First layer - clean up the mess from source systems
**BUSINESS PROBLEM SOLVED**: Every system names things differently

#### **Subfolders by Source System**:

##### 📁 **staging/cin7_core/**
```sql
-- stg_cin7_customers.sql
SELECT
    id as customer_id,              -- Standardize: 'id' → 'customer_id'
    name as customer_name,          -- Standardize: 'name' → 'customer_name'
    email,                          -- Already good
    UPPER(country) as country,      -- Clean: Standardize country format
    created_date as created_at      -- Standardize: dates end with '_at'
FROM {{ source('cin7core', 'contacts') }}
WHERE is_active = 1                 -- Filter: Only active customers
```

**WHY THIS EXISTS**:
- Cin7 calls customers "contacts", we call them "customers"
- Cin7 uses 'id', we want 'customer_id' everywhere
- Some countries are 'usa', others 'USA' - we standardize

##### 📁 **staging/shopify/**
```sql
-- stg_shopify_customers.sql
SELECT
    customer_id,                    -- Shopify already uses good names
    first_name || ' ' || last_name as customer_name,  -- Combine names
    email,
    UPPER(country) as country,      -- Same standardization
    created_at                      -- Shopify already uses '_at'
FROM {{ source('shopify', 'customers') }}
WHERE deleted_at IS NULL            -- Filter: Not deleted
```

**WHY DIFFERENT FROM CIN7**:
- Shopify splits names, Cin7 doesn't
- Shopify marks deleted with timestamp, Cin7 uses boolean
- BUT output is identical structure

##### 📁 **staging/xero/**
```sql
-- stg_xero_contacts.sql
SELECT
    contact_id as customer_id,      -- Xero: 'contact_id' → 'customer_id'
    name as customer_name,
    email_address as email,         -- Xero: 'email_address' → 'email'
    'UNKNOWN' as country,           -- Xero doesn't track country
    updated_date_utc as created_at  -- Best we have
FROM {{ source('xero', 'contacts') }}
WHERE contact_status = 'ACTIVE'
```

**KEY INSIGHT**: All 3 systems have different names, but staging makes them identical!

#### **Core Staging Files**:

##### 📄 **fivetran_sources.yml**
```yaml
version: 2
sources:
  - name: cin7core
    database: "{{ var('fivetran_database') }}"
    schema: cin7core
    tables:
      - name: contacts
        description: "Raw customer data from Cin7"
        columns:
          - name: id
            tests: [unique, not_null]
```

**PURPOSE**: Tells dbt where to find raw data + documents it + tests it
**WHY**: Without this, dbt can't find source tables
**BUSINESS VALUE**: Auto-generates documentation showing data lineage

---

### 📁 **models/intermediate/**
**PURPOSE**: Combine data from multiple sources into unified views
**BUSINESS PROBLEM**: Customer exists in 3 systems - need single view

#### **int_unified_customers.sql**
```sql
WITH cin7_customers AS (
    SELECT * FROM {{ ref('stg_cin7_customers') }}
),
shopify_customers AS (
    SELECT * FROM {{ ref('stg_shopify_customers') }}
),
xero_customers AS (
    SELECT * FROM {{ ref('stg_xero_contacts') }}
),

-- Combine all sources, remove duplicates
all_customers AS (
    SELECT * FROM cin7_customers
    UNION
    SELECT * FROM shopify_customers
    UNION
    SELECT * FROM xero_customers
),

-- Deduplicate by email
final AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_at DESC) as rn
    FROM all_customers
)

SELECT * FROM final WHERE rn = 1
```

**WHY THIS LAYER EXISTS**:
- Same customer might be in all 3 systems
- Need to deduplicate
- Need to pick "best" record when duplicates exist
- Business logic too complex for staging layer

---

### 📁 **models/marts/**
**PURPOSE**: Final tables that Power BI connects to
**BUSINESS RULE**: If Power BI uses it, it lives in marts

#### **dim_customers.sql** (Dimension Table)
```sql
WITH customer_base AS (
    SELECT * FROM {{ ref('int_unified_customers') }}
),

customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) as total_orders,
        SUM(amount) as lifetime_value,
        MAX(order_date) as last_order_date
    FROM {{ ref('fct_sales') }}
    GROUP BY customer_id
),

final AS (
    SELECT
        c.*,
        COALESCE(o.total_orders, 0) as total_orders,
        COALESCE(o.lifetime_value, 0) as lifetime_value,

        -- Business logic: Customer segmentation
        CASE
            WHEN o.lifetime_value > 10000 THEN 'VIP'
            WHEN o.lifetime_value > 5000 THEN 'Gold'
            WHEN o.lifetime_value > 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as customer_tier,

        -- Business logic: Activity status
        CASE
            WHEN DATEDIFF(day, o.last_order_date, CURRENT_DATE) < 30 THEN 'Active'
            WHEN DATEDIFF(day, o.last_order_date, CURRENT_DATE) < 90 THEN 'At Risk'
            ELSE 'Churned'
        END as status

    FROM customer_base c
    LEFT JOIN customer_orders o ON c.customer_id = o.customer_id
)

SELECT * FROM final
```

**WHY IN MARTS**:
- Contains business logic (tiers, status)
- Optimized for reporting (pre-calculated metrics)
- Single table Power BI can use directly

#### **fct_sales.sql** (Fact Table)
```sql
{{ config(
    materialized='incremental',
    unique_key='transaction_id'
) }}

SELECT
    -- Dimensions (foreign keys)
    transaction_id,
    customer_id,
    product_id,

    -- Dates
    order_date,
    ship_date,

    -- Measures (what you sum/average)
    quantity,
    unit_price,
    quantity * unit_price as revenue,
    unit_cost,
    (unit_price - unit_cost) * quantity as profit,

    -- Calculated metrics
    (unit_price - unit_cost) / unit_price as margin_percent

FROM {{ ref('int_sales_transactions') }}

{% if is_incremental() %}
    WHERE order_date > (SELECT MAX(order_date) FROM {{ this }})
{% endif %}
```

**WHY INCREMENTAL**:
- Sales table gets huge (millions of rows)
- Full rebuild takes hours
- Incremental only processes new data (minutes)

---

### 📁 **models/reporting/**
**PURPOSE**: Ready-made views for specific reports
**USE CASE**: CEO dashboard, monthly reports

#### **views/vw_business_summary.sql**
```sql
-- Pre-built executive summary
SELECT
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT CASE WHEN status = 'Active' THEN customer_id END) as active_customers,
    SUM(revenue) as total_revenue,
    AVG(margin_percent) as avg_margin
FROM {{ ref('fct_sales') }}
JOIN {{ ref('dim_customers') }} USING (customer_id)
WHERE order_date >= DATEADD(month, -1, CURRENT_DATE)
```

**WHY**: CEO wants same metrics daily - pre-calculate them

---

## 📁 **macros/** (Reusable Code)

**PURPOSE**: SQL functions you use everywhere
**ANALOGY**: Like Excel formulas you can reuse

#### **get_fiscal_year.sql**
```sql
{% macro get_fiscal_year(date_column) %}
    CASE
        WHEN MONTH({{ date_column }}) >= 7
        THEN YEAR({{ date_column }}) + 1
        ELSE YEAR({{ date_column }})
    END
{% endmacro %}
```

**USAGE**:
```sql
SELECT {{ get_fiscal_year('order_date') }} as fiscal_year
```

**WHY**: Write fiscal year logic once, use everywhere

---

## 📁 **tests/** (Quality Control)

**PURPOSE**: Automated checks that data is correct
**BUSINESS PROBLEM**: Bad data → Bad decisions

#### **Generic Tests** (Built-in):
```yaml
models:
  - name: dim_customers
    columns:
      - name: customer_id
        tests:
          - unique              # No duplicate customers
          - not_null           # Every customer has ID
```

#### **Custom Tests**:
```sql
-- tests/assert_positive_revenue.sql
SELECT *
FROM {{ ref('fct_sales') }}
WHERE revenue < 0  -- Should return no rows
```

**WHY**: Catch issues before CEO sees wrong numbers

---

## 📁 **snapshots/** (History Tracking)

**PURPOSE**: Track how data changes over time
**USE CASE**: Customer changed from 'Silver' to 'Gold' - when?

```sql
{% snapshot customers_snapshot %}
    {{
        config(
          target_schema='snapshots',
          unique_key='customer_id',
          strategy='check',
          check_cols=['customer_tier', 'status']
        )
    }}
    SELECT * FROM {{ ref('dim_customers') }}
{% endsnapshot %}
```

**CREATES**: Table with valid_from/valid_to dates showing history

---

## 📁 **data/** (Seed Files)

**PURPOSE**: Small reference data that doesn't come from systems
**EXAMPLE**: Country codes, tax rates, product categories

```csv
country_code,country_name,region
US,United States,North America
UK,United Kingdom,Europe
AU,Australia,APAC
```

**USAGE**: `dbt seed` loads these into database as tables

---

## 📁 **.github/workflows/** (CI/CD)

**PURPOSE**: Automation - run tests on every code change
**BUSINESS VALUE**: Catch breaks before production

```yaml
on:
  pull_request:
    branches: [main]

jobs:
  test:
    steps:
      - run: dbt test
      - run: dbt run --select state:modified+
```

**WHAT IT DOES**: Every code change automatically tested

---

## 📁 **target/** (Generated Files)

**PURPOSE**: dbt's working directory - compiled SQL, logs
**NOTE**: Don't edit these - automatically generated

---

## 📁 **dbt_packages/** (Downloaded Dependencies)

**PURPOSE**: External packages you imported
**LIKE**: node_modules in JavaScript

---

## 🎯 **How It All Serves The Business Goal**

### **For Your Current Client**:
1. **Staging** standardizes their 3 different systems
2. **Intermediate** combines into single customer view
3. **Marts** provides Power BI-ready analytics
4. **Tests** ensure data quality
5. **Documentation** shows how everything connects

### **For New Clients**:
1. Copy entire folder
2. Change `profiles.yml` (database connection)
3. Adjust `sources.yml` if they use different systems
4. 95% of code works immediately
5. Deploy in minutes, not weeks

### **The Magic**:
- **Staging pattern** means any source system works
- **Intermediate pattern** means business logic is reusable
- **Marts pattern** means Power BI setup is instant
- **Config-driven** means customization without code changes

## 📊 **File Count Breakdown**

```
Total Files: ~50
├── Configuration: 3 files (6%)
├── Staging Models: 15 files (30%)
├── Intermediate Models: 4 files (8%)
├── Mart Models: 12 files (24%)
├── Tests: 5 files (10%)
├── Documentation: 6 files (12%)
└── Macros: 5 files (10%)
```

**Key Insight**: 70% is reusable (intermediate, marts, macros, tests)
Only 30% (staging) might change per client

This architecture is WHY you can onboard clients in minutes - you've built a template that handles 95% of what every business needs!