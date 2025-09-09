{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('shopify', 'order_lines') }}
),

transformed as (
    select
        -- IDs
        id as line_id,
        order_id,
        product_id,
        variant_id,
        
        -- Product details
        title as product_title,
        variant_title,
        sku,
        
        -- Quantities and amounts
        cast(quantity as decimal(18,4)) as quantity,
        cast(price as decimal(18,4)) as unit_price,
        cast(quantity * price as decimal(18,2)) as gross_amount,
        cast(total_discount as decimal(18,2)) as discount_amount,
        cast((quantity * price) - total_discount as decimal(18,2)) as net_amount,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed