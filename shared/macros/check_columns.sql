{% macro check_columns() %}
  {% set query %}
    SELECT TOP 5
      COLUMN_NAME,
      DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'cin7core'
      AND TABLE_NAME = 'sale'
    ORDER BY ORDINAL_POSITION
  {% endset %}

  {% set results = run_query(query) %}
  
  {% if execute %}
    {{ log("=== COLUMNS IN cin7core.sale ===", info=True) }}
    {% for row in results %}
      {{ log(row[0] ~ " (" ~ row[1] ~ ")", info=True) }}
    {% endfor %}
  {% endif %}
{% endmacro %}