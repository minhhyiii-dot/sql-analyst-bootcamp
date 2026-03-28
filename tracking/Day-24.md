## DAY 24 – COMPLETED

**Time spent:** 3h (day 1) + 2h (day 2)  
**Main topic:** Cohort Analysis

### Task
Build cohort analysis for e-commerce using **first purchase cohort** logic.

### Final metric decision
I originally started from the Day 24 spec: cohort based on first paid purchase.

However, after reviewing the dataset logic more carefully, I decided to tighten the definition into a **validated paid cohort**:

- calculate `order_total` from `order_items`
- calculate `paid_total` from `payments` where `payment_status = 'paid'`
- only keep orders where `ABS(order_total - paid_total) <= 0.01`

So in my final version:

- `cohort_month` = month of the customer's **first validated paid order**
- `order_month` = every month where the customer had a **validated paid order**
- `retention_rate` = active customers in month N / total customers in that cohort

### What I understood
- Cohort analysis is only meaningful if the time logic and purchase definition are trustworthy.
- `signup_date` is not a reliable cohort base in this dataset because time logic can be inconsistent.
- `month_number` must be calculated using real month difference, not `MONTH(order_date)`.
- `cohort_size` must be calculated separately from the first purchase table, not borrowed from month 0 activity.
- The base table grain matters: **1 customer × 1 active month**.

### What I struggled with
- Choosing the right business rule for “paid order”
- Avoiding weak logic like using `orders.status = 'completed'`
- Controlling data grain correctly so `order_id` would not duplicate customer-month activity
- Keeping the metric definition consistent after changing the cohort rule

### Key lesson
**Bad time logic destroys cohort analysis.  
Bad metric definition destroys it even faster.**

### Query I’m most proud of today
The final validated paid cohort retention query below.

#query: 
DAY 24 — COHORT ANALYSIS (FIRST PURCHASE COHORT)

========================
TASK 1 — COHORT BASE TABLE
========================

Requirement:
- cohort = month of first purchase (validated paid order)
- order_month = month of every validated paid order
- each row = 1 customer × 1 active month

SQL:
```sql
WITH calculate_order AS(
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_fee
),
calculate_payment AS(
    SELECT
        p.order_id,
        SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT
        co.order_id
    FROM calculate_order co 
    JOIN calculate_payment cp 
        ON co.order_id = cp.order_id
    WHERE ABS(co.order_total - cp.paid_total) <= 0.01 
),
order_month AS(
    SELECT DISTINCT
        o.customer_id,
        CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE) AS order_month
    FROM validated v 
    JOIN orders o 
        ON v.order_id = o.order_id
),
first_purchase AS(
    SELECT
        om.customer_id,
        MIN(om.order_month) AS cohort_month
    FROM order_month om
    GROUP BY om.customer_id
),
cohort_activity AS(
    SELECT
        om.customer_id,
        fp.cohort_month,
        om.order_month
    FROM order_month om
    JOIN first_purchase fp 
        ON om.customer_id = fp.customer_id
)
SELECT
    customer_id,
    cohort_month,
    order_month
FROM cohort_activity
ORDER BY customer_id, order_month;
```


========================
TASK 2 — ACTIVE CUSTOMERS BY COHORT
========================

Requirement:
- count active customers for each cohort_month × order_month

SQL:
```sql
WITH calculate_order AS(
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_fee
),
calculate_payment AS(
    SELECT
        p.order_id,
        SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT
        co.order_id
    FROM calculate_order co 
    JOIN calculate_payment cp 
        ON co.order_id = cp.order_id
    WHERE ABS(co.order_total - cp.paid_total) <= 0.01 
),
order_month AS(
    SELECT DISTINCT
        o.customer_id,
        CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE) AS order_month
    FROM validated v 
    JOIN orders o 
        ON v.order_id = o.order_id
),
first_purchase AS(
    SELECT
        om.customer_id,
        MIN(om.order_month) AS cohort_month
    FROM order_month om
    GROUP BY om.customer_id
),
cohort_activity AS(
    SELECT
        om.customer_id,
        fp.cohort_month,
        om.order_month
    FROM order_month om
    JOIN first_purchase fp 
        ON om.customer_id = fp.customer_id
)
SELECT
    cohort_month,
    order_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_activity
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;
```

========================
TASK 3 — RETENTION TABLE
========================

Requirement:
- month_number = difference in months between cohort_month and order_month
- retention_rate = active_customers / cohort_size

SQL:
```sql
WITH calculate_order AS(
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_fee
),
calculate_payment AS(
    SELECT
        p.order_id,
        SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT
        co.order_id
    FROM calculate_order co 
    JOIN calculate_payment cp 
        ON co.order_id = cp.order_id
    WHERE ABS(co.order_total - cp.paid_total) <= 0.01 
),
order_month AS(
    SELECT DISTINCT
        o.customer_id,
        CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE) AS order_month
    FROM validated v 
    JOIN orders o 
        ON v.order_id = o.order_id
),
first_purchase AS(
    SELECT
        om.customer_id,
        MIN(om.order_month) AS cohort_month
    FROM order_month om
    GROUP BY om.customer_id
),
cohort_activity AS(
    SELECT
        om.customer_id,
        fp.cohort_month,
        om.order_month
    FROM order_month om
    JOIN first_purchase fp 
        ON om.customer_id = fp.customer_id
),
active_customers AS(
    SELECT
        cohort_month,
        order_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, order_month
),
cohort_size AS(
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT
    ac.cohort_month,
    TIMESTAMPDIFF(MONTH, ac.cohort_month, ac.order_month) AS month_number,
    ac.active_customers * 100.0 / cs.cohort_size AS retention_rate
FROM active_customers ac 
JOIN cohort_size cs 
    ON ac.cohort_month = cs.cohort_month
ORDER BY ac.cohort_month, month_number;
```
