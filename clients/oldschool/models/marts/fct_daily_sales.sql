{{
    config(
        materialized='table',
    )
}}

-- Daily sales fact table for Power BI reporting
with daily_sales as (
    select
        transaction_date as sale_date,
        source_system,
        currency_code,
        transaction_year as sale_year,
        transaction_quarter as sale_quarter,
        transaction_month as sale_month,
        transaction_week as sale_week,
        year_month,
        
        -- Metrics
        count(distinct transaction_id) as total_transactions,
        count(distinct customer_id) as unique_customers,
        
        -- Revenue metrics
        sum(subtotal_amount) as gross_revenue,
        sum(tax_amount) as total_tax,
        sum(shipping_amount) as total_shipping,
        sum(total_amount) as net_revenue,
        
        -- Average metrics
        avg(total_amount) as avg_transaction_value,
        
        -- Min/Max for data quality checks
        min(total_amount) as min_transaction_value,
        max(total_amount) as max_transaction_value,
        
        -- Status breakdown
        sum(case when status in ('PAID', 'paid', 'AUTHORISED') then 1 else 0 end) as paid_transactions,
        sum(case when status in ('pending', 'SUBMITTED', 'DRAFT') then 1 else 0 end) as pending_transactions,
        
        max(last_synced_at) as last_updated_at
        
    from {{ ref('int_sales_transactions') }}
    group by 
        transaction_date,
        source_system,
        currency_code,
        transaction_year,
        transaction_quarter,
        transaction_month,
        transaction_week,
        year_month
)

select
    sale_date,
    source_system,
    currency_code,
    sale_year,
    sale_quarter,
    sale_month,
    sale_week,
    year_month,
    
    -- Day name for reporting
    datename(weekday, sale_date) as day_of_week,
    datepart(day, sale_date) as day_of_month,
    
    -- Fiscal periods (assuming fiscal year starts in January)
    case 
        when sale_month <= 6 then concat('H1-', sale_year)
        else concat('H2-', sale_year)
    end as fiscal_half,
    
    -- Metrics
    total_transactions,
    unique_customers,
    gross_revenue,
    total_tax,
    total_shipping,
    net_revenue,
    avg_transaction_value,
    min_transaction_value,
    max_transaction_value,
    paid_transactions,
    pending_transactions,
    
    -- Calculated metrics
    case 
        when total_transactions > 0 
        then cast(paid_transactions as decimal(10,2)) / cast(total_transactions as decimal(10,2)) * 100
        else 0 
    end as payment_completion_rate,
    
    case 
        when gross_revenue > 0 
        then cast(total_tax as decimal(18,2)) / cast(gross_revenue as decimal(18,2)) * 100
        else 0 
    end as effective_tax_rate,
    
    -- Data freshness
    last_updated_at,
    getdate() as report_generated_at
    
from daily_sales