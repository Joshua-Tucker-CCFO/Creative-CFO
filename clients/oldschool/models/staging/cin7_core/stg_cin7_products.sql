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

        -- Product details
        name as product_name,

        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed