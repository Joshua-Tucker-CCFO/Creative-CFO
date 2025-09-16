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
        lower(email) as email,
        phone,
        
        -- Addresses
        billing_address,
        shipping_address,
        
        -- Credit
        cast(credit_limit as decimal(18,2)) as credit_limit,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed