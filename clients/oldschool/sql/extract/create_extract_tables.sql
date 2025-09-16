-- Create extract layer schema and tables
-- Run this in Azure Synapse first

-- Create extract schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'extract')
BEGIN
    EXEC('CREATE SCHEMA extract');
END
GO

-- Cin7 Core extract tables
CREATE TABLE extract.cin7_customers (
    customer_id VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    billing_address VARCHAR(1000),
    shipping_address VARCHAR(1000),
    credit_limit DECIMAL(18,2),
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

CREATE TABLE extract.cin7_products (
    product_id VARCHAR(50) NOT NULL,
    sku VARCHAR(100),
    name VARCHAR(255),
    description VARCHAR(2000),
    category VARCHAR(100),
    cost_price DECIMAL(18,2),
    retail_price DECIMAL(18,2),
    stock_on_hand INT,
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

CREATE TABLE extract.cin7_sales_orders (
    sales_order_id VARCHAR(50) NOT NULL,
    order_number VARCHAR(100),
    customer_id VARCHAR(50),
    order_date DATE,
    status VARCHAR(50),
    total_amount DECIMAL(18,2),
    subtotal DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    currency VARCHAR(10),
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

-- Xero extract tables
CREATE TABLE extract.xero_invoices (
    invoice_id VARCHAR(50) NOT NULL,
    invoice_number VARCHAR(100),
    contact_id VARCHAR(50),
    type VARCHAR(50),
    status VARCHAR(50),
    date DATE,
    due_date DATE,
    total DECIMAL(18,2),
    sub_total DECIMAL(18,2),
    total_tax DECIMAL(18,2),
    currency_code VARCHAR(10),
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

CREATE TABLE extract.xero_contacts (
    contact_id VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    email_address VARCHAR(255),
    contact_status VARCHAR(50),
    is_customer BIT,
    is_supplier BIT,
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

-- Shopify extract tables
CREATE TABLE extract.shopify_orders (
    id BIGINT NOT NULL,
    order_number VARCHAR(100),
    customer_id BIGINT,
    created_at DATETIME2,
    processed_at DATETIME2,
    financial_status VARCHAR(50),
    fulfillment_status VARCHAR(50),
    total_price DECIMAL(18,2),
    subtotal_price DECIMAL(18,2),
    total_tax DECIMAL(18,2),
    total_shipping_price_set DECIMAL(18,2),
    currency VARCHAR(10),
    cancelled_at DATETIME2,
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);

CREATE TABLE extract.shopify_customers (
    id BIGINT NOT NULL,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    created_at DATETIME2,
    updated_at DATETIME2,
    orders_count INT,
    total_spent DECIMAL(18,2),
    state VARCHAR(50),
    _fivetran_synced DATETIME2,
    _fivetran_deleted BIT,
    extracted_at DATETIME2 NOT NULL
);