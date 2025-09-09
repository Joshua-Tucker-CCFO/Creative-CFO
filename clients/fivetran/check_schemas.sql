-- Check what schemas exist in the database
SELECT 
    schema_name
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE schema_name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
ORDER BY schema_name;