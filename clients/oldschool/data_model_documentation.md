# 📊 Comprehensive Data Model Documentation
## OldSchool Fivetran Integration (Cin7 + Shopify + Future Xero)

---

## 🏗️ Current Data Architecture

### Data Sources Status:
- ✅ **Cin7 Core** - Inventory & Order Management (Active, 61 tables)
- ✅ **Shopify** - E-commerce Platform (Syncing, schema TBD)
- ⏳ **Xero** - Accounting System (Pending connection)

---

## 1️⃣ CIN7 CORE DATA MODEL

### 📦 Core Business Entities

#### **SALES Module**
```
cin7core.sale (Main Order Table)
├── id (PK) ─────────────────┐
├── customer_id (FK) ─────────┼──→ cin7core.customer
├── order_number             │
├── order_date               │
├── order_status             │
├── order_total              │
├── location                 │
└── _fivetran_synced         │
                             │
cin7core.sale_order_line     │
├── id (PK)                  │
├── sale_id (FK) ────────────┘
├── product_id (FK) ──────────→ cin7core.product
├── quantity
├── unit_price
└── line_total
```

#### **CUSTOMER Module**
```
cin7core.customer (Customer Master)
├── id (PK)
├── name
├── email
├── status
├── credit_limit
├── price_tier
├── is_on_credit_hold
├── location
└── sales_representative

cin7core.customer_address
├── id (PK)
├── customer_id (FK) ──→ customer
├── address_type
├── address_line_1
├── city
├── postal_code
└── country

cin7core.customer_contacts
├── id (PK)
├── customer_id (FK) ──→ customer
├── contact_name
├── email
└── phone
```

#### **PRODUCT/INVENTORY Module**
```
cin7core.product (Product Master)
├── id (PK)
├── sku
├── name
├── barcode
├── category_id (FK) ──→ category
├── brand
├── price_tier_1 (retail)
├── price_tier_2 (wholesale)
├── stock_locator
├── default_location
└── status

cin7core.product_movement
├── movement_id (PK)
├── product_id (FK) ──→ product
├── movement_date
├── movement_type
├── quantity
└── reference_id ──→ sale/purchase

cin7core.non_zero_stock_on_hand_product
├── product_id (FK) ──→ product
├── location
├── quantity_on_hand
└── last_updated
```

#### **PURCHASE/SUPPLIER Module**
```
cin7core.purchase
├── id (PK)
├── supplier_id
├── purchase_order_number
├── order_date
├── status
└── total_amount

cin7core.purchase_order_line
├── id (PK)
├── purchase_id (FK) ──→ purchase
├── product_id (FK) ──→ product
├── quantity_ordered
├── unit_cost
└── line_total
```

#### **FINANCIAL Module**
```
cin7core.chart_of_account
├── account_id (PK)
├── account_code
├── account_name
├── account_type
└── parent_account_id

cin7core.purchase_invoice
├── invoice_id (PK)
├── purchase_id (FK) ──→ purchase
├── invoice_number
├── invoice_date
├── due_date
└── total_amount

cin7core.purchase_invoice_payment
├── payment_id (PK)
├── invoice_id (FK) ──→ purchase_invoice
├── payment_date
├── payment_amount
└── payment_method
```

---

## 2️⃣ SHOPIFY DATA MODEL (Expected Structure)

### 🛍️ E-commerce Entities

#### **ORDERS Module**
```
shopify.orders
├── id (PK)
├── order_number
├── customer_id (FK) ──→ shopify.customers
├── created_at
├── financial_status
├── fulfillment_status
├── total_price
├── currency
└── cancelled_at

shopify.order_lines
├── id (PK)
├── order_id (FK) ──→ orders
├── product_id (FK) ──→ products
├── variant_id (FK) ──→ product_variants
├── quantity
├── price
└── total_discount
```

#### **CUSTOMERS Module**
```
shopify.customers
├── id (PK)
├── email
├── first_name
├── last_name
├── phone
├── total_spent
├── orders_count
└── state (enabled/disabled)

shopify.customer_addresses
├── id (PK)
├── customer_id (FK) ──→ customers
├── address1
├── city
├── province
├── country
└── zip
```

#### **PRODUCTS Module**
```
shopify.products
├── id (PK)
├── title
├── vendor
├── product_type
├── handle (URL slug)
├── status
└── published_at

shopify.product_variants
├── id (PK)
├── product_id (FK) ──→ products
├── sku
├── price
├── compare_at_price
├── inventory_quantity
└── barcode
```

---

## 3️⃣ CROSS-SYSTEM RELATIONSHIPS

### 🔗 Key Integration Points

#### **Customer Matching**
```sql
-- Cin7 ←→ Shopify Customer Mapping
cin7core.customer.email = shopify.customers.email
-- OR --
cin7core.customer.name = CONCAT(shopify.customers.first_name, ' ', shopify.customers.last_name)
```

#### **Product/SKU Matching**
```sql
-- Cin7 ←→ Shopify Product Mapping
cin7core.product.sku = shopify.product_variants.sku
-- OR --
cin7core.product.barcode = shopify.product_variants.barcode
```

#### **Order Synchronization**
```sql
-- Shopify orders may create Cin7 sales
shopify.orders.name → cin7core.sale.reference
shopify.orders.id → cin7core.sale.external_id
```

---

## 4️⃣ FUTURE XERO INTEGRATION

### 📚 Expected Xero Entities & Mappings

#### **XERO Module (When Connected)**
```
xero.invoices
├── invoice_id (PK)
├── invoice_number ──────→ cin7core.sale.order_number
├── contact_id (FK) ─────→ xero.contacts
├── date
├── due_date
├── total
├── status
└── type (ACCREC/ACCPAY)

xero.contacts
├── contact_id (PK)
├── name ────────────────→ cin7core.customer.name
├── email ───────────────→ cin7core.customer.email
├── is_customer
└── is_supplier

xero.line_items
├── line_item_id (PK)
├── invoice_id (FK) ─────→ invoices
├── item_code ───────────→ cin7core.product.sku
├── quantity
├── unit_amount
└── account_code ────────→ cin7core.chart_of_account.account_code
```

---

## 5️⃣ UNIFIED DATA MODEL

### 🎯 Master Fact & Dimension Tables

```yaml
fact_sales:
  sources:
    - cin7core.sale (primary)
    - shopify.orders (e-commerce)
    - xero.invoices (future - financial truth)
  
  grain: One row per sales transaction
  
  keys:
    - sale_id (natural key)
    - customer_id (FK → dim_customers)
    - product_id (FK → dim_products)
    - date_id (FK → dim_date)
  
  measures:
    - total_amount
    - tax_amount
    - discount_amount
    - quantity_sold
    - cost_of_goods_sold
    - gross_profit

dim_customers:
  sources:
    - cin7core.customer (primary)
    - shopify.customers (e-commerce data)
    - xero.contacts (future - billing info)
  
  matching_logic: Email > Name > Phone
  
  attributes:
    - customer_id (surrogate key)
    - customer_name
    - email
    - customer_segment
    - lifetime_value
    - credit_status
    - location

dim_products:
  sources:
    - cin7core.product (primary - inventory)
    - shopify.products + variants (e-commerce)
    - xero.items (future - accounting codes)
  
  matching_logic: SKU > Barcode > Name
  
  attributes:
    - product_id (surrogate key)
    - sku
    - product_name
    - category
    - brand
    - current_price
    - current_stock
    - margin_percentage
```

---

## 6️⃣ DATA QUALITY & RELATIONSHIPS

### 🔍 Key Integrity Rules

1. **Customer Deduplication**
   - Match by email first
   - Then by normalized name
   - Create master customer record

2. **Product Harmonization**
   - SKU is primary identifier
   - Fallback to barcode
   - Handle variant differences

3. **Order Consolidation**
   - Cin7 sales are source of truth for fulfillment
   - Shopify orders for online channel
   - Xero invoices for financial reporting

4. **Inventory Tracking**
   - Cin7 holds real-time stock
   - Shopify reflects available to sell
   - Reconciliation required daily

---

## 7️⃣ IMPLEMENTATION QUERIES

### Current Available Queries:

```sql
-- Get unified sales view (Cin7 only for now)
SELECT 
    s.id as sale_id,
    s.customer_id,
    c.name as customer_name,
    s.order_number,
    s.order_date,
    s.order_total,
    s.location,
    'cin7' as source_system
FROM cin7core.sale s
LEFT JOIN cin7core.customer c ON s.customer_id = c.id
WHERE s._fivetran_deleted = 0;

-- Product inventory status
SELECT 
    p.sku,
    p.name,
    p.brand,
    COALESCE(stk.quantity_on_hand, 0) as current_stock,
    p.price_tier_1 as retail_price,
    p.status
FROM cin7core.product p
LEFT JOIN cin7core.non_zero_stock_on_hand_product stk 
    ON p.id = stk.product_id
WHERE p._fivetran_deleted = 0;

-- Customer purchase history
SELECT 
    c.name as customer_name,
    COUNT(DISTINCT s.id) as total_orders,
    SUM(s.order_total) as lifetime_value,
    MAX(s.order_date) as last_order_date,
    c.credit_limit,
    c.is_on_credit_hold
FROM cin7core.customer c
LEFT JOIN cin7core.sale s ON c.id = s.customer_id
WHERE c._fivetran_deleted = 0
GROUP BY c.id, c.name, c.credit_limit, c.is_on_credit_hold;
```

### Future Unified Query (with all sources):

```sql
-- Unified sales across all channels
WITH all_sales AS (
    -- Cin7 Sales
    SELECT 
        'cin7' as source,
        id as transaction_id,
        customer_id,
        order_date,
        order_total as amount
    FROM cin7core.sale
    
    UNION ALL
    
    -- Shopify Orders (when available)
    SELECT 
        'shopify' as source,
        id as transaction_id,
        customer_id,
        created_at as order_date,
        total_price as amount
    FROM shopify.orders
    
    UNION ALL
    
    -- Xero Invoices (future)
    SELECT 
        'xero' as source,
        invoice_id as transaction_id,
        contact_id as customer_id,
        date as order_date,
        total as amount
    FROM xero.invoices
    WHERE type = 'ACCREC'
)
SELECT * FROM all_sales;
```

---

## 📈 Next Steps

1. **Complete Shopify schema discovery** once sync completes
2. **Build intermediate matching tables** for customer/product dedup
3. **Create data quality tests** for key relationships
4. **Prepare Xero mapping logic** for when connected
5. **Build Power BI data model** with all relationships defined