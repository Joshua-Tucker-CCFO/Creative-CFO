{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple product dimension for Power BI
-- Works with cin7core.product table directly

SELECT
    id as product_id,
    name as product_name,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at

FROM [{{ var('fivetran_database') }}].cin7core.product
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)