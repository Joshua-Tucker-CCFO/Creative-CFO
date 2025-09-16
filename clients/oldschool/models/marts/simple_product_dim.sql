{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple product dimension for Power BI
-- Works with cin7core.product table directly

SELECT 
    id as product_id,
    code as product_code,
    name as product_name,
    description as product_description,
    
    -- Product categorization
    category,
    brand,
    supplier_name,
    supplier_code,
    
    -- Pricing and costs
    COALESCE(retail_price, 0) as retail_price,
    COALESCE(wholesale_price, 0) as wholesale_price,
    COALESCE(cost_price, 0) as cost_price,
    COALESCE(retail_price - cost_price, 0) as gross_margin,
    CASE 
        WHEN retail_price > 0 
        THEN ((retail_price - cost_price) / retail_price) * 100
        ELSE 0 
    END as margin_percentage,
    
    -- Inventory information
    COALESCE(stock_on_hand, 0) as current_stock_on_hand,
    COALESCE(available, 0) as available_stock,
    stock_locator,
    barcode,
    
    -- Product attributes
    unit_of_measure,
    weight,
    width,
    height,
    depth,
    
    -- Status flags
    never_diminishing,
    sellable,
    purchasable,
    notes,
    
    -- Metadata
    created_date,
    modified_date,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM [{{ var('fivetran_database') }}].cin7core.product
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
