{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('fivetran_source', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_name,
        email,
        created_at,
        _fivetran_synced,
        _fivetran_deleted,
        case 
            when _fivetran_deleted = 1 then 'deleted'
            else 'active'
        end as record_status
    from source
    where _fivetran_deleted is null or _fivetran_deleted = 0
)

select * from renamed