{{ config(
    materialized='table',
    schema='marts'
) }}

-- Sales fact table for Power BI
-- Based on actual cin7core.sale table columns

WITH sales_data AS (
    SELECT 
        -- Primary keys
        id as sale_id,
        customer_id,
        
        -- Order information
        order_number,
        order_date,
        location,
        type as sale_type,
        status as sale_status,
        order_status,
        fulfilment_status,
        
        -- Financial metrics
        COALESCE(order_total, 0) as total_amount,
        COALESCE(order_tax, 0) as tax_amount,
        COALESCE(order_total_before_tax, 0) as subtotal_amount,
        COALESCE(cogs_amount, 0) as cost_of_goods_sold,
        COALESCE(order_total_before_tax - cogs_amount, 0) as gross_profit,
        
        -- Additional details
        base_currency as currency_code,
        sales_representative,
        price_tier,
        source_channel,
        carrier,
        ship_by as ship_by_date,
        
        -- Status flags
        combined_payment_status as payment_status,
        combined_invoice_status as invoice_status,
        combined_shipping_status as shipping_status,
        
        -- Metadata
        last_modified_on,
        _fivetran_synced
        
    FROM [{{ var('fivetran_database') }}].cin7core.sale
    WHERE _fivetran_deleted = 0 OR _fivetran_deleted IS NULL
)

SELECT 
    -- Core dimensions
    sale_id,
    customer_id,
    order_number,
    order_date,
    location,
    sale_type,
    sale_status,
    order_status,
    fulfilment_status,
    
    -- Financial measures for Power BI
    total_amount,
    tax_amount,
    subtotal_amount,
    cost_of_goods_sold,
    gross_profit,
    CASE 
        WHEN subtotal_amount > 0 
        THEN (gross_profit / subtotal_amount) * 100
        ELSE 0 
    END as gross_margin_percentage,
    
    -- Additional attributes
    currency_code,
    sales_representative,
    price_tier,
    source_channel,
    carrier,
    ship_by_date,
    payment_status,
    invoice_status,
    shipping_status,
    
    -- Date dimensions for Power BI
    CAST(order_date AS DATE) as order_date_key,
    YEAR(order_date) as order_year,
    MONTH(order_date) as order_month,
    DAY(order_date) as order_day,
    DATEPART(quarter, order_date) as order_quarter,
    DATEPART(week, order_date) as order_week,
    DATENAME(weekday, order_date) as order_weekday,
    
    -- Processing metadata
    last_modified_on,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM sales_data