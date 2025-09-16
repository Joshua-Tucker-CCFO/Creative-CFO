{{ config(
    materialized='table',
    schema='marts'
) }}

-- Simple customer dimension for Power BI
-- Works with cin7core.customer table directly

SELECT
    id as customer_id,
    name as customer_name,
    status as customer_status,
    _fivetran_synced,
    CURRENT_TIMESTAMP as dbt_processed_at

FROM [{{ var('fivetran_database') }}].cin7core.customer
WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
