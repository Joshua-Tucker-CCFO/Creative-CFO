{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('cin7core', 'sale') }}
    where _fivetran_deleted is null or _fivetran_deleted = 0
),

transformed as (
    select
        -- IDs
        id as sales_order_id,
        order_number,
        customer_id,
        
        -- Order details
        status as order_status,
        
        -- Dates
        cast(order_date as date) as order_date,
        
        -- Amounts
        cast(total_amount as decimal(18,2)) as total_amount,
        cast(subtotal as decimal(18,2)) as subtotal_amount,
        cast(tax_amount as decimal(18,2)) as tax_amount,
        
        -- Currency
        upper(currency) as currency_code,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed