{{ config(
    materialized='table',
    schema='marts'
) }}

-- Product dimension for Power BI
-- Based on actual cin7core.product table columns

SELECT 
    -- Primary key
    id as product_id,
    
    -- Product identification
    sku as product_sku,
    name as product_name,
    barcode,
    short_description as product_description,
    
    -- Categorization
    category_id,
    brand,
    type as product_type,
    tags as product_tags,
    
    -- Pricing (using tier 1 as default retail price)
    COALESCE(price_tier_1, 0) as retail_price,
    COALESCE(price_tier_2, 0) as wholesale_price,
    COALESCE(price_tier_3, 0) as tier_3_price,
    
    -- Physical attributes
    uom as unit_of_measure,
    COALESCE(weight, 0) as weight,
    COALESCE(height, 0) as height,
    COALESCE(carton_quantity, 0) as carton_quantity,
    COALESCE(carton_inner_quantity, 0) as carton_inner_quantity,
    COALESCE(carton_length, 0) as carton_length,
    
    -- Inventory
    stock_locator,
    default_location,
    costing_method,
    
    -- Tax and accounting
    sale_tax_rule,
    purchase_tax_rule,
    revenue_account,
    expense_account,
    inventory_account,
    
    -- Additional attributes
    suppliers,
    attribute_set,
    status as product_status,
    bom_type,
    auto_assembly,
    
    -- Custom attributes
    additional_attribute_1,
    additional_attribute_2,
    additional_attribute_4,
    
    -- Metadata
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at
    
FROM [{{ var('fivetran_database') }}].cin7core.product
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)