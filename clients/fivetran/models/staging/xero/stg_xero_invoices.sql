{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('xero', 'invoices') }}
    where _fivetran_deleted is null or _fivetran_deleted = false
),

transformed as (
    select
        -- IDs
        invoice_id,
        invoice_number,
        contact_id,
        
        -- Invoice details
        type as invoice_type,
        status as invoice_status,
        
        -- Dates
        cast(date as date) as invoice_date,
        cast(due_date as date) as due_date,
        
        -- Amounts (ensure proper decimal precision)
        cast(total as decimal(18,2)) as total_amount,
        cast(sub_total as decimal(18,2)) as subtotal_amount,
        cast(total_tax as decimal(18,2)) as tax_amount,
        
        -- Currency
        upper(currency_code) as currency_code,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed