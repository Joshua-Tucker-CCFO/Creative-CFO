{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('cin7core', 'product') }}
),

transformed as (
    select
        id as product_id,
        name as product_name,
        _fivetran_synced,
        _fivetran_deleted,
        case
            when _fivetran_deleted = 1 then 'deleted'
            else 'active'
        end as record_status
    from source
    where _fivetran_deleted is null or _fivetran_deleted = 0
)

select * from transformed