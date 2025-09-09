{% macro list_all_tables() %}
  {% set query %}
    SELECT DISTINCT
      TABLE_SCHEMA as schema_name,
      COUNT(*) as table_count
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'db_owner', 'db_accessadmin', 'db_securityadmin', 'db_ddladmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
    GROUP BY TABLE_SCHEMA
    ORDER BY TABLE_SCHEMA
  {% endset %}

  {% set results = run_query(query) %}
  
  {% if execute %}
    {{ log("=== SCHEMAS FOUND ===", info=True) }}
    {% for row in results %}
      {{ log("Schema: " ~ row[0] ~ " (" ~ row[1] ~ " tables)", info=True) }}
    {% endfor %}
    
    {% set query2 %}
      SELECT TOP 100
        TABLE_SCHEMA,
        TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA IN ('cin7core', 'shopify_au', 'xero_accounting_au', 'dbt_jtucker')
      ORDER BY TABLE_SCHEMA, TABLE_NAME
    {% endset %}
    
    {% set results2 = run_query(query2) %}
    
    {{ log("=== KEY TABLES ===", info=True) }}
    {% for row in results2 %}
      {{ log(row[0] ~ "." ~ row[1], info=True) }}
    {% endfor %}
  {% endif %}
{% endmacro %}