{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple sales fact table for Power BI
-- Works with cin7core.sale table directly

SELECT
    id as sale_id,
    customer_id,
    status as sale_status,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at

FROM [{{ var('fivetran_database') }}].cin7core.sale
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)