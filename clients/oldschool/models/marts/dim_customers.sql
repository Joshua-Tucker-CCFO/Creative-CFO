{{
    config(
        materialized='table',
            {'columns': ['email']},
            {'columns': ['source_system']}
        ]
    )
}}

-- Customer dimension table with enriched attributes
with customer_sales as (
    select
        concat(source_system, '_', customer_id) as unique_customer_key,
        count(distinct transaction_id) as total_orders,
        sum(total_amount) as total_revenue,
        min(transaction_date) as first_order_date,
        max(transaction_date) as last_order_date,
        avg(total_amount) as avg_order_value
    from {{ ref('int_sales_transactions') }}
    where customer_id is not null
    group by source_system, customer_id
)

select
    c.unique_customer_key,
    c.source_system,
    c.customer_id as source_customer_id,
    c.customer_name,
    c.email,
    c.phone,
    
    -- Customer metrics from source
    coalesce(c.lifetime_value, s.total_revenue, 0) as lifetime_value,
    coalesce(c.total_orders, s.total_orders, 0) as total_orders,
    
    -- Additional calculated metrics
    s.first_order_date,
    s.last_order_date,
    s.avg_order_value,
    
    -- Customer segmentation
    case
        when coalesce(c.lifetime_value, s.total_revenue, 0) > 10000 then 'VIP'
        when coalesce(c.lifetime_value, s.total_revenue, 0) > 5000 then 'High Value'
        when coalesce(c.lifetime_value, s.total_revenue, 0) > 1000 then 'Medium Value'
        when coalesce(c.lifetime_value, s.total_revenue, 0) > 0 then 'Low Value'
        else 'No Purchase'
    end as customer_segment,
    
    case
        when s.last_order_date >= dateadd(day, -30, getdate()) then 'Active'
        when s.last_order_date >= dateadd(day, -90, getdate()) then 'At Risk'
        when s.last_order_date >= dateadd(day, -180, getdate()) then 'Dormant'
        when s.last_order_date is not null then 'Churned'
        else 'Never Purchased'
    end as customer_status,
    
    -- Days since last order
    case 
        when s.last_order_date is not null 
        then datediff(day, s.last_order_date, getdate())
        else null
    end as days_since_last_order,
    
    -- Customer lifetime in days
    case 
        when s.first_order_date is not null 
        then datediff(day, s.first_order_date, coalesce(s.last_order_date, getdate()))
        else null
    end as customer_lifetime_days,
    
    -- Data quality flags
    case when c.email is null then 0 else 1 end as has_email,
    case when c.phone is null then 0 else 1 end as has_phone,
    
    -- Metadata
    c.last_synced_at,
    getdate() as dimension_updated_at

from {{ ref('int_unified_customers') }} c
left join customer_sales s 
    on c.unique_customer_key = s.unique_customer_key