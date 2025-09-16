# Centralized Foundation Model Blueprint
## 95% Coverage, 5-Minute Onboarding

## Architecture Overview

```
┌─────────────────────────────────────────┐
│     FOUNDATION LAYER (95% Coverage)     │
│  Universal models all businesses need   │
├─────────────────────────────────────────┤
│         CUSTOMIZATION LAYER (5%)        │
│     Client-specific overrides only      │
└─────────────────────────────────────────┘
```

## Foundation Models Structure

### 1. Core Business Entities (Always Needed)

```
foundation/
├── staging/
│   ├── stg_customers.sql           # Every business has customers
│   ├── stg_products.sql            # Every business has products/services
│   ├── stg_transactions.sql        # Every business has sales/transactions
│   ├── stg_employees.sql           # Staff/team members
│   └── stg_locations.sql           # Stores/offices/warehouses
│
├── intermediate/
│   ├── int_customer_lifetime_value.sql
│   ├── int_product_performance.sql
│   ├── int_revenue_recognition.sql
│   └── int_inventory_levels.sql
│
└── marts/
    ├── core/
    │   ├── dim_customers.sql       # Customer dimension
    │   ├── dim_products.sql        # Product dimension
    │   ├── dim_date.sql            # Date dimension
    │   ├── dim_employees.sql       # Employee dimension
    │   ├── fct_sales.sql           # Sales facts
    │   └── fct_inventory.sql       # Inventory facts
    │
    ├── finance/
    │   ├── profit_and_loss.sql     # P&L statement
    │   ├── balance_sheet.sql       # Balance sheet
    │   ├── cash_flow.sql           # Cash flow
    │   ├── accounts_receivable.sql # AR aging
    │   └── accounts_payable.sql    # AP aging
    │
    ├── marketing/
    │   ├── customer_acquisition.sql # CAC, channels
    │   ├── campaign_performance.sql # ROI, conversions
    │   ├── customer_segments.sql    # RFM, cohorts
    │   └── attribution.sql          # Multi-touch attribution
    │
    ├── operations/
    │   ├── inventory_turnover.sql   # Stock metrics
    │   ├── fulfillment_metrics.sql  # Shipping performance
    │   ├── supplier_performance.sql # Vendor scorecards
    │   └── operational_efficiency.sql
    │
    └── executive/
        ├── kpi_dashboard.sql        # Top-level KPIs
        ├── mrr_arr.sql             # SaaS metrics
        ├── unit_economics.sql      # LTV, CAC, margins
        └── growth_metrics.sql       # YoY, MoM growth
```

## Foundation Model Examples

### Universal Customer Dimension
```sql
-- foundation/marts/core/dim_customers.sql
-- This works for 95% of businesses

{{ config(
    materialized='table',
    indexes=[{'columns': ['customer_id'], 'unique': true}]
) }}

WITH customer_base AS (
    SELECT
        -- Core fields every business has
        customer_id,
        customer_name,
        email,
        phone,

        -- Address (standard across businesses)
        address_line_1,
        address_line_2,
        city,
        state,
        postal_code,
        country,

        -- Universal dates
        first_purchase_date,
        last_purchase_date,
        created_at,
        updated_at,

        -- Standard classifications
        customer_type,  -- B2B/B2C/Internal
        customer_status, -- Active/Inactive/Churned

        -- Geographic
        region,
        territory,

        -- Source
        acquisition_channel,
        acquisition_date

    FROM {{ ref('stg_customers') }}
),

customer_metrics AS (
    SELECT
        customer_id,

        -- Universal metrics every business wants
        COUNT(DISTINCT order_id) as total_orders,
        SUM(order_amount) as lifetime_value,
        AVG(order_amount) as avg_order_value,
        DATEDIFF(day, MIN(order_date), MAX(order_date)) as customer_lifetime_days,
        MAX(order_date) as last_order_date,

        -- Recency, Frequency, Monetary
        DATEDIFF(day, MAX(order_date), CURRENT_DATE) as days_since_last_order,
        COUNT(DISTINCT DATE_TRUNC('month', order_date)) as active_months,
        SUM(CASE WHEN order_date >= DATEADD(month, -12, CURRENT_DATE)
            THEN order_amount ELSE 0 END) as revenue_last_12_months

    FROM {{ ref('fct_sales') }}
    GROUP BY customer_id
),

customer_classification AS (
    SELECT
        customer_id,

        -- Universal customer segments
        CASE
            WHEN revenue_last_12_months >= {{ var('vip_threshold', 10000) }} THEN 'VIP'
            WHEN revenue_last_12_months >= {{ var('gold_threshold', 5000) }} THEN 'Gold'
            WHEN revenue_last_12_months >= {{ var('silver_threshold', 1000) }} THEN 'Silver'
            ELSE 'Bronze'
        END as customer_tier,

        CASE
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'At Risk'
            WHEN days_since_last_order <= 365 THEN 'Dormant'
            ELSE 'Churned'
        END as engagement_status,

        NTILE(10) OVER (ORDER BY lifetime_value DESC) as value_decile,
        NTILE(10) OVER (ORDER BY total_orders DESC) as frequency_decile

    FROM customer_metrics
)

SELECT
    c.*,
    m.total_orders,
    m.lifetime_value,
    m.avg_order_value,
    m.customer_lifetime_days,
    m.last_order_date,
    m.days_since_last_order,
    m.active_months,
    m.revenue_last_12_months,
    cl.customer_tier,
    cl.engagement_status,
    cl.value_decile,
    cl.frequency_decile,

    -- Predictive scores (optional)
    {{ calculate_churn_probability('m.days_since_last_order', 'm.total_orders') }} as churn_probability,
    {{ calculate_clv_prediction('m.avg_order_value', 'm.active_months') }} as predicted_clv

FROM customer_base c
LEFT JOIN customer_metrics m ON c.customer_id = m.customer_id
LEFT JOIN customer_classification cl ON c.customer_id = cl.customer_id
```

### Universal Sales Fact Table
```sql
-- foundation/marts/core/fct_sales.sql
-- Covers every business's sales needs

{{ config(
    materialized='incremental',
    unique_key='transaction_id',
    on_schema_change='sync_all_columns'
) }}

WITH sales_base AS (
    SELECT
        -- Universal transaction fields
        transaction_id,
        order_id,
        line_item_id,

        -- Dimensions (every business has these)
        customer_id,
        product_id,
        employee_id,
        location_id,

        -- Dates (standard across all businesses)
        order_date,
        ship_date,
        delivery_date,

        -- Amounts (universal financial fields)
        quantity,
        unit_price,
        gross_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        net_amount,

        -- Costs and margins
        unit_cost,
        total_cost,
        gross_margin,
        gross_margin_percent,

        -- Classifications
        sales_channel,
        order_type,
        payment_method,
        fulfillment_method,

        -- Status
        order_status,
        payment_status,
        fulfillment_status,

        -- Attribution
        campaign_id,
        promo_code,
        referral_source

    FROM {{ ref('stg_transactions') }}

    {% if is_incremental() %}
        WHERE order_date > (SELECT MAX(order_date) FROM {{ this }})
    {% endif %}
)

SELECT
    *,

    -- Calculated fields every business needs
    EXTRACT(YEAR FROM order_date) as order_year,
    EXTRACT(QUARTER FROM order_date) as order_quarter,
    EXTRACT(MONTH FROM order_date) as order_month,
    EXTRACT(WEEK FROM order_date) as order_week,
    EXTRACT(DOW FROM order_date) as order_day_of_week,

    -- Profitability
    net_amount - total_cost as contribution_margin,
    (net_amount - total_cost) / NULLIF(net_amount, 0) as contribution_margin_percent,

    -- Operational metrics
    DATEDIFF(day, order_date, ship_date) as processing_days,
    DATEDIFF(day, ship_date, delivery_date) as shipping_days,
    DATEDIFF(day, order_date, delivery_date) as total_fulfillment_days

FROM sales_base
```

## Configuration System

### vars.yml (Default Business Rules)
```yaml
# foundation/vars.yml
# Default values that work for 95% of businesses

vars:
  # Customer Segmentation Thresholds
  vip_threshold: 10000
  gold_threshold: 5000
  silver_threshold: 1000

  # Inventory Settings
  reorder_point_days: 14
  safety_stock_multiplier: 1.5

  # Financial Settings
  fiscal_year_start: '01-01'
  default_tax_rate: 0.0725
  default_currency: 'USD'

  # Operational Settings
  business_hours_start: '09:00'
  business_hours_end: '17:00'
  working_days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']

  # Marketing Attribution
  attribution_window_days: 30
  attribution_model: 'last_touch'  # or 'linear', 'time_decay'

  # Date Ranges
  lookback_days: 730  # 2 years of history
  forecast_days: 90   # 3 months forward
```

## Source Mapping System

### Universal Source Mapper
```sql
-- macros/map_source_fields.sql
-- Maps different source systems to standard fields

{% macro map_customer_fields(source_system) %}
    {% set field_mappings = {
        'shopify': {
            'customer_id': 'id',
            'customer_name': "first_name || ' ' || last_name",
            'email': 'email',
            'phone': 'phone',
            'created_at': 'created_at'
        },
        'stripe': {
            'customer_id': 'customer_id',
            'customer_name': 'name',
            'email': 'email',
            'phone': 'metadata_phone',
            'created_at': 'created'
        },
        'quickbooks': {
            'customer_id': 'customer_id',
            'customer_name': 'display_name',
            'email': 'primary_email_addr_address',
            'phone': 'primary_phone_number',
            'created_at': 'metadata_create_time'
        },
        'cin7': {
            'customer_id': 'id',
            'customer_name': 'name',
            'email': 'email',
            'phone': 'phone',
            'created_at': 'created_date'
        },
        'xero': {
            'customer_id': 'contact_id',
            'customer_name': 'name',
            'email': 'email_address',
            'phone': 'phones[0].phone_number',
            'created_at': 'updated_date_utc'
        }
    } %}

    {% set mapping = field_mappings.get(source_system, {}) %}

    SELECT
        {{ mapping.get('customer_id', 'id') }} as customer_id,
        {{ mapping.get('customer_name', 'name') }} as customer_name,
        {{ mapping.get('email', 'email') }} as email,
        {{ mapping.get('phone', 'phone') }} as phone,
        {{ mapping.get('created_at', 'created_at') }} as created_at
    FROM {{ source(source_system, 'customers') }}

{% endmacro %}
```

## Client Onboarding Process

### 1. Initial Setup (< 5 minutes)
```bash
#!/bin/bash
# onboard_client.sh

CLIENT_NAME=$1
DATABASE=$2
SOURCE_SYSTEM=$3  # shopify, stripe, quickbooks, etc.

# Create client configuration
cat > clients/$CLIENT_NAME/client_config.yml <<EOF
# Client: $CLIENT_NAME
# Generated: $(date)

vars:
  client_name: '$CLIENT_NAME'
  database_name: '$DATABASE'
  source_system: '$SOURCE_SYSTEM'

  # Use foundation defaults
  extends: foundation/vars.yml

  # Client-specific overrides (if any)
  # vip_threshold: 15000  # Different VIP threshold
EOF

# Deploy foundation models
dbt run --target $CLIENT_NAME --vars "{'client_name': '$CLIENT_NAME', 'source_system': '$SOURCE_SYSTEM'}"

echo "✅ Client $CLIENT_NAME onboarded with foundation models"
```

### 2. Customization (Only if Needed)
```sql
-- clients/client_name/custom/special_metric.sql
-- Only create if client needs something beyond foundation

{{ config(
    enabled=(var('client_name') == 'special_client')
) }}

-- Client-specific logic here
```

## Testing Framework

### Universal Tests
```yaml
# foundation/tests/schema.yml
version: 2

models:
  - name: dim_customers
    tests:
      - dbt_utils.recency:
          datepart: day
          field: updated_at
          interval: 1
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique
      - name: email
        tests:
          - not_null
          - dbt_utils.not_empty_string

  - name: fct_sales
    tests:
      - dbt_utils.recency:
          datepart: day
          field: order_date
          interval: 1
      - dbt_utils.relationships_where:
          to: ref('dim_customers')
          field: customer_id
          from_condition: "order_date >= dateadd(day, -30, current_date)"
```

## Monitoring & Alerts

### Universal Data Quality Checks
```sql
-- foundation/tests/data_quality/anomaly_detection.sql
{{ config(
    severity='warn',
    tags=['data_quality', 'daily']
) }}

WITH daily_metrics AS (
    SELECT
        DATE_TRUNC('day', order_date) as date,
        COUNT(*) as order_count,
        SUM(net_amount) as revenue
    FROM {{ ref('fct_sales') }}
    WHERE order_date >= DATEADD(day, -30, CURRENT_DATE)
    GROUP BY 1
),

stats AS (
    SELECT
        AVG(order_count) as avg_orders,
        STDDEV(order_count) as stddev_orders,
        AVG(revenue) as avg_revenue,
        STDDEV(revenue) as stddev_revenue
    FROM daily_metrics
    WHERE date < CURRENT_DATE
),

today AS (
    SELECT * FROM daily_metrics
    WHERE date = CURRENT_DATE
)

SELECT
    'Order count anomaly' as check_name,
    today.order_count,
    stats.avg_orders,
    ABS(today.order_count - stats.avg_orders) / NULLIF(stats.stddev_orders, 0) as z_score
FROM today, stats
WHERE ABS(today.order_count - stats.avg_orders) > (2 * stats.stddev_orders)

UNION ALL

SELECT
    'Revenue anomaly' as check_name,
    today.revenue,
    stats.avg_revenue,
    ABS(today.revenue - stats.avg_revenue) / NULLIF(stats.stddev_revenue, 0) as z_score
FROM today, stats
WHERE ABS(today.revenue - stats.avg_revenue) > (2 * stats.stddev_revenue)
```

## ROI & Benefits

### Time Savings
- **Traditional approach**: 2-4 weeks per client
- **Foundation approach**: 5 minutes to 2 hours

### Coverage
- **95% coverage**: Most businesses need the same core metrics
- **5% customization**: Industry-specific or client quirks

### Maintenance
- **Update once**: Foundation improvements benefit all clients
- **Test once**: Universal tests catch issues everywhere
- **Document once**: Self-documenting models

## Implementation Checklist

### Phase 1: Foundation (Do Once)
- [ ] Build core staging models
- [ ] Create universal dimensions
- [ ] Build standard fact tables
- [ ] Add financial models
- [ ] Create marketing analytics
- [ ] Build operational dashboards
- [ ] Add executive KPIs
- [ ] Create universal tests
- [ ] Document everything

### Phase 2: Client Onboarding (Per Client)
- [ ] Run onboarding script (5 min)
- [ ] Map source fields (if different)
- [ ] Override specific vars (if needed)
- [ ] Add custom models (5% cases)
- [ ] Validate with tests
- [ ] Schedule jobs
- [ ] Done!

## Example Client Onboarding Log

```
Client: Acme Corp
Time: 8 minutes total
- Foundation deployment: 3 minutes
- Source mapping: 2 minutes (Shopify → standard)
- Custom override: 3 minutes (added loyalty program metrics)
- Testing & validation: automated
Result: Full analytics stack operational
```

## Summary

**The Foundation Approach:**
1. Build once, use everywhere
2. 95% of businesses have identical needs
3. 5-minute onboarding for standard clients
4. Customization only when truly needed
5. Centralized improvements benefit everyone

**Key Success Factors:**
- Comprehensive foundation models
- Smart source mapping system
- Variable-driven configuration
- Override capability for edge cases
- Automated testing & monitoring

This is how you scale from 1 to 100 clients without 100x the work.