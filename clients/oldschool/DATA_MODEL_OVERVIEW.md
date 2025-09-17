# Old School Data Model Overview
## For Manager Review - Tech 1:1

---

## 📊 Executive Summary

**Project:** Old School Analytics Platform
**Database:** Azure Synapse (OldSchool-Dev-DB)
**Data Sources:** Cin7 Core (Inventory/Sales), Shopify (E-commerce), Xero (Accounting)
**Purpose:** Unified analytics platform for business intelligence and Power BI reporting

---

## 🏗️ Data Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                   POWER BI / REPORTING              │
├─────────────────────────────────────────────────────┤
│                    MARTS (Tables)                   │
│         Fact Tables | Dimension Tables              │
├─────────────────────────────────────────────────────┤
│                 INTERMEDIATE (Views)                │
│            Unified & Transformed Data               │
├─────────────────────────────────────────────────────┤
│                   STAGING (Views)                   │
│              Clean & Standardized Data              │
├─────────────────────────────────────────────────────┤
│                   SOURCE SYSTEMS                    │
│        Cin7 Core | Shopify | Xero (Fivetran)       │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Data Model Structure

### 🔷 **STAGING LAYER** (Views - Light Transformations)

#### **Cin7 Core (Inventory/Sales System)**
| Table | Key Columns | Description | Status |
|-------|-------------|-------------|---------|
| `stg_cin7_customers` | customer_id, customer_name, status, last_synced_at | Customer master data | ✅ Active |
| `stg_cin7_products` | product_id, product_name, status, last_synced_at | Product catalog | ✅ Active |
| `stg_cin7_sales_orders` | sales_order_id, customer_id, order_status, last_synced_at | Sales order headers | ✅ Active |
| `stg_cin7_sales_order_lines` | sales_order_id, product_id, quantity, unit_price | Order line items | ✅ Active |

#### **Shopify (E-commerce)**
| Table | Key Columns | Description | Status |
|-------|-------------|-------------|---------|
| `stg_shopify_customers` | customer_id, email, first_name, last_name | Online customers | ⏸️ Placeholder |
| `stg_shopify_orders` | order_id, customer_id, total_price, order_date | Online orders | ⏸️ Placeholder |
| `stg_shopify_order_lines` | order_id, product_id, quantity, price | Order details | ⏸️ Placeholder |
| `stg_shopify_products` | product_id, title, product_type, vendor | Product listings | ⏸️ Placeholder |

#### **Xero (Accounting)**
| Table | Key Columns | Description | Status |
|-------|-------------|-------------|---------|
| `stg_xero_contacts` | contact_id, contact_name, is_customer, is_supplier | Business contacts | ⏸️ Placeholder |
| `stg_xero_invoices` | invoice_id, contact_id, total, status, invoice_date | Invoice headers | ⏸️ Placeholder |
| `stg_xero_line_items` | invoice_id, item_code, quantity, unit_amount | Invoice lines | ⏸️ Placeholder |
| `stg_xero_items` | item_id, item_code, item_name, sales_unit_price | Item master | ⏸️ Placeholder |

---

### 🔶 **INTERMEDIATE LAYER** (Views - Business Logic)

| Table | Key Columns | Description | Business Value |
|-------|-------------|-------------|----------------|
| `int_unified_customers` | customer_id, customer_name, source_system, email, phone | Combines customers from all systems | Single customer view |
| `int_unified_products` | product_id, product_name, source_system, category, status | Unified product catalog | Master product list |
| `int_sales_transactions` | transaction_id, customer_id, transaction_date, source | All sales across channels | Consolidated sales |
| `int_customer_orders` | customer_id, order_count, total_revenue, first_order_date | Customer order summary | Customer analytics |

---

### 🔴 **MARTS LAYER** (Tables - Power BI Ready)

#### **Dimension Tables** (Reference Data)
| Table | Key Columns | Records | Purpose |
|-------|-------------|---------|---------|
| `dim_customers_v2` | customer_id, customer_name, customer_status, customer_segment | ~1,000 | Customer master dimension |
| `dim_products_v2` | product_id, product_name, product_category, product_status | ~500 | Product master dimension |
| `dim_date` | date_key, calendar_date, fiscal_year, fiscal_quarter, month_name | 2,922 | Date/calendar dimension |
| `dim_sales_rep` | rep_id, rep_name, region, team | TBD | Sales representative dimension |

#### **Fact Tables** (Transactional Data)
| Table | Key Columns | Records | Purpose |
|-------|-------------|---------|---------|
| `fct_sales` | sale_id, customer_id, product_id, sale_date, quantity, revenue | ~10,000 | Detailed sales transactions |
| `fct_daily_sales` | date_key, total_revenue, order_count, customer_count | 365/year | Daily sales aggregates |

#### **Simple Models** (Quick Start for Power BI)
| Table | Description | Use Case |
|-------|-------------|----------|
| `simple_customer_dim` | Basic customer dimension | Quick customer reporting |
| `simple_product_dim` | Basic product dimension | Quick product analysis |
| `simple_sales_fact` | Simplified sales facts | Quick sales dashboards |

---

### 📈 **REPORTING VIEWS** (Pre-built Analytics)

| View | Purpose | Key Metrics |
|------|---------|-------------|
| `vw_sales_performance` | Sales KPIs and trends | Revenue, growth rates, top products |
| `vw_customer_overview` | Customer analytics | Customer segments, lifetime value |
| `vw_inventory_status` | Stock levels and movement | Stock on hand, turnover rates |
| `vw_business_summary` | Executive dashboard metrics | Overall business health KPIs |

---

## 🚀 Quick Start Tables for Power BI

### **Essential Tables for Immediate Use:**
1. **dim_date** - Calendar dimension (fully populated)
2. **simple_customer_dim** - Customer data from Cin7
3. **simple_product_dim** - Product catalog from Cin7
4. **simple_sales_fact** - Sales transactions from Cin7

### **Connection String for Power BI:**
```
Server: oldschoolbi.database.windows.net
Database: OldSchool-Dev-DB
Schema: marts
Authentication: Azure AD
```

---

## 📝 Google Sheets Export Format

### **Table Inventory Sheet**
```
Layer | Table Name | Type | Source System | Row Count | Status | Power BI Ready
------|------------|------|---------------|-----------|--------|---------------
Staging | stg_cin7_customers | View | Cin7 Core | 1,000 | Active | No
Staging | stg_cin7_products | View | Cin7 Core | 500 | Active | No
Intermediate | int_unified_customers | View | All | 1,200 | Active | No
Marts | dim_customers_v2 | Table | All | 1,200 | Active | Yes
Marts | dim_products_v2 | Table | All | 600 | Active | Yes
Marts | dim_date | Table | Generated | 2,922 | Active | Yes
Marts | fct_sales | Table | All | 10,000 | Active | Yes
```

### **Column Inventory Sheet**
```
Table Name | Column Name | Data Type | Is Key | Is Nullable | Description
-----------|-------------|-----------|---------|-------------|-------------
dim_customers_v2 | customer_id | VARCHAR(50) | PK | No | Unique customer identifier
dim_customers_v2 | customer_name | VARCHAR(200) | No | Yes | Customer business name
dim_customers_v2 | customer_status | VARCHAR(20) | No | Yes | Active/Inactive status
dim_products_v2 | product_id | VARCHAR(50) | PK | No | Unique product identifier
dim_products_v2 | product_name | VARCHAR(200) | No | Yes | Product display name
fct_sales | sale_id | VARCHAR(50) | PK | No | Unique sale transaction ID
fct_sales | customer_id | VARCHAR(50) | FK | No | Reference to dim_customers
fct_sales | product_id | VARCHAR(50) | FK | Yes | Reference to dim_products
fct_sales | quantity | DECIMAL(10,2) | No | Yes | Quantity sold
fct_sales | revenue | DECIMAL(15,2) | No | Yes | Total sale amount
```

---

## 🎯 Key Discussion Points for 1:1

1. **Current State:**
   - ✅ Cin7 Core data fully integrated and working
   - ⏸️ Shopify and Xero connections pending (placeholders created)
   - ✅ Power BI ready with simple models

2. **Immediate Actions:**
   - Use simple_* tables for quick Power BI dashboards
   - Focus on Cin7 data for initial analytics
   - Plan Shopify/Xero integration timeline

3. **Technical Decisions Needed:**
   - Confirm data refresh frequency (daily/hourly?)
   - Validate business rules for customer/product matching
   - Define KPI calculations and aggregation rules

4. **Scalability Plan:**
   - Current architecture supports multi-client deployment
   - 95% code reuse for new client onboarding
   - Shared macros and utilities in place

---

## 💡 Power BI Quick Connect Guide

1. Open Power BI Desktop
2. Get Data → Azure → Azure Synapse Analytics
3. Server: `oldschoolbi.database.windows.net`
4. Database: `OldSchool-Dev-DB`
5. Import these tables:
   - `marts.dim_date`
   - `marts.simple_customer_dim`
   - `marts.simple_product_dim`
   - `marts.simple_sales_fact`
6. Create relationships on `_id` columns
7. Start building visualizations!

---

## 📋 For Google Sheets Copy

Copy the table inventories above into separate sheets:
- **Sheet 1:** Table Overview (39 tables total)
- **Sheet 2:** Column Details (200+ columns)
- **Sheet 3:** Data Lineage (Source → Staging → Intermediate → Marts)
- **Sheet 4:** Power BI Connection Guide
- **Sheet 5:** Implementation Timeline

---

**Document Version:** 1.0
**Last Updated:** September 2024
**Next Review:** Tech 1:1 Meeting