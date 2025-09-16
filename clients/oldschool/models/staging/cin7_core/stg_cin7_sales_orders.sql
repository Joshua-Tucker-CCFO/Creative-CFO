{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7core', 'sale') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        id as sales_order_id,

        -- Order details
        customer_id,
        status as order_status,

        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed