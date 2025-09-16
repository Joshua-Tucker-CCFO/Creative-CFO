{{
    config(
        materialized='table',
    )
}}

-- Sales representative dimension for sales performance analytics
-- Template structure ready for actual source data integration
-- Includes territory management and performance tracking attributes
with base_sales_reps as (
    -- Extract sales rep info from existing sales transactions
    select distinct
        coalesce(sales_rep_id, 'UNKNOWN') as source_rep_id,
        coalesce(sales_rep_name, 'Unknown Sales Rep') as sales_rep_name,
        coalesce(sales_rep_email, 'unknown@company.com') as sales_rep_email,
        coalesce(sales_rep_code, 'UNKNOWN') as sales_rep_code,
        coalesce(territory, 'Unassigned') as territory,
        null as team_lead,
        null as commission_rate,
        min(order_date) as start_date,
        null as end_date,
        source_system,
        max(last_synced_at) as last_updated
    from {{ ref('int_sales_transactions') }}
    where sales_rep_id is not null
    group by 
        sales_rep_id, sales_rep_name, sales_rep_email, 
        sales_rep_code, territory, source_system
),

-- Manual sales rep entries for common cases
default_sales_reps as (
    select 
        'MANUAL_UNKNOWN' as source_rep_id,
        'Unknown Sales Rep' as sales_rep_name,
        'unknown@company.com' as sales_rep_email,
        'UNKNOWN' as sales_rep_code,
        'Unassigned' as territory,
        null as team_lead,
        null as commission_rate,
        '2020-01-01' as start_date,
        null as end_date,
        'Manual' as source_system,
        getdate() as last_updated
    
    union all
    
    select 
        'MANUAL_ONLINE' as source_rep_id,
        'Online Sales Team' as sales_rep_name,
        'online@company.com' as sales_rep_email,
        'ONLINE' as sales_rep_code,
        'Digital' as territory,
        'Digital Manager' as team_lead,
        null as commission_rate,
        '2020-01-01' as start_date,
        null as end_date,
        'Manual' as source_system,
        getdate() as last_updated
),

unified_sales_reps as (
    select * from base_sales_reps
    union all
    select * from default_sales_reps
),

final_dimensions as (
    select
        -- Primary key generation
        {{ dbt_utils.generate_surrogate_key(['source_rep_id']) }} as sales_rep_key,
        
        -- Sales rep identifiers
        source_rep_id,
        sales_rep_name,
        sales_rep_email,
        sales_rep_code,
        source_system,
        
        -- Territory and team management
        coalesce(territory, 'Unassigned') as territory,
        coalesce(team_lead, 'Not Assigned') as team_lead,
        
        -- Sales team classification
        case 
            when territory in ('Cape Town', 'Western Cape') then 'Cape Town Team'
            when territory in ('Johannesburg', 'Gauteng', 'Pretoria') then 'Gauteng Team'
            when territory in ('Durban', 'KwaZulu-Natal') then 'KZN Team'
            when territory = 'Online' then 'Digital Team'
            else 'Regional Team'
        end as sales_team,
        
        -- Performance attributes
        commission_rate,
        
        -- Employment status
        case 
            when end_date is null or end_date > getdate() then 1
            else 0
        end as is_active,
        
        case 
            when start_date <= getdate() and (end_date is null or end_date > getdate()) then 1
            else 0
        end as is_current_employee,
        
        -- Tenure calculation
        case 
            when start_date is not null then 
                datediff(month, start_date, coalesce(end_date, getdate()))
            else null
        end as tenure_months,
        
        -- Classification
        case 
            when sales_rep_name = 'Unknown Sales Rep' then 'Unassigned'
            when source_system = 'Shopify' then 'Digital Sales'
            when commission_rate > 0 then 'Commission Sales'
            else 'Salary Sales'
        end as rep_category,
        
        -- Date attributes
        start_date,
        end_date,
        last_updated,
        
        -- Data quality tracking
        getdate() as created_at,
        current_timestamp as updated_at
        
    from unified_sales_reps
)

select 
    sales_rep_key,
    source_rep_id,
    sales_rep_name,
    sales_rep_email,
    sales_rep_code,
    source_system,
    territory,
    team_lead,
    sales_team,
    commission_rate,
    is_active,
    is_current_employee,
    tenure_months,
    rep_category,
    start_date,
    end_date,
    last_updated,
    created_at,
    updated_at
from final_dimensions
order by sales_rep_name, source_system