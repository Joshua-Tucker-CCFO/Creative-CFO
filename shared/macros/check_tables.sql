{% macro check_tables() %}
  {% set query %}
    SELECT 
      TABLE_SCHEMA,
      TABLE_NAME,
      TABLE_TYPE
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'dbt_jtucker')
    ORDER BY TABLE_SCHEMA, TABLE_NAME
  {% endset %}

  {% set results = run_query(query) %}
  
  {% if execute %}
    {% for row in results %}
      {{ log("Schema: " ~ row[0] ~ ", Table: " ~ row[1] ~ ", Type: " ~ row[2], info=True) }}
    {% endfor %}
  {% endif %}
{% endmacro %}