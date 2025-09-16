{{ config(
    materialized='view',
    schema='staging'
) }}

-- Simple Cin7 Core staging model to test connection
-- This will work with the cin7core schema (no underscore)

SELECT 
    *,
    CURRENT_TIMESTAMP as processed_at
FROM {{ var('fivetran_database') }}.cin7core.sale
WHERE 1=1
    {% if var('limit_rows', false) %}
    AND TOP 100
    {% endif %}