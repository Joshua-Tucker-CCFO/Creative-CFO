{% macro inspect_tables() %}
  {% set tables = ['sale', 'customer', 'product'] %}
  
  {% for table in tables %}
    {% set query %}
      SELECT 
        COLUMN_NAME,
        DATA_TYPE
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'cin7core'
        AND TABLE_NAME = '{{ table }}'
      ORDER BY ORDINAL_POSITION
    {% endset %}

    {% set results = run_query(query) %}
    
    {% if execute %}
      {{ log("", info=True) }}
      {{ log("=== COLUMNS IN cin7core." ~ table ~ " ===", info=True) }}
      {% for row in results %}
        {{ log("  " ~ row[0] ~ " (" ~ row[1] ~ ")", info=True) }}
      {% endfor %}
    {% endif %}
  {% endfor %}
{% endmacro %}