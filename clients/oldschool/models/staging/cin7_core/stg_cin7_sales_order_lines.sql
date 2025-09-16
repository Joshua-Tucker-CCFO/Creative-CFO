{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7core', 'sale_order_line') }}
),

transformed as (
    select
        -- IDs
        sale_id as sales_order_id,
        product_id,

        -- Basic line details
        quantity,

        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed