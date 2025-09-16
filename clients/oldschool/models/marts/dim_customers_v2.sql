{{ config(
    materialized='table',
    schema='marts'
) }}

-- Customer dimension for Power BI
-- Based on actual cin7core.customer table columns

SELECT 
    -- Primary key
    id as customer_id,
    
    -- Customer information
    name as customer_name,
    status as customer_status,
    location as default_location,
    
    -- Financial information
    COALESCE(credit_limit, 0) as credit_limit,
    COALESCE(discount, 0) as customer_discount,
    price_tier,
    payment_term,
    currency,
    is_on_credit_hold as on_credit_hold,
    
    -- Tax and accounting
    tax_rule,
    tax_number,
    account_receivable,
    revenue_account,
    
    -- Additional attributes
    sales_representative,
    carrier as preferred_carrier,
    tags,
    comments,
    attribute_set,
    
    -- Metadata
    last_modified_on,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM [{{ var('fivetran_database') }}].cin7core.customer
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
  AND status = 'Active'  -- Only include active customers