{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('shopify', 'products') }}
    where _fivetran_deleted is null or _fivetran_deleted = false
),

transformed as (
    select
        -- IDs
        id as product_id,
        
        -- Product details
        title as product_name,
        vendor,
        product_type,
        handle as url_handle,
        
        -- Dates
        cast(created_at as datetime) as created_at,
        cast(updated_at as datetime) as updated_at,
        cast(published_at as datetime) as published_at,
        
        -- Status
        status as product_status,
        
        -- Flags
        case 
            when status = 'active' then 1 
            else 0 
        end as is_active,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed