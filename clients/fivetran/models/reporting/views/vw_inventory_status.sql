{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Inventory status dashboard for Power BI
-- Data source: int_unified_products (aggregated from Cin7 Core primarily)
-- Business rules: Configurable stock thresholds, automated margin calculations
-- Performance: Filters out invalid products for optimal query performance
select
    -- Product identifiers
    product_id,
    sku,
    product_name,
    category,
    source_system,
    
    -- Inventory metrics
    coalesce(stock_on_hand, 0) as current_stock,
    cost_price,
    retail_price,
    
    -- Calculated fields
    (retail_price - cost_price) as gross_margin_amount,
    case 
        when cost_price > 0 
        then round(((retail_price - cost_price) / cost_price) * 100, 2)
        else 0 
    end as gross_margin_percent,
    
    -- Stock status categories for Power BI (configurable thresholds)
    case 
        when coalesce(stock_on_hand, 0) = 0 then 'Out of Stock'
        when coalesce(stock_on_hand, 0) <= {{ var('low_stock_threshold', 10) }} then 'Low Stock'
        when coalesce(stock_on_hand, 0) <= {{ var('normal_stock_threshold', 50) }} then 'Normal Stock'
        else 'High Stock'
    end as stock_status,
    
    -- Value classifications
    case 
        when retail_price < 20 then 'Low Value Item'
        when retail_price between 20 and 100 then 'Medium Value Item'
        when retail_price between 100 and 500 then 'High Value Item'
        else 'Premium Item'
    end as price_category,
    
    -- Inventory value
    coalesce(stock_on_hand, 0) * cost_price as inventory_value_cost,
    coalesce(stock_on_hand, 0) * retail_price as inventory_value_retail,
    
    -- Data freshness
    last_synced_at,
    current_timestamp as view_refreshed_at

from {{ ref('int_unified_products') }}

-- Only include active products
where product_name is not null
and sku is not null