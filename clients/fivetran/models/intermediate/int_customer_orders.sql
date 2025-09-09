{{
    config(
        materialized='view'
    )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        c.customer_id,
        c.customer_name,
        c.email,
        c.created_at as customer_created_at,
        count(distinct o.order_id) as total_orders,
        sum(o.total_amount) as lifetime_value,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date,
        datediff(day, min(o.order_date), max(o.order_date)) as customer_lifespan_days
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by 
        c.customer_id,
        c.customer_name,
        c.email,
        c.created_at
)

select * from customer_orders