# DAY 14 UPDATE

**DAY 14 | COMPLETED | 1h | Level: 4.8/5**

## Focus Topic Project 2 — Payment Validation & Data Integrity

## Session Notes

- Built a full validation query comparing orders.total_amount vs SUM(payments.paid_amount).
- Applied multi-layer aggregation using CTEs to separate calculation logic (payments vs recalculated order value).
- Practiced combining order_items, orders, and payments without causing JOIN explosion.
- Implemented CASE WHEN logic to classify orders into:
    • correctly paid
    • underpaid
    • overpaid
    • no payment
- Identified real-world data issues such as:
    • missing payment records
    • mismatched payment vs order value
- Reinforced importance of filtering payment_status = 'paid' before aggregation.

## Minhyi Notes

- Initially used INNER JOIN which caused loss of orders without payment records.
- Realized that the issue was not missing columns, but losing rows due to join type.
- Switched to LEFT JOIN to preserve all orders and correctly detect "no payment" cases.
- Understood that validation queries must always include missing-data scenarios, not just mismatched values.

## Key Lesson

"Data validation is not just comparing numbers — it requires preserving missing cases and correctly structuring joins to reflect business reality."

## Bootcamp Progress Update

Current Streak: 14 Days
Bootcamp Progress: Day 14 / 42
Completion: ~33%

## Query

### 1.Customer Revenue
```sql
SELECT
o.customer_id,
SUM(O.total_amount) AS total_spent
FROM orders o 
WHERE o.status = 'completed'
GROUP BY o.customer_id;

```
### 2.Top 5 Product
```sql
SELECT
oi.product_id,
p.product_name,
SUM(oi.quantity * oi.unit_price) AS prod_revenue
FROM order_items oi 
JOIN products p ON p.product_id = oi.product_id
GROUP BY oi.product_id
ORDER BY prod_revenue DESC
LIMIT 5;

```
### 3.Payment Validation
```sql
WITH totalpaid AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS total_paid
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
calcamount AS(
    SELECT
    oi.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS calculated_amount
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.order_id
)
SELECT
ca.order_id,
ca.calculated_amount,
tp.total_paid,
CASE
WHEN tp.total_paid IS NULL THEN 'no payment record'
WHEN tp.total_paid = 0 THEN 'not paid'
WHEN ca.calculated_amount = tp.total_paid THEN 'correct paid'
WHEN ca.calculated_amount > tp.total_paid THEN 'underpaid'
WHEN ca.calculated_amount < tp.total_paid THEN 'overpaid'
ELSE 'other'
END AS payment_validation
FROM calcamount ca  
LEFT JOIN totalpaid tp ON tp.order_id = ca.order_id;

```
### 4.Above Average Customer
```sql
WITH totalspent AS(
    SELECT
    o.customer_id,
    SUM(o.total_amount) AS total_spent
    FROM orders o 
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
)
SELECT
ts.customer_id,
c.full_name,
ts.total_spent
FROM totalspent ts
JOIN customers c ON c.customer_id = ts.customer_id
WHERE ts.total_spent > (
    SELECT AVG(total_spent)
    FROM totalspent
);

```