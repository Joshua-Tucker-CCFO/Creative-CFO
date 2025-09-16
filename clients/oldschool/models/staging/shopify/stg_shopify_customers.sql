{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('shopify', 'customers') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        id as customer_id,
        
        -- Customer details
        lower(email) as email,
        first_name,
        last_name,
        concat(coalesce(first_name, ''), ' ', coalesce(last_name, '')) as full_name,
        phone,
        
        -- Dates
        cast(created_at as datetime) as created_at,
        cast(updated_at as datetime) as updated_at,
        
        -- Metrics
        cast(orders_count as int) as total_orders,
        cast(total_spent as decimal(18,2)) as lifetime_value,
        
        -- Status
        state as customer_state,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
    where state = 'enabled'
)

select * from transformed