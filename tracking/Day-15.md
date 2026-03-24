# DAY 15 UPDATE

**DAY 15 | COMPLETED | ~75 minutes | Level: 4.5/5**

## Focus Topic Window Functions — OVER() & PARTITION BY

## Session Notes

- Learned core difference between GROUP BY (collapses rows) and window functions (keeps all rows while computing aggregations).
- Practiced OVER() with no arguments to compute a global total across all rows.
- Applied PARTITION BY to compute per-customer totals without collapsing rows.
- Built a percentage-of-customer-spend column by dividing order total by customer total using the same window function inline.
- Learned that window functions can be repeated directly in SELECT — no CTE required for simple cases.
- Introduced to WINDOW w AS (...) shorthand for reusing window definitions (PostgreSQL, MySQL 8+).

## Minhyi Notes

- Initially wrapped window function in a CTE to compute customer_total, then JOINed back to orders.
- Realized the CTE was unnecessary — window function result can be referenced directly in the same SELECT.
- Gap identified: did not know window functions could be repeated inline in SELECT.

## Key Lesson

"Window functions compute aggregations across related rows without collapsing them — OVER() defines the window, PARTITION BY defines the group."

## Bootcamp Progress Update

Current Streak: 15 Days
Bootcamp Progress: Day 15 / 42
Completion: ~36%

## Query

### Task 1
Task: For each order, display: order_id, customer_id, total_amount, and the total revenue across all orders as a new column on the same row.
```sql
SELECT
    o.order_id,
    o.customer_id,
    o.total_amount,
    SUM(o.total_amount) OVER() AS global_total
FROM orders o

```

### Task 2
Task: For each order, display: order_id, customer_id, total_amount, and the total spending of that customer — without collapsing rows.
```sql
SELECT
    o.order_id,
    o.customer_id,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY o.customer_id) AS total_spending
FROM orders o

```

### Task 3
Task: For each order, calculate what percentage of that customer's total spending this order represents. Required columns: order_id, customer_id, total_amount, customer_total, pct_of_customer_spend.
```sql
SELECT
    o.order_id,
    o.customer_id,
    o.total_amount,
    SUM(o.total_amount) OVER (PARTITION BY o.customer_id) AS customer_total,
    (o.total_amount / SUM(o.total_amount) OVER (PARTITION BY o.customer_id)) * 100 AS pct_of_customer_spend
FROM orders o

```