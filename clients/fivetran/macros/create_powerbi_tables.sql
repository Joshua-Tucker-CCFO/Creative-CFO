{% macro create_powerbi_tables() %}
  
  {% set create_sales_table %}
    -- Drop existing table if exists
    IF OBJECT_ID('dbt_jtucker.powerbi_sales_fact', 'U') IS NOT NULL
      DROP TABLE dbt_jtucker.powerbi_sales_fact;
    
    -- Create sales fact table for Power BI
    SELECT 
      id as sale_id,
      customer_id,
      order_number,
      CAST(order_date AS DATE) as order_date,
      location,
      type as sale_type,
      status as sale_status,
      order_status,
      CAST(COALESCE(order_total, 0) AS DECIMAL(18,2)) as total_amount,
      CAST(COALESCE(order_tax, 0) AS DECIMAL(18,2)) as tax_amount,
      CAST(COALESCE(order_total_before_tax, 0) AS DECIMAL(18,2)) as subtotal_amount,
      base_currency as currency_code,
      sales_representative,
      source_channel,
      YEAR(order_date) as order_year,
      MONTH(order_date) as order_month,
      DATEPART(quarter, order_date) as order_quarter
    INTO dbt_jtucker.powerbi_sales_fact
    FROM [OldSchool-Dev-DB].cin7core.sale
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
      AND order_date IS NOT NULL;
  {% endset %}
  
  {% set result = run_query(create_sales_table) %}
  
  {% if execute %}
    {{ log("Created powerbi_sales_fact table", info=True) }}
    
    {% set count_query %}
      SELECT COUNT(*) as row_count FROM dbt_jtucker.powerbi_sales_fact
    {% endset %}
    
    {% set count_result = run_query(count_query) %}
    {% for row in count_result %}
      {{ log("Rows in powerbi_sales_fact: " ~ row[0], info=True) }}
    {% endfor %}
  {% endif %}
  
{% endmacro %}