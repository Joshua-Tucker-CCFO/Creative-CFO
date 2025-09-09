-- ============================================
-- DATA RELATIONSHIP EXPLORATION QUERIES
-- Run these to understand actual data relationships
-- ============================================

-- ============================================
-- 1. CIN7 CORE TABLE INVENTORY
-- ============================================

-- Get all Cin7 tables with row counts
SELECT 
    TABLE_NAME,
    CASE 
        WHEN TABLE_NAME LIKE '%sale%' THEN '1_Sales'
        WHEN TABLE_NAME LIKE '%customer%' THEN '2_Customer'
        WHEN TABLE_NAME LIKE '%product%' THEN '3_Product'
        WHEN TABLE_NAME LIKE '%purchase%' THEN '4_Purchase'
        WHEN TABLE_NAME LIKE '%invoice%' THEN '5_Invoice'
        WHEN TABLE_NAME LIKE '%stock%' OR TABLE_NAME LIKE '%inventory%' THEN '6_Inventory'
        ELSE '7_Other'
    END as module
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'cin7core'
ORDER BY module, TABLE_NAME;

-- ============================================
-- 2. SALES RELATIONSHIPS
-- ============================================

-- Sales to Customer relationship
SELECT 
    COUNT(DISTINCT s.id) as total_sales,
    COUNT(DISTINCT s.customer_id) as unique_customers,
    COUNT(CASE WHEN c.id IS NULL THEN 1 END) as orphan_sales,
    MIN(s.order_date) as earliest_sale,
    MAX(s.order_date) as latest_sale
FROM cin7core.sale s
LEFT JOIN cin7core.customer c ON s.customer_id = c.id
WHERE s._fivetran_deleted = 0;

-- Sales order lines analysis
SELECT 
    COUNT(*) as total_lines,
    COUNT(DISTINCT sale_id) as unique_orders,
    COUNT(DISTINCT product_id) as unique_products,
    AVG(quantity) as avg_quantity,
    AVG(unit_price) as avg_price
FROM cin7core.sale_order_line
WHERE _fivetran_deleted = 0;

-- ============================================
-- 3. CUSTOMER DATA QUALITY
-- ============================================

-- Customer completeness check
SELECT 
    COUNT(*) as total_customers,
    COUNT(DISTINCT email) as unique_emails,
    COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as missing_email,
    COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) as missing_phone,
    COUNT(CASE WHEN status = 'Active' THEN 1 END) as active_customers,
    COUNT(CASE WHEN is_on_credit_hold = 1 THEN 1 END) as on_hold
FROM cin7core.customer
WHERE _fivetran_deleted = 0;

-- Customer address coverage
SELECT 
    c.id,
    c.name,
    COUNT(ca.id) as address_count
FROM cin7core.customer c
LEFT JOIN cin7core.customer_address ca ON c.id = ca.customer_id
WHERE c._fivetran_deleted = 0
GROUP BY c.id, c.name
ORDER BY address_count DESC;

-- ============================================
-- 4. PRODUCT RELATIONSHIPS
-- ============================================

-- Product inventory status
SELECT 
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT p.sku) as unique_skus,
    COUNT(DISTINCT p.barcode) as unique_barcodes,
    COUNT(CASE WHEN stk.product_id IS NOT NULL THEN 1 END) as products_with_stock,
    COUNT(CASE WHEN p.status = 'Active' THEN 1 END) as active_products
FROM cin7core.product p
LEFT JOIN cin7core.non_zero_stock_on_hand_product stk ON p.id = stk.product_id
WHERE p._fivetran_deleted = 0;

-- Product movement patterns
SELECT 
    movement_type,
    COUNT(*) as movement_count,
    SUM(ABS(quantity)) as total_quantity,
    COUNT(DISTINCT product_id) as products_affected
FROM cin7core.product_movement
WHERE _fivetran_deleted = 0
GROUP BY movement_type
ORDER BY movement_count DESC;

-- ============================================
-- 5. FINANCIAL RELATIONSHIPS
-- ============================================

-- Purchase to invoice relationship
SELECT 
    COUNT(DISTINCT p.id) as total_purchases,
    COUNT(DISTINCT pi.purchase_id) as invoiced_purchases,
    COUNT(DISTINCT pip.invoice_id) as paid_invoices,
    SUM(p.total_amount) as total_purchase_value,
    SUM(pip.payment_amount) as total_paid
FROM cin7core.purchase p
LEFT JOIN cin7core.purchase_invoice pi ON p.id = pi.purchase_id
LEFT JOIN cin7core.purchase_invoice_payment pip ON pi.invoice_id = pip.invoice_id
WHERE p._fivetran_deleted = 0;

-- ============================================
-- 6. SHOPIFY DATA CHECK (if available)
-- ============================================

-- Check if Shopify schema exists
SELECT 
    TABLE_SCHEMA,
    COUNT(*) as table_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE '%shopify%'
GROUP BY TABLE_SCHEMA;

-- ============================================
-- 7. KEY METRICS SUMMARY
-- ============================================

-- Business metrics overview
SELECT 
    'Sales Metrics' as category,
    (SELECT COUNT(*) FROM cin7core.sale WHERE _fivetran_deleted = 0) as total_records,
    (SELECT SUM(order_total) FROM cin7core.sale WHERE _fivetran_deleted = 0) as total_value,
    (SELECT COUNT(DISTINCT customer_id) FROM cin7core.sale WHERE _fivetran_deleted = 0) as unique_entities
UNION ALL
SELECT 
    'Customer Base' as category,
    (SELECT COUNT(*) FROM cin7core.customer WHERE _fivetran_deleted = 0) as total_records,
    (SELECT SUM(credit_limit) FROM cin7core.customer WHERE _fivetran_deleted = 0) as total_value,
    (SELECT COUNT(DISTINCT sales_representative) FROM cin7core.customer WHERE _fivetran_deleted = 0) as unique_entities
UNION ALL
SELECT 
    'Product Catalog' as category,
    (SELECT COUNT(*) FROM cin7core.product WHERE _fivetran_deleted = 0) as total_records,
    (SELECT SUM(price_tier_1) FROM cin7core.product WHERE _fivetran_deleted = 0) as total_value,
    (SELECT COUNT(DISTINCT brand) FROM cin7core.product WHERE _fivetran_deleted = 0) as unique_entities;

-- ============================================
-- 8. DATA FRESHNESS CHECK
-- ============================================

SELECT 
    'cin7core.sale' as table_name,
    MAX(_fivetran_synced) as last_sync,
    MAX(order_date) as latest_data,
    COUNT(*) as row_count
FROM cin7core.sale
UNION ALL
SELECT 
    'cin7core.customer' as table_name,
    MAX(_fivetran_synced) as last_sync,
    MAX(last_modified_on) as latest_data,
    COUNT(*) as row_count
FROM cin7core.customer
UNION ALL
SELECT 
    'cin7core.product' as table_name,
    MAX(_fivetran_synced) as last_sync,
    NULL as latest_data,
    COUNT(*) as row_count
FROM cin7core.product;