// Power Query M Script for Power BI
// Copy this entire script and paste into Power BI Advanced Editor
// Home → Transform Data → Advanced Editor → Replace all content

let
    // Connection parameters
    ServerName = "oldschoolbi.database.windows.net",
    DatabaseName = "OldSchool-Dev-DB",
    
    // Load Sales Fact Table
    SalesFactSource = Sql.Database(ServerName, DatabaseName, 
        [Query="SELECT 
            sale_id,
            customer_id,
            order_number,
            order_date,
            location,
            sale_type,
            sale_status,
            order_status,
            total_amount,
            tax_amount,
            subtotal_amount,
            currency_code,
            sales_representative,
            source_channel,
            order_year,
            order_month,
            order_quarter
        FROM dbt_jtucker.powerbi_sales_fact"]),
    
    SalesFact = Table.TransformColumnTypes(SalesFactSource,{
        {"sale_id", type text},
        {"customer_id", type text},
        {"order_number", type text},
        {"order_date", type date},
        {"location", type text},
        {"sale_type", type text},
        {"sale_status", type text},
        {"order_status", type text},
        {"total_amount", Currency.Type},
        {"tax_amount", Currency.Type},
        {"subtotal_amount", Currency.Type},
        {"currency_code", type text},
        {"sales_representative", type text},
        {"source_channel", type text},
        {"order_year", Int64.Type},
        {"order_month", Int64.Type},
        {"order_quarter", Int64.Type}
    }),
    
    // Load Customer Dimension
    CustomerDimSource = Sql.Database(ServerName, DatabaseName, 
        [Query="SELECT 
            customer_id,
            customer_name,
            customer_status,
            default_location,
            credit_limit,
            customer_discount,
            price_tier,
            payment_term,
            currency,
            on_credit_hold,
            tax_rule,
            sales_representative
        FROM dbt_jtucker.powerbi_customer_dim"]),
    
    CustomerDim = Table.TransformColumnTypes(CustomerDimSource,{
        {"customer_id", type text},
        {"customer_name", type text},
        {"customer_status", type text},
        {"default_location", type text},
        {"credit_limit", Currency.Type},
        {"customer_discount", Percentage.Type},
        {"price_tier", type text},
        {"payment_term", type text},
        {"currency", type text},
        {"on_credit_hold", type logical},
        {"tax_rule", type text},
        {"sales_representative", type text}
    }),
    
    // Load Product Dimension
    ProductDimSource = Sql.Database(ServerName, DatabaseName, 
        [Query="SELECT 
            product_id,
            product_sku,
            product_name,
            barcode,
            product_description,
            category_id,
            brand,
            product_type,
            retail_price,
            wholesale_price,
            unit_of_measure,
            weight,
            stock_locator,
            default_location,
            product_status
        FROM dbt_jtucker.powerbi_product_dim"]),
    
    ProductDim = Table.TransformColumnTypes(ProductDimSource,{
        {"product_id", type text},
        {"product_sku", type text},
        {"product_name", type text},
        {"barcode", type text},
        {"product_description", type text},
        {"category_id", type text},
        {"brand", type text},
        {"product_type", type text},
        {"retail_price", Currency.Type},
        {"wholesale_price", Currency.Type},
        {"unit_of_measure", type text},
        {"weight", type number},
        {"stock_locator", type text},
        {"default_location", type text},
        {"product_status", type text}
    }),
    
    // Create a simple output table listing all queries
    Output = Table.FromRecords({
        [TableName = "SalesFact", RowCount = Table.RowCount(SalesFact), Status = "Loaded"],
        [TableName = "CustomerDim", RowCount = Table.RowCount(CustomerDim), Status = "Loaded"],
        [TableName = "ProductDim", RowCount = Table.RowCount(ProductDim), Status = "Loaded"]
    })
in
    Output