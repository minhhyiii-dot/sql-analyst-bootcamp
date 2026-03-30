## DAY 25 — Retention Logic

**Status:** COMPLETED  
**Time spent:** 1h 17m 31s  
**Level:** 4.5 / 5  

---

### Focus Topic
Retention Logic

---

### Session Notes

- Reused validated paid order logic consistently from Day 24  
- Built monthly retention using customer-month activity grain  
- Built cohort retention curve with correct cohort sizing and month offset logic  
- Built a basic churn snapshot using last active month vs reference month  
- Demonstrated stable control over retention data structure and time logic  

---

### Minhyi Notes

- Monthly retention logic was structurally correct, but retention rate calculation still needed cleaner numeric handling  
- Cohort retention query was the strongest query of the session  
- Churn logic was directionally correct, but still too mechanical and not yet business-rich  
- Need to improve business interpretation after query output, not stop at correct numbers  

---

### Key Lesson

> Retention analysis only works when activity grain, time logic, and metric base are all controlled precisely.

---

### Performance Evaluation

| Area                      | Score |
|--------------------------|------|
| Monthly retention logic  | 4.4  |
| Cohort retention curve   | 4.8  |
| Churn snapshot logic     | 4.2  |
| Overall analytical control | 4.5 |

---

### Critical Weakness

> Technical logic is mostly correct, but business interpretation is still thin.  
> Churn definition is usable but not yet robust enough for deeper analyst work.

---

query: 
**1.Basic Retention (Monthly)**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_fee
),
paid_total AS(
    SELECT
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT 
    ot.order_id,
    ot.order_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(pt.paid_total - ot.order_total) <= 0.01 
),
order_month AS (
    SELECT DISTINCT
        o.customer_id,
        cast(DATE_FORMAT(o.order_date, '%Y-%m-01') AS date) AS order_month
    FROM validated v
    JOIN orders o ON o.order_id = v.order_id
),
retention AS(
    SELECT
    om1.order_month,
    COUNT(DISTINCT om1.customer_id) AS total_users,
    COUNT(DISTINCT om2.customer_id) AS retained_users
    FROM order_month om1
    LEFT JOIN order_month om2
    ON om1.customer_id = om2.customer_id
    AND om2.order_month = date_add(om1.order_month, INTERVAL 1 month)
    GROUP BY  om1.order_month
)
SELECT
r.order_month,
r.retained_users,
r.total_users,
(r.retained_users * 100 / r.total_users) AS retention_rate
FROM retention r
```

**2.Classic Retention Curve**
```sql
WITH order_total AS( 
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.shipping_fee
),
paid_total AS(
    SELECT
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT 
    ot.order_id,
    ot.order_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(pt.paid_total - ot.order_total) <= 0.01 
),
order_month AS(
    SELECT DISTINCT
    o.customer_id,
    cast(date_format(o.order_date, '%Y-%m-01') AS date) AS order_month
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
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
    fp.customer_id,
    fp.cohort_month,
    om.order_month
    FROM first_purchase fp
    JOIN order_month om ON om.customer_id = fp.customer_id
),
retained_customer AS(
    SELECT
    ca.cohort_month,
    ca.order_month,
    COUNT(DISTINCT ca.customer_id) AS retained_user
    FROM cohort_activity ca 
    GROUP BY ca.cohort_month, ca.order_month
),
cohort_size AS(
    SELECT
    fp.cohort_month,
    COUNT(DISTINCT fp.customer_id) AS total_customer
    FROM first_purchase fp 
    GROUP BY fp.cohort_month
)
SELECT
rc.cohort_month,
timestampdiff(
    month,
    rc.cohort_month,
    rc.order_month
) AS month_number,
rc.order_month,
cs.total_customer,
rc.retained_user,
(rc.retained_user * 1.0 / cs.total_customer) * 100 AS retention_rate
FROM retained_customer rc
JOIN cohort_size cs ON rc.cohort_month = cs.cohort_month
ORDER BY rc.cohort_month, month_number
```
**3.Churn Snapshot**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.shipping_fee
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validated AS(
    SELECT
    ot.order_id,
    ot.order_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01 
),
order_month AS(
    SELECT DISTINCT
    o.customer_id,
    cast(date_format(o.order_date, '%Y-%m-01') AS date) AS order_month
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
),
last_active AS(
    SELECT
    om.customer_id,
    MAX(order_month) AS last_active_month
    FROM order_month om
    GROUP BY om.customer_id
),
reference_month AS(
    SELECT
    MAX(om.order_month) AS reference_month
    FROM order_month om 
)
SELECT
la.customer_id,
la.last_active_month,
CASE
WHEN timestampdiff(month, la.last_active_month, rm.reference_month) >= 2 THEN '1'
ELSE '0'
END AS churn_flag
FROM last_active la 
CROSS JOIN reference_month rm
```

