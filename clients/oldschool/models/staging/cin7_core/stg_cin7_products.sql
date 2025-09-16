{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7core', 'product') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        id as product_id,
        sku,
        
        -- Product details
        name as product_name,
        description as product_description,
        category as product_category,
        
        -- Pricing
        cast(cost_price as decimal(18,2)) as cost_price,
        cast(retail_price as decimal(18,2)) as retail_price,
        
        -- Inventory
        cast(stock_on_hand as decimal(18,4)) as stock_on_hand,
        
        -- Calculated fields
        cast(retail_price - cost_price as decimal(18,2)) as gross_margin,
        case 
            when retail_price > 0 
            then cast((retail_price - cost_price) / retail_price * 100 as decimal(5,2))
            else 0 
        end as margin_percent,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed