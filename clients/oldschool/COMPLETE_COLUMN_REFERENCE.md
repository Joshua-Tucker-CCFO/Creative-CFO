# Complete Column Reference - All Tables
## Old School Data Model

---

## 🔷 **STAGING LAYER** (16 Views)

### **stg_customers**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR | Unique customer identifier | `id` from cin7core.customer |
| `customer_name` | VARCHAR | Customer business/display name | `name` from cin7core.customer |
| `status` | VARCHAR | Customer status (Active/Inactive) | `status` from cin7core.customer |
| `_fivetran_synced` | TIMESTAMP | When record was last synced by Fivetran | Fivetran metadata |
| `_fivetran_deleted` | INTEGER | Deletion flag (0=active, 1=deleted) | Fivetran metadata |
| `record_status` | VARCHAR | Calculated status ('active' or 'deleted') | Derived from `_fivetran_deleted` |

### **stg_products**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR | Unique product identifier | `id` from cin7core.product |
| `product_name` | VARCHAR | Product display name | `name` from cin7core.product |
| `_fivetran_synced` | TIMESTAMP | When record was last synced | Fivetran metadata |
| `_fivetran_deleted` | INTEGER | Deletion flag (0=active, 1=deleted) | Fivetran metadata |
| `record_status` | VARCHAR | Calculated status ('active' or 'deleted') | Derived from `_fivetran_deleted` |

### **stg_orders**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `order_id` | VARCHAR | Unique order identifier | `id` from cin7core.sale |
| `customer_id` | VARCHAR | Associated customer ID | `customer_id` from cin7core.sale |
| `status` | VARCHAR | Order status | `status` from cin7core.sale |
| `_fivetran_synced` | TIMESTAMP | When record was last synced | Fivetran metadata |
| `_fivetran_deleted` | INTEGER | Deletion flag (0=active, 1=deleted) | Fivetran metadata |
| `record_status` | VARCHAR | Calculated status ('active' or 'deleted') | Derived from `_fivetran_deleted` |

### **stg_cin7_customers**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR | Unique customer identifier | `id` from cin7core.customer |
| `customer_name` | VARCHAR | Customer business name | `name` from cin7core.customer |
| `status` | VARCHAR | Customer status | `status` from cin7core.customer |
| `last_synced_at` | TIMESTAMP | Last sync timestamp | `_fivetran_synced` from source |

### **stg_cin7_products**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR | Unique product identifier | `id` from cin7core.product |
| `product_name` | VARCHAR | Product display name | `name` from cin7core.product |
| `status` | VARCHAR | Product status | `status` from cin7core.product |
| `last_synced_at` | TIMESTAMP | Last sync timestamp | `_fivetran_synced` from source |

### **stg_cin7_sales_orders**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `sales_order_id` | VARCHAR | Unique sales order identifier | `id` from cin7core.sale |
| `customer_id` | VARCHAR | Associated customer ID | `customer_id` from cin7core.sale |
| `order_status` | VARCHAR | Order processing status | `status` from cin7core.sale |
| `last_synced_at` | TIMESTAMP | Last sync timestamp | `_fivetran_synced` from source |

### **stg_cin7_sales_order_lines**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `sales_order_id` | VARCHAR | Reference to sales order | `sale_id` from cin7core.sale_order_line |
| `product_id` | VARCHAR | Reference to product | `product_id` from cin7core.sale_order_line |
| `quantity` | DECIMAL(10,2) | Quantity ordered | `quantity` from cin7core.sale_order_line |
| `unit_price` | DECIMAL(15,2) | Price per unit | `unit_price` from cin7core.sale_order_line |
| `last_synced_at` | TIMESTAMP | Last sync timestamp | `_fivetran_synced` from source |

### **stg_cin7_simple**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `*` | VARIOUS | All columns from sale table | All from cin7core.sale |
| `processed_at` | TIMESTAMP | When processed by dbt | CURRENT_TIMESTAMP |

### **Shopify Staging Tables** (Placeholders - Empty Result Sets)
**stg_shopify_customers**, **stg_shopify_orders**, **stg_shopify_order_lines**, **stg_shopify_products**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `placeholder_id` | VARCHAR(50) | Placeholder column | NULL cast |
| `_fivetran_synced` | TIMESTAMP | Placeholder timestamp | NULL cast |

### **Xero Staging Tables** (Placeholders - Empty Result Sets)
**stg_xero_contacts**, **stg_xero_invoices**, **stg_xero_line_items**, **stg_xero_items**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `placeholder_id` | VARCHAR(50) | Placeholder column | NULL cast |
| `_fivetran_synced` | TIMESTAMP | Placeholder timestamp | NULL cast |

---

## 🔶 **INTERMEDIATE LAYER** (4 Views)

### **int_unified_customers**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR | Unique customer identifier | Derived from multiple sources |
| `customer_name` | VARCHAR | Customer display name | Unified from all sources |
| `source_system` | VARCHAR | Origin system (Xero/Shopify/Cin7) | Calculated based on source |
| `email` | VARCHAR | Customer email address | From respective source systems |
| `phone` | VARCHAR | Customer phone number | From respective source systems |
| `customer_type` | VARCHAR | Customer classification | Business logic applied |

### **int_unified_products**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR | Unique product identifier | Derived from multiple sources |
| `product_name` | VARCHAR | Product display name | Unified from all sources |
| `source_system` | VARCHAR | Origin system (Xero/Shopify/Cin7) | Calculated based on source |
| `category` | VARCHAR | Product category | From respective source systems |
| `status` | VARCHAR | Product status | Unified status logic |

### **int_sales_transactions**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `transaction_id` | VARCHAR | Unique transaction identifier | Derived from source order/invoice IDs |
| `customer_id` | VARCHAR | Reference to unified customer | From source transactions |
| `transaction_date` | DATE | When transaction occurred | From source systems |
| `source_system` | VARCHAR | Origin system | Calculated |
| `amount` | DECIMAL(15,2) | Transaction amount | From source systems |

### **int_customer_orders**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR | Unique customer identifier | From transactions |
| `order_count` | INTEGER | Total number of orders | Aggregated count |
| `total_revenue` | DECIMAL(15,2) | Total customer revenue | Sum of all orders |
| `first_order_date` | DATE | Date of first order | MIN(order_date) |
| `last_order_date` | DATE | Date of most recent order | MAX(order_date) |

---

## 🔴 **MARTS LAYER** (14 Tables)

### **dim_customers_v2**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR(50) | Primary key - customer identifier | `id` from cin7core.customer |
| `customer_name` | VARCHAR(200) | Customer business name | `name` from cin7core.customer |
| `customer_status` | VARCHAR(20) | Customer status (Active/Inactive) | `status` from cin7core.customer |
| `customer_segment` | VARCHAR(50) | Customer segmentation | Business logic applied |
| `created_at` | TIMESTAMP | Record creation timestamp | CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Last update timestamp | CURRENT_TIMESTAMP |

### **dim_products_v2**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR(50) | Primary key - product identifier | `id` from cin7core.product |
| `product_name` | VARCHAR(200) | Product display name | `name` from cin7core.product |
| `product_category` | VARCHAR(100) | Product category | Business logic/mapping |
| `product_status` | VARCHAR(20) | Product status | `status` from cin7core.product |
| `created_at` | TIMESTAMP | Record creation timestamp | CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Last update timestamp | CURRENT_TIMESTAMP |

### **dim_date**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `date_key` | VARCHAR(8) | Primary key (YYYYMMDD format) | Calculated |
| `calendar_date` | DATE | Actual calendar date | Generated |
| `calendar_year` | INTEGER | Calendar year (2020-2027) | YEAR(date) |
| `calendar_month` | INTEGER | Month number (1-12) | MONTH(date) |
| `calendar_day` | INTEGER | Day of month (1-31) | DAY(date) |
| `calendar_quarter` | INTEGER | Quarter (1-4) | DATEPART(quarter) |
| `week_of_year` | INTEGER | Week number in year | DATEPART(week) |
| `day_of_year` | INTEGER | Day number in year (1-366) | DATEPART(dayofyear) |
| `day_of_week` | INTEGER | Day of week (1=Sunday, 7=Saturday) | DATEPART(weekday) |
| `month_year` | VARCHAR(20) | Formatted month-year | FORMAT(date, 'MMMM yyyy') |
| `year_month` | VARCHAR(7) | YYYY-MM format | FORMAT(date, 'yyyy-MM') |
| `day_name` | VARCHAR(10) | Day name (Monday, Tuesday, etc.) | FORMAT(date, 'dddd') |
| `month_name` | VARCHAR(15) | Month name (January, February, etc.) | FORMAT(date, 'MMMM') |
| `fiscal_year` | INTEGER | Fiscal year (April-March) | Calculated |
| `fiscal_quarter` | INTEGER | Fiscal quarter (1-4) | Calculated |
| `is_weekend` | INTEGER | Weekend flag (1=Weekend, 0=Weekday) | Calculated |
| `is_weekday` | INTEGER | Weekday flag (1=Weekday, 0=Weekend) | Calculated |
| `is_holiday` | INTEGER | South African holiday flag | Calculated |
| `is_last_30_days` | INTEGER | Last 30 days flag | Calculated |
| `is_last_90_days` | INTEGER | Last 90 days flag | Calculated |
| `is_current_year` | INTEGER | Current year flag | Calculated |
| `created_at` | TIMESTAMP | Record creation timestamp | GETDATE() |

### **fct_sales**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `sale_id` | VARCHAR(50) | Primary key - sale identifier | `id` from cin7core.sale |
| `customer_id` | VARCHAR(50) | Foreign key to dim_customers | From sales order |
| `product_id` | VARCHAR(50) | Foreign key to dim_products | From order lines |
| `sale_date` | DATE | Date of sale | From sales order |
| `quantity` | DECIMAL(10,2) | Quantity sold | From order lines |
| `unit_price` | DECIMAL(15,2) | Price per unit | From order lines |
| `line_total` | DECIMAL(15,2) | Total line amount | quantity * unit_price |
| `sale_status` | VARCHAR(20) | Status of sale | From sales order |
| `created_at` | TIMESTAMP | Record creation timestamp | CURRENT_TIMESTAMP |

### **simple_customer_dim**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR(50) | Primary key | `id` from cin7core.customer |
| `customer_name` | VARCHAR(200) | Customer name | `name` from cin7core.customer |
| `customer_status` | VARCHAR(20) | Status | `status` from cin7core.customer |
| `_fivetran_synced` | TIMESTAMP | Sync timestamp | Fivetran metadata |
| `dbt_processed_at` | TIMESTAMP | dbt processing time | CURRENT_TIMESTAMP |

### **simple_product_dim**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR(50) | Primary key | `id` from cin7core.product |
| `product_name` | VARCHAR(200) | Product name | `name` from cin7core.product |
| `_fivetran_synced` | TIMESTAMP | Sync timestamp | Fivetran metadata |
| `dbt_processed_at` | TIMESTAMP | dbt processing time | CURRENT_TIMESTAMP |

### **simple_sales_fact**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `sale_id` | VARCHAR(50) | Primary key | `id` from cin7core.sale |
| `customer_id` | VARCHAR(50) | Foreign key | `customer_id` from cin7core.sale |
| `sale_status` | VARCHAR(20) | Sale status | `status` from cin7core.sale |
| `_fivetran_synced` | TIMESTAMP | Sync timestamp | Fivetran metadata |
| `dbt_processed_at` | TIMESTAMP | dbt processing time | CURRENT_TIMESTAMP |

### **fct_sales_simple** (in marts_simple schema)
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `sale_id` | VARCHAR(50) | Primary key | `id` from cin7core.sale |
| `customer_id` | VARCHAR(50) | Foreign key | `customer_id` from cin7core.sale |
| `sale_status` | VARCHAR(20) | Sale status | `status` from cin7core.sale |
| `_fivetran_synced` | TIMESTAMP | Sync timestamp | Fivetran metadata |
| `dbt_processed_at` | TIMESTAMP | dbt processing time | CURRENT_TIMESTAMP |

### **Legacy Dimensions** (dim_customers, dim_products)
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `source_customer_id` / `source_product_id` | VARCHAR(50) | Legacy primary key | Source system ID |
| `customer_name` / `product_name` | VARCHAR(200) | Name fields | Source system |
| `customer_type` / `product_category` | VARCHAR(100) | Classification | Business logic |

### **Planned Tables** (customer_analytics, daily_revenue, dim_sales_rep)
*Structure to be defined during implementation*

---

## 📈 **REPORTING LAYER** (4 Views)

### **vw_sales_performance**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `date` | DATE | Performance date | From fct_sales |
| `revenue` | DECIMAL(15,2) | Daily revenue | SUM(line_total) |
| `growth_rate` | DECIMAL(5,2) | Revenue growth % | Calculated |
| `top_products` | VARCHAR(500) | Best-selling products | Aggregated |

### **vw_customer_overview**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_segment` | VARCHAR(50) | Customer segment | From dim_customers |
| `customer_count` | INTEGER | Number of customers | COUNT(*) |
| `lifetime_value` | DECIMAL(15,2) | Average LTV | Calculated |
| `churn_rate` | DECIMAL(5,2) | Churn percentage | Calculated |

### **vw_inventory_status**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `product_id` | VARCHAR(50) | Product identifier | From dim_products |
| `product_name` | VARCHAR(200) | Product name | From dim_products |
| `stock_on_hand` | INTEGER | Current inventory | Business logic |
| `turnover_rate` | DECIMAL(5,2) | Inventory turnover | Calculated |

### **vw_business_summary**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `kpi_name` | VARCHAR(100) | KPI identifier | Static list |
| `kpi_value` | DECIMAL(15,2) | Current value | Calculated |
| `trend` | VARCHAR(20) | Trend direction | Calculated |

---

## 🧪 **TEST LAYER** (1 View)

### **test_connection**
| Column Name | Data Type | Description | Source |
|-------------|-----------|-------------|---------|
| `customer_id` | VARCHAR(50) | Customer ID | TOP 10 from cin7core.customer |
| `customer_name` | VARCHAR(200) | Customer name | TOP 10 from cin7core.customer |
| `status` | VARCHAR(20) | Status | TOP 10 from cin7core.customer |

---

## 📋 **Summary Statistics**

| Layer | Tables | Total Columns | Key Tables |
|-------|--------|---------------|------------|
| **Staging** | 16 views | ~96 columns | stg_cin7_customers, stg_cin7_products, stg_cin7_sales_orders |
| **Intermediate** | 4 views | ~24 columns | int_unified_customers, int_unified_products |
| **Marts** | 14 tables | ~98 columns | dim_date (23 cols), fct_sales (9 cols), simple_* tables |
| **Reporting** | 4 views | ~16 columns | vw_sales_performance, vw_customer_overview |
| **Test** | 1 view | ~3 columns | test_connection |
| **TOTAL** | **39 models** | **~237 columns** | **Power BI Ready: 18 models** |

---

**Document Version:** 1.0
**Last Updated:** September 2024
**Next Review:** After manager feedback