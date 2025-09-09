{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('xero', 'items') }}
),

transformed as (
    select
        -- IDs
        item_id,
        code as item_code,
        
        -- Item details
        name as item_name,
        description as item_description,
        
        -- Pricing
        cast(unit_price as decimal(18,2)) as unit_price,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed