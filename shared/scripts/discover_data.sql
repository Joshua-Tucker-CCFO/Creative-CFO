-- Discover all available schemas and tables
-- Run this with: dbt run-operation run_query --args "{sql: $(cat discover_data.sql)}"

WITH schema_summary AS (
    SELECT 
        TABLE_SCHEMA,
        COUNT(*) as table_count,
        STRING_AGG(TABLE_NAME, ', ') WITHIN GROUP (ORDER BY TABLE_NAME) as sample_tables
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'db_owner', 'db_accessadmin', 'db_securityadmin', 'db_ddladmin')
    GROUP BY TABLE_SCHEMA
)
SELECT 
    TABLE_SCHEMA as schema_name,
    table_count,
    LEFT(sample_tables, 200) as first_tables
FROM schema_summary
ORDER BY 
    CASE 
        WHEN TABLE_SCHEMA LIKE '%cin7%' THEN 1
        WHEN TABLE_SCHEMA LIKE '%shopify%' THEN 2
        WHEN TABLE_SCHEMA LIKE '%xero%' THEN 3
        ELSE 4
    END,
    TABLE_SCHEMA;