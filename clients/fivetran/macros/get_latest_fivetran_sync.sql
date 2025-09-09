{% macro get_latest_fivetran_sync(table_name) %}
    select max(_fivetran_synced) as last_sync_time
    from {{ source('fivetran_source', table_name) }}
{% endmacro %}