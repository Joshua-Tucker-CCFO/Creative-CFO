{{ config(materialized="view") }}

-- Xero source not available - returning empty result set
SELECT 
    CAST(NULL AS VARCHAR(50)) as placeholder_id,
    CAST(NULL AS TIMESTAMP) as _fivetran_synced
WHERE 1=0
