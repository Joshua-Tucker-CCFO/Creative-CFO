-- Simple sales fact table for Power BI
-- No config block to avoid Synapse-specific syntax

SELECT 
    -- Primary keys
    id as sale_id,
    customer_id,
    
    -- Order information
    order_number,
    CAST(order_date AS DATE) as order_date,
    location,
    type as sale_type,
    status as sale_status,
    order_status,
    
    -- Financial metrics (all converted to DECIMAL for consistency)
    CAST(COALESCE(order_total, 0) AS DECIMAL(18,2)) as total_amount,
    CAST(COALESCE(order_tax, 0) AS DECIMAL(18,2)) as tax_amount,
    CAST(COALESCE(order_total_before_tax, 0) AS DECIMAL(18,2)) as subtotal_amount,
    
    -- Additional details
    base_currency as currency_code,
    sales_representative,
    source_channel,
    
    -- Date dimensions for Power BI
    YEAR(order_date) as order_year,
    MONTH(order_date) as order_month,
    DATEPART(quarter, order_date) as order_quarter
    
FROM [OldSchool-Dev-DB].cin7core.sale
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
  AND order_date IS NOT NULL