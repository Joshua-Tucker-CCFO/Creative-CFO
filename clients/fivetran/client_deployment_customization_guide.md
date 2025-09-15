# Client Deployment & Customization Guide

## Deploy Base Schema → Customize Specific Tables/Columns

### Step 1: Deploy Base Template to New Client

```bash
# 1. Copy entire project structure
cp -r clients/fivetran clients/client_b

# 2. Update connection in profiles.yml
cd clients/client_b
```

**profiles.yml:**
```yaml
fivetran_azure:
  outputs:
    client_b:
      type: synapse
      database: ClientB-DB  # Different database
      schema: dbt_client_b
      # Rest stays the same
```

**dbt_project.yml:**
```yaml
vars:
  fivetran_database: 'ClientB-DB'  # Update to new client's DB
  fivetran_schema: 'fivetran'
```

### Step 2: Run Initial Deployment

```bash
# This creates all the same tables/views in ClientB's database
dbt run --target client_b

# Now ClientB has exact same schema as ClientA
```

### Step 3: Customize Specific Tables/Columns

## Method 1: Override Specific Models (Recommended)

Keep base models, override only what's different:

```sql
-- models/staging/base/base_customers.sql (shared)
SELECT
    customer_id,
    customer_name,
    email,
    created_at
FROM {{ source('fivetran', 'customers') }}
```

```sql
-- models/staging/client_overrides/stg_customers_client_b.sql
{{ config(
    enabled=(var('client_name') == 'client_b')
) }}

-- Client B has additional fields
SELECT
    customer_id,
    customer_name,
    email,
    loyalty_tier,        -- Client B specific
    rewards_points,      -- Client B specific
    created_at
FROM {{ source('fivetran', 'customers') }}
```

## Method 2: Conditional Columns with Macros

```sql
-- models/staging/stg_customers.sql (works for all clients)
SELECT
    customer_id,
    customer_name,
    email,

    -- Conditional columns based on client
    {% if var('client_name') == 'client_b' %}
        loyalty_tier,
        rewards_points,
    {% elif var('client_name') == 'client_c' %}
        vip_status,
        credit_limit,
    {% endif %}

    created_at
FROM {{ source('fivetran', 'customers') }}
```

## Method 3: Dynamic Column Selection

```sql
-- macros/get_customer_columns.sql
{% macro get_customer_columns(client_name) %}
    {% set base_columns = ['customer_id', 'customer_name', 'email', 'created_at'] %}

    {% if client_name == 'client_b' %}
        {% set client_columns = base_columns + ['loyalty_tier', 'rewards_points'] %}
    {% elif client_name == 'client_c' %}
        {% set client_columns = base_columns + ['vip_status', 'credit_limit'] %}
    {% else %}
        {% set client_columns = base_columns %}
    {% endif %}

    {{ return(client_columns | join(', ')) }}
{% endmacro %}
```

```sql
-- models/staging/stg_customers.sql
SELECT
    {{ get_customer_columns(var('client_name')) }}
FROM {{ source('fivetran', 'customers') }}
```

## Method 4: Schema Evolution Handling

```sql
-- macros/safe_column.sql
{% macro safe_column(column_name, default_value='NULL', table_alias='') %}
    {% set cols = adapter.get_columns_in_relation(ref('source_table')) %}
    {% set col_names = cols | map(attribute='name') | list %}

    {% if column_name in col_names %}
        {% if table_alias %}
            {{ table_alias }}.{{ column_name }}
        {% else %}
            {{ column_name }}
        {% endif %}
    {% else %}
        {{ default_value }} AS {{ column_name }}
    {% endif %}
{% endmacro %}
```

```sql
-- models/staging/stg_sales.sql
SELECT
    sale_id,
    customer_id,
    amount,

    -- These columns might not exist for all clients
    {{ safe_column('discount_amount', '0') }},
    {{ safe_column('loyalty_points_earned', '0') }},
    {{ safe_column('gift_card_amount', '0') }}

FROM {{ source('fivetran', 'sales') }}
```

## Real-World Example: Customizing fct_sales Table

### Base Model (All Clients)
```sql
-- models/marts/base/base_fct_sales.sql
WITH sales_data AS (
    SELECT
        sale_id,
        customer_id,
        product_id,
        quantity,
        unit_price,
        quantity * unit_price as line_total,
        sale_date
    FROM {{ ref('stg_sales') }}
)

SELECT * FROM sales_data
```

### Client B Customization (Add Commission)
```sql
-- models/marts/client_custom/fct_sales_client_b.sql
{{ config(
    enabled=(var('client_name') == 'client_b'),
    alias='fct_sales'  -- Same table name, replaces base
) }}

WITH sales_data AS (
    SELECT * FROM {{ ref('base_fct_sales') }}
),

-- Client B tracks sales reps and commissions
sales_with_reps AS (
    SELECT
        s.*,
        sr.rep_name,
        sr.commission_rate
    FROM sales_data s
    LEFT JOIN {{ ref('stg_sales_reps') }} sr
        ON s.sale_id = sr.sale_id
)

SELECT
    *,
    line_total * COALESCE(commission_rate, 0) as commission_amount
FROM sales_with_reps
```

### Client C Customization (Add Shipping)
```sql
-- models/marts/client_custom/fct_sales_client_c.sql
{{ config(
    enabled=(var('client_name') == 'client_c'),
    alias='fct_sales'  -- Same table name, replaces base
) }}

WITH sales_data AS (
    SELECT * FROM {{ ref('base_fct_sales') }}
),

-- Client C has complex shipping calculations
sales_with_shipping AS (
    SELECT
        s.*,
        sh.shipping_method,
        sh.shipping_cost,
        sh.estimated_delivery
    FROM sales_data s
    LEFT JOIN {{ ref('stg_shipping') }} sh
        ON s.sale_id = sh.sale_id
)

SELECT
    *,
    line_total + COALESCE(shipping_cost, 0) as total_with_shipping
FROM sales_with_shipping
```

## Deployment Configuration

### dbt_project.yml Setup
```yaml
models:
  fivetran_azure_project:
    # Base models always run
    staging:
      base:
        +enabled: true

      # Client-specific overrides
      client_overrides:
        +enabled: false  # Disabled by default
        stg_customers_client_b:
          +enabled: "{{ var('client_name') == 'client_b' }}"
        stg_customers_client_c:
          +enabled: "{{ var('client_name') == 'client_c' }}"

    marts:
      base:
        +enabled: true
      client_custom:
        +enabled: false  # Enable per client
```

## Workflow for Adding Custom Column

### Example: Client B needs 'tax_exempt' flag in customers

#### Option 1: Quick Override
```sql
-- models/staging/overrides/stg_customers_client_b.sql
{{ config(
    enabled=(var('client_name') == 'client_b'),
    alias='stg_customers'  -- Replaces default stg_customers
) }}

SELECT
    customer_id,
    customer_name,
    email,
    tax_exempt,  -- New column for Client B
    created_at
FROM {{ source('fivetran', 'customers') }}
WHERE _fivetran_deleted = false
```

#### Option 2: Extend Existing Model
```sql
-- models/staging/stg_customers_extended.sql
WITH base_customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

{% if var('client_name') == 'client_b' %}
tax_info AS (
    SELECT
        customer_id,
        tax_exempt
    FROM {{ source('fivetran', 'customer_tax_info') }}
),

final AS (
    SELECT
        b.*,
        COALESCE(t.tax_exempt, false) as tax_exempt
    FROM base_customers b
    LEFT JOIN tax_info t
        ON b.customer_id = t.customer_id
)
{% else %}
final AS (
    SELECT
        *,
        false as tax_exempt  -- Default for other clients
    FROM base_customers
)
{% endif %}

SELECT * FROM final
```

## Handling Different Table Names

```sql
-- macros/get_source_table.sql
{% macro get_source_table(table_type) %}
    {% set client = var('client_name') %}

    {% set table_mappings = {
        'client_a': {
            'customers': 'customer_master',
            'orders': 'sales_orders',
            'products': 'item_master'
        },
        'client_b': {
            'customers': 'clients',
            'orders': 'transactions',
            'products': 'inventory'
        }
    } %}

    {% if client in table_mappings %}
        {{ return(table_mappings[client][table_type]) }}
    {% else %}
        {{ return(table_type) }}  -- Default table name
    {% endif %}
{% endmacro %}
```

```sql
-- models/staging/stg_customers.sql
SELECT *
FROM {{ source('fivetran', get_source_table('customers')) }}
```

## Testing Client-Specific Changes

```yaml
# models/tests/schema.yml
models:
  - name: stg_customers
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique

      # Test only for Client B
      - name: tax_exempt
        tests:
          - not_null:
              enabled: "{{ var('client_name') == 'client_b' }}"

      # Test only for Client C
      - name: credit_limit
        tests:
          - not_null:
              enabled: "{{ var('client_name') == 'client_c' }}"
```

## Deployment Commands

```bash
# Initial deployment (copies everything)
dbt run --target client_b --vars '{"client_name": "client_b"}'

# After customization, run only changed models
dbt run --target client_b --vars '{"client_name": "client_b"}' --select state:modified+

# Test client-specific models
dbt test --target client_b --vars '{"client_name": "client_b"}' --select tag:client_b

# Build everything including tests
dbt build --target client_b --vars '{"client_name": "client_b"}'
```

## Best Practices

1. **Use Aliases** to keep same table names across clients
2. **Use Variables** for client-specific logic
3. **Document Changes** in model descriptions
4. **Test Thoroughly** with client-specific test cases
5. **Version Control** client customizations separately

## Example: Complete Client Setup

```bash
# 1. Deploy base schema
dbt run --target client_new --vars '{"client_name": "client_base"}'

# 2. Add client-specific model
echo "
{{ config(
    enabled=(var('client_name') == 'client_new'),
    alias='dim_customers'
) }}

SELECT
    *,
    -- Client-specific calculation
    CASE
        WHEN total_purchases > 10000 THEN 'VIP'
        WHEN total_purchases > 5000 THEN 'Gold'
        ELSE 'Standard'
    END as customer_tier
FROM {{ ref('base_dim_customers') }}
" > models/marts/client_custom/dim_customers_client_new.sql

# 3. Run with client-specific models
dbt run --target client_new --vars '{"client_name": "client_new"}'

# 4. Verify in database
# Table 'dim_customers' now has extra 'customer_tier' column for this client only
```

## Summary

You can:
1. **Deploy identical schema** to new client in minutes
2. **Override specific tables** completely with client versions
3. **Add/remove columns** conditionally based on client
4. **Handle different source table names** with macros
5. **Mix and match** - most tables identical, few customized

The key is using dbt's features:
- **Variables** (`var('client_name')`)
- **Conditionals** (`{% if %}`)
- **Aliases** (same table name, different content)
- **Enabled configs** (turn models on/off per client)