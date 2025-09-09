{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('fivetran_source', 'products') }}
),

renamed as (
    select
        product_id,
        product_name,
        category,
        price,
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