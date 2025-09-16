{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('xero', 'contacts') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        contact_id,
        
        -- Contact details
        name as contact_name,
        lower(email_address) as email,
        contact_status as status,
        
        -- Contact type flags
        cast(is_customer as bit) as is_customer,
        cast(is_supplier as bit) as is_supplier,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
    where contact_status = 'ACTIVE'
)

select * from transformed