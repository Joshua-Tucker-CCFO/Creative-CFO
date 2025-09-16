-- Extract layer stored procedure for Cin7 customers
-- Run this in Azure Synapse to populate extract.cin7_customers

CREATE OR ALTER PROCEDURE sp_extract_cin7_customers
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear existing data
    TRUNCATE TABLE extract.cin7_customers;

    -- Extract and load with basic quality checks
    INSERT INTO extract.cin7_customers (
        customer_id,
        name,
        email,
        phone,
        billing_address,
        shipping_address,
        credit_limit,
        _fivetran_synced,
        _fivetran_deleted,
        extracted_at
    )
    SELECT 
        customer_id,
        name,
        email,
        phone,
        billing_address,
        shipping_address,
        credit_limit,
        _fivetran_synced,
        _fivetran_deleted,
        GETDATE() as extracted_at
    FROM cin7core.customers
    WHERE customer_id IS NOT NULL  -- Basic quality check
    AND name IS NOT NULL;

    -- Log extraction stats
    DECLARE @row_count INT = @@ROWCOUNT;
    PRINT CONCAT('Extracted ', @row_count, ' Cin7 customers at ', GETDATE());
END