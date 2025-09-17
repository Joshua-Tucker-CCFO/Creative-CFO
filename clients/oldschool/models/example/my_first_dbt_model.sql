/*
    Welcome to your first dbt model!
    Azure SQL Database compatible version

    Fixes INDEX syntax error by explicitly configuring for Azure SQL Database
*/

{{ config(
    materialized='table',
    post_hook=[],
    pre_hook=[]
) }}

with source_data as (

    select 1 as id
    union all
    select null as id

)

select *
from source_data

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null