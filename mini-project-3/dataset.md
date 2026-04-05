# Dataset & Data Logic

## 1. Tables Used

* orders
* order_items
* payments

---

## 2. Data Reality

The dataset includes:

* Orders without payment
* Partial payments
* Payment mismatches
* Cancelled/refunded scenarios

---

## 3. Revenue Validation Logic

To ensure accuracy:

### Step 1 — Calculate order value

SUM(quantity * unit_price) + shipping_fee

### Step 2 — Calculate paid amount

SUM(paid_amount) WHERE payment_status = 'paid'

### Step 3 — Validate order

ABS(order_total - paid_total) <= 0.01

---

## 4. Final Dataset Definition

Only validated orders are used for:

* Recency
* Frequency
* Monetary

---

## 5. Important Assumptions

* payment_status = 'paid' is source of truth
* order status is NOT reliable
* floating differences are tolerated (<= 0.01)

---

## 6. Data Grain

* Order level → validation
* Customer level → RFM calculation

Maintaining correct data grain is critical to avoid:

* double counting
* inflated revenue
* incorrect segmentation

## How to Use

1. Set up the database using [ecommerce_db.sql](https://github.com/user-attachments/files/26117482/ecommerce_db.sql)
2. Run the SQL query file to reproduce results
