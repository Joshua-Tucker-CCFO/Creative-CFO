{{
    config(
        materialized='view'
    )
}}

-- Create a unified product catalog across systems
with xero_products as (
    select
        'Xero' as source_system,
        item_id as product_id,
        item_code as sku,
        item_name as product_name,
        item_description as product_description,
        null as product_category,
        unit_price as selling_price,
        null as cost_price,
        null as stock_on_hand,
        last_synced_at
    from {{ ref('stg_xero_items') }}
),

cin7_products as (
    select
        'Cin7' as source_system,
        product_id,
        sku,
        product_name,
        product_description,
        product_category,
        retail_price as selling_price,
        cost_price,
        stock_on_hand,
        last_synced_at
    from {{ ref('stg_cin7_products') }}
),

shopify_products as (
    select
        'Shopify' as source_system,
        cast(product_id as varchar(50)) as product_id,
        null as sku,  -- SKU is at variant level in Shopify
        product_name,
        null as product_description,
        product_type as product_category,
        null as selling_price,  -- Price is at variant level
        null as cost_price,
        null as stock_on_hand,  -- Inventory is at variant level
        last_synced_at
    from {{ ref('stg_shopify_products') }}
    where is_active = 1
),

combined_products as (
    select * from xero_products
    union all
    select * from cin7_products
    union all
    select * from shopify_products
)

select
    source_system,
    product_id,
    sku,
    product_name,
    product_description,
    product_category,
    selling_price,
    cost_price,
    stock_on_hand,
    last_synced_at,
    concat(source_system, '_', product_id) as unique_product_key,
    -- Calculated fields
    case 
        when selling_price > 0 and cost_price > 0 
        then cast(selling_price - cost_price as decimal(18,2))
        else null 
    end as gross_margin_amount,
    case 
        when selling_price > 0 and cost_price > 0 
        then cast((selling_price - cost_price) / selling_price * 100 as decimal(5,2))
        else null 
    end as gross_margin_percent
from combined_products