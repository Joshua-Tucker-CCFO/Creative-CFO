{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple customer dimension for Power BI
-- Works with cin7core.customer table directly

SELECT 
    id as customer_id,
    code as customer_code,
    name as customer_name,
    email as customer_email,
    phone as customer_phone,
    mobile as customer_mobile,
    fax as customer_fax,
    website as customer_website,
    
    -- Address information
    billing_address_line_1,
    billing_address_line_2,
    billing_city,
    billing_state,
    billing_postal_code,
    billing_country,
    
    -- Business information
    credit_limit,
    discount as customer_discount,
    payment_term as payment_terms,
    account_receivable,
    revenue_account,
    tax_rule,
    price_tier,
    
    -- Status flags
    on_credit_hold,
    
    -- Metadata
    created_date,
    modified_date,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM [{{ var('fivetran_database') }}].cin7core.customer
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
