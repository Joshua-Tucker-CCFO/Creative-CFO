-- Packleder Database Discovery Script
-- Run these queries to understand the current data structure

-- ============================================
-- 1. CHECK ALL SCHEMAS
-- ============================================
SELECT 
    TABLE_SCHEMA as schema_name,
    COUNT(*) as table_count,
    MIN(TABLE_NAME) as sample_table
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA NOT IN ('dbo', 'sys', 'INFORMATION_SCHEMA', 'guest')
GROUP BY TABLE_SCHEMA
ORDER BY table_count DESC;

-- ============================================
-- 2. FIND CIN7 DATA
-- ============================================
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE '%cin7%'
   OR TABLE_NAME LIKE '%sale%'
   OR TABLE_NAME LIKE '%order%'
   OR TABLE_NAME LIKE '%customer%'
   OR TABLE_NAME LIKE '%product%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 3. FIND SHOPIFY DATA
-- ============================================
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE '%shopify%'
   OR TABLE_NAME LIKE '%shop%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 4. FIND XERO DATA
-- ============================================
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA LIKE '%xero%'
   OR TABLE_NAME LIKE '%invoice%'
   OR TABLE_NAME LIKE '%contact%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 5. CHECK EXISTING ANALYTICS TABLES
-- ============================================
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    'Table' as object_type
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%fact%'
   OR TABLE_NAME LIKE '%dim%'
   OR TABLE_NAME LIKE '%mart%'
   OR TABLE_NAME LIKE '%analytics%'
UNION ALL
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    'View' as object_type
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE '%fact%'
   OR TABLE_NAME LIKE '%dim%'
   OR TABLE_NAME LIKE '%mart%'
   OR TABLE_NAME LIKE '%analytics%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ============================================
-- 6. COUNT RECORDS IN KEY TABLES (Update table names)
-- ============================================
-- Uncomment and update these based on discovered tables:

/*
-- Sales data volume
SELECT 'sales' as table_type, COUNT(*) as row_count
FROM [schema].[sales_table]
UNION ALL
-- Customer data volume  
SELECT 'customers' as table_type, COUNT(*) as row_count
FROM [schema].[customer_table]
UNION ALL
-- Product data volume
SELECT 'products' as table_type, COUNT(*) as row_count
FROM [schema].[product_table];
*/

-- ============================================
-- 7. SAMPLE DATA STRUCTURE (Update table names)
-- ============================================
-- Uncomment and update based on discovered tables:

/*
-- Sample sales record structure
SELECT TOP 3 * FROM [schema].[sales_table];

-- Sample customer record structure  
SELECT TOP 3 * FROM [schema].[customer_table];

-- Sample product record structure
SELECT TOP 3 * FROM [schema].[product_table];
*/