{% macro create_clean_tables() %}
  
  -- Create Sales Fact Table
  {% set create_sales %}
    -- Drop existing table if exists
    IF OBJECT_ID('dbo.sales_fact', 'U') IS NOT NULL
      DROP TABLE dbo.sales_fact;
    
    -- Create clean sales fact table
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
      DATEPART(quarter, order_date) as order_quarter,
      DATENAME(month, order_date) as order_month_name,
      DATEPART(week, order_date) as order_week,
      CURRENT_TIMESTAMP as last_refreshed
    INTO dbo.sales_fact
    FROM [OldSchool-Dev-DB].cin7core.sale
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL)
      AND order_date IS NOT NULL;
  {% endset %}
  
  {% set result1 = run_query(create_sales) %}
  
  -- Create Customer Dimension
  {% set create_customer %}
    IF OBJECT_ID('dbo.customer_dim', 'U') IS NOT NULL
      DROP TABLE dbo.customer_dim;
    
    SELECT 
      id as customer_id,
      name as customer_name,
      status as customer_status,
      location as default_location,
      CAST(COALESCE(credit_limit, 0) AS DECIMAL(18,2)) as credit_limit,
      CAST(COALESCE(discount, 0) AS DECIMAL(5,2)) as customer_discount,
      price_tier,
      payment_term,
      currency,
      is_on_credit_hold as on_credit_hold,
      tax_rule,
      sales_representative,
      CURRENT_TIMESTAMP as last_refreshed
    INTO dbo.customer_dim
    FROM [OldSchool-Dev-DB].cin7core.customer
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL);
  {% endset %}
  
  {% set result2 = run_query(create_customer) %}
  
  -- Create Product Dimension
  {% set create_product %}
    IF OBJECT_ID('dbo.product_dim', 'U') IS NOT NULL
      DROP TABLE dbo.product_dim;
    
    SELECT 
      id as product_id,
      sku as product_sku,
      name as product_name,
      barcode,
      short_description as product_description,
      category_id,
      brand,
      type as product_type,
      CAST(COALESCE(price_tier_1, 0) AS DECIMAL(18,2)) as retail_price,
      CAST(COALESCE(price_tier_2, 0) AS DECIMAL(18,2)) as wholesale_price,
      uom as unit_of_measure,
      CAST(COALESCE(weight, 0) AS DECIMAL(10,2)) as weight,
      stock_locator,
      default_location,
      status as product_status,
      CURRENT_TIMESTAMP as last_refreshed
    INTO dbo.product_dim
    FROM [OldSchool-Dev-DB].cin7core.product
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL);
  {% endset %}
  
  {% set result3 = run_query(create_product) %}
  
  {% if execute %}
    {{ log("=== TABLES CREATED SUCCESSFULLY ===", info=True) }}
    
    {% set count_query %}
      SELECT 
        'sales_fact' as table_name,
        COUNT(*) as row_count
      FROM dbo.sales_fact
      UNION ALL
      SELECT 
        'customer_dim' as table_name,
        COUNT(*) as row_count
      FROM dbo.customer_dim
      UNION ALL
      SELECT 
        'product_dim' as table_name,
        COUNT(*) as row_count
      FROM dbo.product_dim
    {% endset %}
    
    {% set count_result = run_query(count_query) %}
    {% for row in count_result %}
      {{ log("Table: " ~ row[0] ~ " - Rows: " ~ row[1], info=True) }}
    {% endfor %}
    
    {{ log("", info=True) }}
    {{ log("✅ Tables are ready in dbo schema:", info=True) }}
    {{ log("  • dbo.sales_fact", info=True) }}
    {{ log("  • dbo.customer_dim", info=True) }}
    {{ log("  • dbo.product_dim", info=True) }}
  {% endif %}
  
{% endmacro %}