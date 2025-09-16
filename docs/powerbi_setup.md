# Power BI Setup Guide

## Quick Setup Steps

1. **Open Power BI Desktop**
2. **Get Data** → **Azure SQL Database**
3. **Enter Connection Details:**
   - Server: `oldschoolbi.database.windows.net`
   - Database: `OldSchool-Dev-DB`
   - Data Connectivity mode: Import
   - Username: `CloudSA251754e9@oldschoolbi`
   - Password: `*"P{"p50WN4l$A;1qAZZ`

4. **Select These Tables:**
   - [x] dbt_jtucker.powerbi_sales_fact
   - [x] dbt_jtucker.powerbi_customer_dim
   - [x] dbt_jtucker.powerbi_product_dim

## Data Model Relationships

After importing, create these relationships in the Model view:

1. **Sales → Customer**
   - From: `powerbi_sales_fact.customer_id`
   - To: `powerbi_customer_dim.customer_id`
   - Cardinality: Many to One (*:1)
   - Cross filter: Single

2. **Sales → Product** (if you add product_id to sales)
   - From: `powerbi_sales_fact.product_id`
   - To: `powerbi_product_dim.product_id`
   - Cardinality: Many to One (*:1)
   - Cross filter: Single

## Recommended Measures (DAX)

Add these measures to your Sales Fact table:

```dax
Total Sales = SUM(powerbi_sales_fact[total_amount])

Total Orders = DISTINCTCOUNT(powerbi_sales_fact[order_number])

Average Order Value = DIVIDE([Total Sales], [Total Orders], 0)

Tax Amount = SUM(powerbi_sales_fact[tax_amount])

Net Sales = SUM(powerbi_sales_fact[subtotal_amount])

YTD Sales = 
CALCULATE(
    [Total Sales],
    DATESYTD(powerbi_sales_fact[order_date])
)

Sales Last Month = 
CALCULATE(
    [Total Sales],
    DATEADD(powerbi_sales_fact[order_date], -1, MONTH)
)

MoM Growth % = 
DIVIDE(
    [Total Sales] - [Sales Last Month],
    [Sales Last Month],
    0
) * 100

Customer Count = DISTINCTCOUNT(powerbi_sales_fact[customer_id])

Sales by Status = 
CALCULATE(
    [Total Sales],
    powerbi_sales_fact[order_status] = "Completed"
)
```

## Recommended Visualizations

### Page 1: Executive Dashboard
1. **Card Visuals** (Top Row)
   - Total Sales
   - Total Orders  
   - Customer Count
   - Average Order Value

2. **Line Chart**: Sales Over Time
   - Axis: order_date (Hierarchy: Year > Quarter > Month)
   - Values: Total Sales

3. **Bar Chart**: Top 10 Customers
   - Axis: customer_name (from dim)
   - Values: Total Sales
   - Filter: Top 10

4. **Pie Chart**: Sales by Location
   - Legend: location
   - Values: Total Sales

5. **Table**: Sales by Representative
   - Columns: sales_representative, Total Sales, Total Orders, AOV

### Page 2: Product Analysis
1. **Bar Chart**: Top Products by Revenue
   - Axis: product_name
   - Values: Related sales amounts

2. **Matrix**: Category Performance
   - Rows: brand, product_name
   - Values: Units Sold, Revenue

3. **Scatter Plot**: Price vs Volume
   - X-axis: retail_price
   - Y-axis: Sales Volume
   - Size: Total Revenue

### Page 3: Time Intelligence
1. **Line Chart**: Monthly Trend with Forecast
   - Axis: order_date
   - Values: Total Sales
   - Analytics: Add trend line & forecast

2. **Waterfall Chart**: Month over Month Changes
   - Category: order_month
   - Values: Total Sales

3. **Heat Map**: Sales by Day of Week & Hour
   - Use custom visual or matrix

## Filters to Add

### Report-Level Filters:
- Date Range Slicer (order_date)
- Location Dropdown
- Sales Representative Dropdown

### Page-Level Filters:
- Customer Status = 'Active'
- Order Status (multi-select)
- Currency Code

## Color Theme (Professional Blue)
```json
{
    "name": "Corporate Blue",
    "colors": [
        "#003f5c",
        "#2f4b7c", 
        "#665191",
        "#a05195",
        "#d45087",
        "#f95d6a",
        "#ff7c43",
        "#ffa600"
    ]
}
```

## Quick Start DAX Calendar Table

```dax
Calendar = 
ADDCOLUMNS(
    CALENDAR(
        DATE(2020,1,1),
        DATE(2025,12,31)
    ),
    "Year", YEAR([Date]),
    "Month", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMM"),
    "Quarter", "Q" & QUARTER([Date]),
    "WeekDay", FORMAT([Date], "ddd"),
    "WeekNum", WEEKNUM([Date]),
    "YearMonth", FORMAT([Date], "YYYY-MM")
)
```

Then create relationship:
- Calendar[Date] → powerbi_sales_fact[order_date] (1:*)

Save this as "Cin7 Sales Analytics.pbix"