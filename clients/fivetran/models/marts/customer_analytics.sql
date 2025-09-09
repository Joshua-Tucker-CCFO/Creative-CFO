{{
    config(
        materialized='table'
    )
}}

with customer_orders as (
    select * from {{ ref('int_customer_orders') }}
),

customer_segments as (
    select
        customer_id,
        customer_name,
        email,
        customer_created_at,
        total_orders,
        lifetime_value,
        first_order_date,
        last_order_date,
        customer_lifespan_days,
        case 
            when lifetime_value >= 10000 then 'VIP'
            when lifetime_value >= 5000 then 'High Value'
            when lifetime_value >= 1000 then 'Medium Value'
            else 'Low Value'
        end as customer_segment,
        case
            when datediff(day, last_order_date, getdate()) <= 30 then 'Active'
            when datediff(day, last_order_date, getdate()) <= 90 then 'At Risk'
            when datediff(day, last_order_date, getdate()) <= 180 then 'Dormant'
            else 'Lost'
        end as customer_status,
        case
            when total_orders = 0 then 0
            else round(lifetime_value / total_orders, 2)
        end as avg_order_value
    from customer_orders
)

select * from customer_segments