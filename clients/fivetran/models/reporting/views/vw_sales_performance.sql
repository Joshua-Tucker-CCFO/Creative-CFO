{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Sales performance dashboard view optimized for Power BI
select
    -- Time dimensions
    order_date,
    year(order_date) as order_year,
    month(order_date) as order_month,
    quarter(order_date) as order_quarter,
    format(order_date, 'yyyy-MM') as year_month,
    
    -- Source system
    source_system,
    
    -- Order details
    order_id,
    order_number,
    customer_id,
    
    -- Financial metrics
    total_amount,
    subtotal_amount,
    tax_amount,
    shipping_amount,
    currency_code,
    
    -- Performance indicators for Power BI
    case 
        when total_amount < 50 then 'Small Order'
        when total_amount between 50 and 200 then 'Medium Order'
        when total_amount between 200 and 1000 then 'Large Order'
        else 'Premium Order'
    end as order_size_category,
    
    -- Status flags
    order_status,
    is_cancelled,
    
    -- Data quality indicators
    case 
        when customer_id is null then 'Missing Customer'
        when total_amount <= 0 then 'Invalid Amount'
        when order_date is null then 'Missing Date'
        else 'Valid'
    end as data_quality_flag,
    
    -- Freshness
    last_synced_at,
    current_timestamp as view_refreshed_at

from {{ ref('int_sales_transactions') }}

-- Only include valid transactions for reporting
where order_date >= '2020-01-01'  -- Historical cutoff
and total_amount > 0