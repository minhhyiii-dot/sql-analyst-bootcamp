# DAY 18 UPDATE

**DAY 18 | COMPLETED | 1h 05m 20s | Level: 4.4/5**

## Focus Topic PARTITION BY Deep Dive

## Session Notes

- Practiced core PARTITION BY patterns including:
    • percentage contribution within group
    • comparison with group average
    • ranking within group

- Demonstrated strong understanding of window functions without collapsing rows.

- Correctly separated data levels (order level vs order_item level) before applying window functions.

- Successfully avoided join explosion by pre-aggregating order-level data.

- Applied multi-layer query structure when necessary, but also used inline window functions effectively.

- Identified importance of correct data type handling in division operations.

## Minhyi Notes

- Understood how PARTITION BY creates logical groups without affecting row count.

- Realized that incorrect data type handling (integer division) can silently break results.

- Initially overcomplicated Task 2 by using CASE WHEN instead of directly filtering.

- Need to improve reading comprehension of business requirements before writing queries.

## Key Lesson

"PARTITION BY allows group-level analysis without losing row-level detail — but correctness depends on data level control and precise logic."

Performance Evaluation:

Window function understanding: 4.6/5  
Data level control: 4.5/5  
Query correctness: 4.4/5  
Business interpretation: 4.0/5  

Final Score: 4.4/5

Progress Update:

Window Functions: ~65%  
SQL Maturity Level: ~3.6 → 3.7 / 5  

Critical Weakness:

"Still occasionally overcomplicates solutions and misses exact business requirement."

## Query

### TASK 1
```sql
WITH total_order AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS total_order
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.shipping_fee
)
SELECT
    ot.customer_id,
    ot.order_id,
    ot.total_order,
    SUM(ot.total_order) OVER (PARTITION BY ot.customer_id) AS customer_total,
    ot.total_order / SUM(ot.total_order) OVER (PARTITION BY ot.customer_id) * 100 AS pct
FROM total_order ot
ORDER BY ot.customer_id, ot.order_id

```

### TASK 2
```sql
SELECT
    t.*,
    CASE
        WHEN total_amount = avg_spent THEN 'average'
        WHEN total_amount > avg_spent THEN 'above average'
        WHEN total_amount < avg_spent THEN 'under average'
        ELSE 'no information'
    END AS flag
FROM (
    SELECT
        o.customer_id,
        o.order_id,
        o.total_amount,
        AVG(o.total_amount) OVER (PARTITION BY o.customer_id) AS avg_spent
    FROM orders o
) t

```

### TASK 3
```sql
SELECT
    o.order_id,
    o.customer_id,
    oi.product_id,
    (oi.quantity * oi.unit_price) AS product_total,
    SUM(oi.quantity * oi.unit_price) OVER (PARTITION BY oi.order_id) AS order_total,
    (oi.quantity * oi.unit_price) /
    SUM(oi.quantity * oi.unit_price) OVER (PARTITION BY oi.order_id) * 100 AS pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id

quẻy

```