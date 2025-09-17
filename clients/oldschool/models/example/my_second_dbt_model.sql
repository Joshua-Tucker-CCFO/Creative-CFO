-- Use the `ref` function to select from other models
-- Azure SQL Database compatible version

{{ config(
    materialized='view',
    post_hook=[],
    pre_hook=[]
) }}

select *
from {{ ref('my_first_dbt_model') }}
where id = 1