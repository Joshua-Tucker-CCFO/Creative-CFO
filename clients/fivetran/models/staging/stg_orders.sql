{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('fivetran_source', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_date,
        total_amount,
        status,
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