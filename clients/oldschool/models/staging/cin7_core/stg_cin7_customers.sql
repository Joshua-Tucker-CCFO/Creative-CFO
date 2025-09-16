{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7core', 'customer') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        id as customer_id,

        -- Customer details
        name as customer_name,
        status,

        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed