{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7_core', 'sales_order_lines') }}
),

transformed as (
    select
        -- IDs
        line_id,
        sales_order_id,
        product_id,
        
        -- Line details
        cast(quantity as decimal(18,4)) as quantity,
        cast(unit_price as decimal(18,4)) as unit_price,
        cast(line_total as decimal(18,2)) as line_total,
        cast(discount_percent as decimal(5,2)) as discount_percent,
        
        -- Calculated fields
        cast(line_total / nullif(quantity, 0) as decimal(18,4)) as effective_unit_price,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed