{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('shopify', 'orders') }}
    where _fivetran_deleted is null or _fivetran_deleted = false
),

transformed as (
    select
        -- IDs
        id as order_id,
        order_number,
        customer_id,
        
        -- Dates
        cast(created_at as datetime) as created_at,
        cast(processed_at as datetime) as processed_at,
        cast(cancelled_at as datetime) as cancelled_at,
        
        -- Status
        financial_status,
        fulfillment_status,
        
        -- Amounts
        cast(total_price as decimal(18,2)) as total_amount,
        cast(subtotal_price as decimal(18,2)) as subtotal_amount,
        cast(total_tax as decimal(18,2)) as tax_amount,
        cast(
            case 
                when total_shipping_price_set is not null 
                then total_shipping_price_set 
                else 0 
            end as decimal(18,2)
        ) as shipping_amount,
        
        -- Currency
        upper(currency) as currency_code,
        
        -- Flags
        case 
            when cancelled_at is not null then 1 
            else 0 
        end as is_cancelled,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed