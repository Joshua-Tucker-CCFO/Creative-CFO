{{
    config(
        materialized='view'
    )
}}

-- Combine sales data from all three sources into a unified view
with xero_sales as (
    select
        'Xero' as source_system,
        inv.invoice_id as transaction_id,
        inv.invoice_number as transaction_number,
        inv.contact_id as customer_id,
        inv.invoice_date as transaction_date,
        inv.invoice_type as transaction_type,
        inv.invoice_status as status,
        inv.currency_code,
        inv.subtotal_amount,
        inv.tax_amount,
        inv.total_amount,
        null as shipping_amount,
        inv.last_synced_at
    from {{ ref('stg_xero_invoices') }} inv
    where inv.invoice_type = 'ACCREC'  -- Only sales invoices
),

cin7_sales as (
    select
        'Cin7' as source_system,
        so.sales_order_id as transaction_id,
        so.order_number as transaction_number,
        so.customer_id,
        so.order_date as transaction_date,
        'SALES_ORDER' as transaction_type,
        so.order_status as status,
        so.currency_code,
        so.subtotal_amount,
        so.tax_amount,
        so.total_amount,
        null as shipping_amount,
        so.last_synced_at
    from {{ ref('stg_cin7_sales_orders') }} so
),

shopify_sales as (
    select
        'Shopify' as source_system,
        cast(ord.order_id as varchar(50)) as transaction_id,
        cast(ord.order_number as varchar(50)) as transaction_number,
        cast(ord.customer_id as varchar(50)) as customer_id,
        cast(ord.created_at as date) as transaction_date,
        'ECOMMERCE_ORDER' as transaction_type,
        ord.financial_status as status,
        ord.currency_code,
        ord.subtotal_amount,
        ord.tax_amount,
        ord.total_amount,
        ord.shipping_amount,
        ord.last_synced_at
    from {{ ref('stg_shopify_orders') }} ord
    where ord.is_cancelled = 0
),

combined_sales as (
    select * from xero_sales
    union all
    select * from cin7_sales
    union all
    select * from shopify_sales
)

select 
    source_system,
    transaction_id,
    transaction_number,
    customer_id,
    transaction_date,
    transaction_type,
    status,
    currency_code,
    subtotal_amount,
    tax_amount,
    coalesce(shipping_amount, 0) as shipping_amount,
    total_amount,
    last_synced_at,
    -- Calculated fields
    datepart(year, transaction_date) as transaction_year,
    datepart(quarter, transaction_date) as transaction_quarter,
    datepart(month, transaction_date) as transaction_month,
    datepart(week, transaction_date) as transaction_week,
    format(transaction_date, 'yyyy-MM') as year_month
from combined_sales