{{
    config(
        materialized='table',
    )
}}

-- Product dimension table with enriched attributes
select
    unique_product_key,
    source_system,
    product_id as source_product_id,
    sku,
    product_name,
    product_description,
    
    -- Product categorization
    coalesce(product_category, 'Uncategorized') as product_category,
    
    -- Pricing
    selling_price,
    cost_price,
    gross_margin_amount,
    gross_margin_percent,
    
    -- Price points for analysis
    case
        when selling_price >= 1000 then 'Premium'
        when selling_price >= 100 then 'Mid-Range'
        when selling_price >= 20 then 'Standard'
        when selling_price > 0 then 'Budget'
        else 'No Price'
    end as price_tier,
    
    -- Inventory
    coalesce(stock_on_hand, 0) as current_stock,
    
    -- Stock status
    case
        when stock_on_hand > 100 then 'High Stock'
        when stock_on_hand > 20 then 'Normal Stock'
        when stock_on_hand > 0 then 'Low Stock'
        when stock_on_hand = 0 then 'Out of Stock'
        else 'Stock Unknown'
    end as stock_status,
    
    -- Profitability classification
    case
        when gross_margin_percent >= 50 then 'High Margin'
        when gross_margin_percent >= 30 then 'Medium Margin'
        when gross_margin_percent >= 10 then 'Low Margin'
        when gross_margin_percent > 0 then 'Minimal Margin'
        when gross_margin_percent is null then 'Unknown Margin'
        else 'Negative Margin'
    end as margin_classification,
    
    -- Data quality flags
    case when sku is null then 0 else 1 end as has_sku,
    case when selling_price is null or selling_price = 0 then 0 else 1 end as has_price,
    case when product_category is null then 0 else 1 end as has_category,
    
    -- Metadata
    last_synced_at,
    getdate() as dimension_updated_at

from {{ ref('int_unified_products') }}