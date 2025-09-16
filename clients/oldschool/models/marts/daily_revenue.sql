{{
    config(
        materialized='table',
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
),

daily_metrics as (
    select
        cast(order_date as date) as order_date,
        count(distinct order_id) as total_orders,
        count(distinct customer_id) as unique_customers,
        sum(total_amount) as daily_revenue,
        avg(total_amount) as avg_order_value,
        max(total_amount) as max_order_value,
        min(total_amount) as min_order_value
    from orders
    where record_status = 'active'
    group by cast(order_date as date)
),

with_running_totals as (
    select
        *,
        sum(daily_revenue) over (order by order_date rows between unbounded preceding and current row) as cumulative_revenue,
        avg(daily_revenue) over (order by order_date rows between 6 preceding and current row) as rolling_7day_avg_revenue
    from daily_metrics
)

select * from with_running_totals