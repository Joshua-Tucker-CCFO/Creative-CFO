{{
    config(
        materialized='view'
    )
}}

with source_data as (
    select * from {{ source('xero', 'line_items') }}
),

transformed as (
    select
        -- IDs
        line_item_id,
        invoice_id,
        
        -- Line item details
        description,
        
        -- Quantities and amounts
        cast(quantity as decimal(18,4)) as quantity,
        cast(unit_amount as decimal(18,4)) as unit_price,
        cast(line_amount as decimal(18,2)) as line_total,
        
        -- Accounting
        account_code,
        tax_type,
        
        -- Metadata
        _fivetran_synced as last_synced_at
        
    from source_data
)

select * from transformed