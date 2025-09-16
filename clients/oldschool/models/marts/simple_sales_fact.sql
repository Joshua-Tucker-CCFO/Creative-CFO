{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple sales fact table for Power BI
-- Works with cin7core.sale table directly

WITH cin7_sales AS (
    SELECT 
        id as sale_id,
        CAST(date AS DATE) as sale_date,
        customer_id,
        location as location_name,
        reference as order_reference,
        stage as sale_stage,
        status as sale_status,
        currency_code,
        
        -- Financial metrics
        COALESCE(total, 0) as total_amount,
        COALESCE(tax, 0) as tax_amount,
        COALESCE(total - tax, 0) as subtotal_amount,
        
        -- Metadata
        date as created_date,
        completed_date,
        _fivetran_synced
    FROM [{{ var('fivetran_database') }}].cin7core.sale
    WHERE _fivetran_deleted = 0 OR _fivetran_deleted IS NULL
)

SELECT 
    sale_id,
    sale_date,
    customer_id,
    location_name,
    order_reference,
    sale_stage,
    sale_status,
    currency_code,
    
    -- Metrics for Power BI
    total_amount,
    tax_amount,
    subtotal_amount,
    
    -- Date dimensions for Power BI
    YEAR(sale_date) as sale_year,
    MONTH(sale_date) as sale_month,
    DAY(sale_date) as sale_day,
    DATEPART(quarter, sale_date) as sale_quarter,
    DATEPART(week, sale_date) as sale_week,
    
    -- Processing metadata
    created_date,
    completed_date,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM cin7_sales