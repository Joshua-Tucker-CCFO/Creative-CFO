{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Optimized customer overview for Power BI dashboards
-- Data source: int_unified_customers (unified across Cin7, Xero, Shopify)
-- Refresh frequency: Daily via dbt Cloud
-- Performance note: Filters to active customers only for optimal query performance
select
    -- Customer identifiers
    unique_customer_key,
    customer_name,
    email,
    phone,
    source_system as primary_source,
    
    -- Customer metrics (from marts layer)
    coalesce(lifetime_value, 0) as customer_lifetime_value,
    coalesce(total_orders, 0) as total_orders_count,
    
    -- Calculated fields for Power BI
    case 
        when coalesce(total_orders, 0) = 0 then 'New Customer'
        when coalesce(total_orders, 0) between 1 and 5 then 'Regular Customer'
        when coalesce(total_orders, 0) between 6 and 20 then 'Valued Customer'
        else 'VIP Customer'
    end as customer_segment,
    
    case 
        when coalesce(lifetime_value, 0) < 100 then 'Low Value'
        when coalesce(lifetime_value, 0) between 100 and 500 then 'Medium Value'
        when coalesce(lifetime_value, 0) between 500 and 2000 then 'High Value'
        else 'Premium Value'
    end as value_tier,
    
    -- Data freshness
    last_synced_at,
    current_timestamp as view_refreshed_at
    
from {{ ref('int_unified_customers') }}

-- Optimization: Only include active customers for reporting
where email is not null
and customer_name is not null