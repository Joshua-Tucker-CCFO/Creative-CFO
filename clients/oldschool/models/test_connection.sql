-- Test model to verify database connection and available tables
{{ config(
    materialized='view',
    schema='staging'
) }}

-- Just select from cin7core.customer to test
SELECT TOP 10
    id,
    name,
    status
FROM [{{ var('fivetran_database') }}].cin7core.customer