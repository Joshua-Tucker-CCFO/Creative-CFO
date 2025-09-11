{{
    config(
        materialized='table',
        indexes=[
            {'columns': ['date_key'], 'type': 'clustered'},
            {'columns': ['calendar_year', 'calendar_month']},
            {'columns': ['fiscal_year', 'fiscal_quarter']},
            {'columns': ['day_of_week']},
            {'columns': ['is_weekend']},
            {'columns': ['is_holiday']}
        ]
    )
}}

-- Comprehensive date dimension for time-based analytics
-- Covers business calendar, fiscal periods, and special date attributes
-- Range: Historical data start (2020) through future planning (2027)
with date_spine as (
    -- Generate date series using dbt_utils date_spine macro
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2027-12-31' as date)"
    ) }}
), 

date_attributes as (
    select
        date_day as calendar_date,
        
        -- Primary key
        format(date_day, 'yyyyMMdd') as date_key,
        
        -- Calendar attributes
        year(date_day) as calendar_year,
        month(date_day) as calendar_month,
        day(date_day) as calendar_day,
        datepart(quarter, date_day) as calendar_quarter,
        datepart(week, date_day) as week_of_year,
        datepart(dayofyear, date_day) as day_of_year,
        datepart(weekday, date_day) as day_of_week,
        
        -- Formatted date strings for reporting
        format(date_day, 'MMMM yyyy') as month_year,
        format(date_day, 'yyyy-MM') as year_month,
        format(date_day, 'dddd') as day_name,
        format(date_day, 'MMMM') as month_name,
        
        -- Fiscal year (April - March) for Pack Leader alignment
        case 
            when month(date_day) >= 4 then year(date_day)
            else year(date_day) - 1
        end as fiscal_year,
        
        case 
            when month(date_day) in (4, 5, 6) then 1
            when month(date_day) in (7, 8, 9) then 2
            when month(date_day) in (10, 11, 12) then 3
            else 4
        end as fiscal_quarter,
        
        -- Business day indicators
        case 
            when datepart(weekday, date_day) in (1, 7) then 1
            else 0
        end as is_weekend,
        
        case 
            when datepart(weekday, date_day) between 2 and 6 then 1
            else 0
        end as is_weekday,
        
        -- Holiday detection (basic South African holidays)
        case 
            when (month(date_day) = 1 and day(date_day) = 1) then 1  -- New Year
            when (month(date_day) = 3 and day(date_day) = 21) then 1  -- Human Rights Day
            when (month(date_day) = 4 and day(date_day) = 27) then 1  -- Freedom Day
            when (month(date_day) = 5 and day(date_day) = 1) then 1   -- Workers Day
            when (month(date_day) = 6 and day(date_day) = 16) then 1  -- Youth Day
            when (month(date_day) = 8 and day(date_day) = 9) then 1   -- National Women's Day
            when (month(date_day) = 9 and day(date_day) = 24) then 1  -- Heritage Day
            when (month(date_day) = 12 and day(date_day) = 16) then 1 -- Day of Reconciliation
            when (month(date_day) = 12 and day(date_day) = 25) then 1 -- Christmas
            when (month(date_day) = 12 and day(date_day) = 26) then 1 -- Day of Goodwill
            else 0
        end as is_holiday,
        
        -- Period indicators for analysis
        case 
            when date_day >= dateadd(day, -30, getdate()) then 1
            else 0
        end as is_last_30_days,
        
        case 
            when date_day >= dateadd(day, -90, getdate()) then 1
            else 0
        end as is_last_90_days,
        
        case 
            when year(date_day) = year(getdate()) then 1
            else 0
        end as is_current_year,
        
        -- Data quality tracking
        getdate() as created_at
        
    from date_spine
)

select * from date_attributes
order by calendar_date