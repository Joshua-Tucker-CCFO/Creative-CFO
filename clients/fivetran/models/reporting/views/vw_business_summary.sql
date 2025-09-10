{{
    config(
        materialized='view',
        schema='reporting'
    )
}}

-- Executive business summary for Power BI main dashboard
with sales_metrics as (
    select
        count(*) as total_orders,
        sum(total_amount) as total_revenue,
        avg(total_amount) as avg_order_value,
        count(distinct customer_id) as unique_customers,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date
    from {{ ref('int_sales_transactions') }}
    where order_date >= current_date - 365  -- Last 12 months
    and is_cancelled = 0
),

customer_metrics as (
    select
        count(*) as total_customers,
        count(case when coalesce(total_orders, 0) > 0 then 1 end) as active_customers,
        sum(coalesce(lifetime_value, 0)) as total_customer_value
    from {{ ref('int_unified_customers') }}
),

inventory_metrics as (
    select
        count(*) as total_products,
        count(case when coalesce(stock_on_hand, 0) > 0 then 1 end) as in_stock_products,
        count(case when coalesce(stock_on_hand, 0) = 0 then 1 end) as out_of_stock_products,
        sum(coalesce(stock_on_hand, 0) * cost_price) as total_inventory_value
    from {{ ref('int_unified_products') }}
)

select
    -- Sales KPIs
    s.total_orders,
    s.total_revenue,
    s.avg_order_value,
    s.unique_customers,
    
    -- Customer KPIs
    c.total_customers,
    c.active_customers,
    c.total_customer_value,
    
    -- Inventory KPIs  
    i.total_products,
    i.in_stock_products,
    i.out_of_stock_products,
    i.total_inventory_value,
    
    -- Calculated ratios for Power BI
    case 
        when c.total_customers > 0 
        then round((c.active_customers::decimal / c.total_customers::decimal) * 100, 2)
        else 0 
    end as customer_activation_rate,
    
    case 
        when i.total_products > 0 
        then round((i.out_of_stock_products::decimal / i.total_products::decimal) * 100, 2)
        else 0 
    end as out_of_stock_rate,
    
    case 
        when s.unique_customers > 0 
        then round(s.total_revenue / s.unique_customers, 2)
        else 0 
    end as revenue_per_customer,
    
    -- Time period
    s.first_order_date,
    s.last_order_date,
    current_date - 365 as reporting_period_start,
    current_date as reporting_period_end,
    
    -- Data freshness
    current_timestamp as view_refreshed_at

from sales_metrics s
cross join customer_metrics c  
cross join inventory_metrics i