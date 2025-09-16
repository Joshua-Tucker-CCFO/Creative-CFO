{{
    config(
        materialized='view'
    )
}}

-- Create a unified customer view across all systems
with xero_customers as (
    select
        'Xero' as source_system,
        contact_id as customer_id,
        contact_name as customer_name,
        email,
        null as phone,
        null as lifetime_value,
        null as total_orders,
        last_synced_at
    from {{ ref('stg_xero_contacts') }}
    where is_customer = 1
),

cin7_customers as (
    select
        'Cin7' as source_system,
        customer_id,
        customer_name,
        email,
        phone,
        null as lifetime_value,
        null as total_orders,
        last_synced_at
    from {{ ref('stg_cin7_customers') }}
),

shopify_customers as (
    select
        'Shopify' as source_system,
        cast(customer_id as varchar(50)) as customer_id,
        full_name as customer_name,
        email,
        phone,
        lifetime_value,
        total_orders,
        last_synced_at
    from {{ ref('stg_shopify_customers') }}
),

combined_customers as (
    select * from xero_customers
    union all
    select * from cin7_customers
    union all
    select * from shopify_customers
),

-- Deduplicate customers across systems based on email
deduped_customers as (
    select
        source_system,
        customer_id,
        customer_name,
        email,
        phone,
        lifetime_value,
        total_orders,
        last_synced_at,
        row_number() over (
            partition by lower(email) 
            order by 
                case source_system 
                    when 'Shopify' then 1  -- Prioritize Shopify as it has more metrics
                    when 'Cin7' then 2
                    when 'Xero' then 3
                end
        ) as rn
    from combined_customers
    where email is not null
)

select
    source_system,
    customer_id,
    customer_name,
    email,
    phone,
    lifetime_value,
    total_orders,
    last_synced_at,
    concat(source_system, '_', customer_id) as unique_customer_key
from deduped_customers
where rn = 1

union all

-- Include customers without email addresses
select
    source_system,
    customer_id,
    customer_name,
    email,
    phone,
    lifetime_value,
    total_orders,
    last_synced_at,
    concat(source_system, '_', customer_id) as unique_customer_key
from combined_customers
where email is null