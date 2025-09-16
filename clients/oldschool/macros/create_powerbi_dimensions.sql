{% macro create_powerbi_dimensions() %}
  
  -- Create Customer Dimension
  {% set create_customer_dim %}
    IF OBJECT_ID('dbt_jtucker.powerbi_customer_dim', 'U') IS NOT NULL
      DROP TABLE dbt_jtucker.powerbi_customer_dim;
    
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
      last_modified_on
    INTO dbt_jtucker.powerbi_customer_dim
    FROM [OldSchool-Dev-DB].cin7core.customer
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL);
  {% endset %}
  
  {% set result1 = run_query(create_customer_dim) %}
  
  -- Create Product Dimension
  {% set create_product_dim %}
    IF OBJECT_ID('dbt_jtucker.powerbi_product_dim', 'U') IS NOT NULL
      DROP TABLE dbt_jtucker.powerbi_product_dim;
    
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
      status as product_status
    INTO dbt_jtucker.powerbi_product_dim
    FROM [OldSchool-Dev-DB].cin7core.product
    WHERE (_fivetran_deleted = 0 OR _fivetran_deleted IS NULL);
  {% endset %}
  
  {% set result2 = run_query(create_product_dim) %}
  
  {% if execute %}
    {{ log("Created dimension tables", info=True) }}
    
    {% set count_query %}
      SELECT 
        (SELECT COUNT(*) FROM dbt_jtucker.powerbi_customer_dim) as customers,
        (SELECT COUNT(*) FROM dbt_jtucker.powerbi_product_dim) as products
    {% endset %}
    
    {% set count_result = run_query(count_query) %}
    {% for row in count_result %}
      {{ log("Customers: " ~ row[0] ~ ", Products: " ~ row[1], info=True) }}
    {% endfor %}
  {% endif %}
  
{% endmacro %}