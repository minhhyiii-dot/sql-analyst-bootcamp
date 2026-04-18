# DAY 32 | COMPLETED | 1h 34m 50s | Level: 4.4/5

**Focus Topic:** Query Optimization

---

## Session Notes

- Practiced comparing early vs late filtering and understood why filtering conditions should be applied as early as possible to reduce row scans.
- Identified that joining multiple 1-to-many tables before aggregation causes row multiplication, increasing both computation cost and risk of incorrect aggregation results.
- Reinforced importance of aggregating at the correct data level (order-level before joining).
- Improved understanding of how `SELECT *` increases unnecessary data movement and affects performance.
- Learned that applying functions like `YEAR()` on indexed columns prevents efficient index usage and leads to full scans.
- Practiced restructuring queries using CTEs to separate logic layers (`order_total`, `paid_total`, validation).
- Identified need to use `LEFT JOIN` + `COALESCE` when validating payments to correctly handle missing payment cases.
- Understood that optimization is not only about performance but also about preserving correct business logic and data scope.
- Recognized that changing JOIN type (`LEFT` vs `INNER`) can silently change business meaning if population definition is not explicitly stated.

---

## Minhyi Notes

- Initially focused only on join explosion as performance issue, but learned it also affects correctness of aggregation.
- Missed NULL handling in payment validation logic and corrected using `COALESCE`.
- Realized that optimization decisions must always be tied to clear business definitions (e.g., population scope in Top N queries).
- Made a mistake by over-applying validation logic to a simple query, showing lack of context control.
- Improved awareness of when to use `EXISTS` vs `JOIN` depending on whether row expansion is needed.

---

## Key Lesson

> "Query optimization is not just about making queries faster — it is about controlling data flow, minimizing unnecessary work, and ensuring that performance improvements do not break business logic."

---

## Performance Evaluation

| Dimension | Score |
|---|---|
| Optimization thinking | 4.4 / 5 |
| Data level control | 4.5 / 5 |
| Query correctness | 4.3 / 5 |
| Business awareness | 4.4 / 5 |
| **Final Score** | **4.4 / 5** |

---

## Progress Update

**SQL Maturity Level:** ~4.6 → 4.7 / 5 *(Strong Analyst SQL)*

**Critical Weakness:**
> "Still occasionally misses edge cases (NULL handling, population definition) and needs to improve precision when optimizing queries without changing business meaning."

---

# My work & Query:
TASK 1: Early vs Late Filtering

Requirement:
Total revenue of paid orders in 2025.
You MUST write 2 versions:

Version A (bad):

join everything first
filter at the end

Version B (optimized):

filter orders early
filter payments early
then join

👉 Then answer:

Which scans more rows?
Why?

My work:
```sql
-- Version A:
SELECT
*,
SUM(total_order) AS total_revenue_2025
FROM (
    SELECT
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS total_order,
    SUM(p.paid_amount) AS paid_total
    FROM orders o 
    JOIN order_items oi	 ON o.order_id = oi.order_id
    JOIN payments p ON o.order_id = p.order_id
    WHERE p.payment_status = 'paid'
    GROUP BY o.order_id
    HAVING abs(total_order - paid_total) <= 0.01 
) t 
WHERE year(order_date) = 2025
```
```sql
-- Version B:
WITH order_total AS(
    SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.order_date
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
    ot.customer_id,
    ot.order_id,
    ot.order_total,
    ot.order_date
    FROM order_total ot 
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
)
SELECT
SUM(v.order_total) AS total_revenue_2025
FROM validated v 
WHERE v.order_date < '2026-01-01'
AND v.order_date >= '2025-01-01'
```
Explanation:

- Version A join two 1-to-many tables before aggregation, increase the number of row that system need to process.
- Select * increase unnecessary data movement
- year() function delay data filtering and index is not support this function
- Also join explosion duplicate the paid_total, so the condition will execute almost order even though they are still qualified


--------------------------------------------------

TASK 2: Aggregation Placement (Mismatch Detection)

Requirement:
Business question:
Find orders where:
SUM(order_items) != SUM(payments)

Constraints:
- Must avoid double counting
- Must be production-safe


```sql
WITH order_total AS (
    SELECT
        o.order_id,
        SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id
),
paid_total AS (
    SELECT
        p.order_id,
        SUM(p.paid_amount) AS paid_total
    FROM payments p
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
)
SELECT
    ot.order_id,
    ot.order_total,
    COALESCE(pt.paid_total, 0) AS paid_total
FROM order_total ot
LEFT JOIN paid_total pt
    ON ot.order_id = pt.order_id
WHERE ABS(ot.order_total - COALESCE(pt.paid_total, 0)) > 0.01

Key fix:
- LEFT JOIN to keep orders without payment
- COALESCE to handle NULL payment
- tolerance instead of strict inequality
```

--------------------------------------------------

TASK 3: Column Discipline

Requirement:
Take any query you wrote before (Day 29–31).

Rewrite it with:
- NO SELECT *
- ONLY necessary columns
- Remove unused joins


My work:
```sql
WITH total_spending AS(
    SELECT
    o.customer_id,
    COALESCE(SUM(p.paid_amount), 0) AS total_spending
    FROM orders o 
    JOIN payments p ON o.order_id = p.order_id
    WHERE p.payment_status = 'paid'
    GROUP BY o.customer_id
),
ranking AS(
    SELECT
    ts.customer_id,
    ts.total_spending,
    c.city,
    dense_rank() over(PARTITION BY c.city ORDER BY ts.total_spending DESC) AS rn
    FROM customers c 
    JOIN total_spending ts ON c.customer_id = ts.customer_id
)
SELECT
r.city,
r.customer_id,
r.total_spending,
r.rn
FROM ranking r
WHERE rn <= 3
ORDER BY r.city, r.rn

Clarification:
- This version ranks only customers with paid spending
- Customers with no payment are excluded intentionally
- Valid if business definition = “Top 3 paying customers per city”
```

--------------------------------------------------

TASK 4: Detect Optimization Mistake

Bad query:
```sql
SELECT *
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2023
```
Issues:
- SELECT * increases unnecessary data movement
- YEAR() prevents index usage (non-sargable)
- system must compute YEAR() for every row before filtering
- join expands rows (order → multiple order_items)

Fixed query:
```sql
SELECT
    o.order_id
    -- and what the requirement include 
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_date >= '2025-01-01'
  AND o.order_date < '2026-01-01'
  AND o.order_date < '2026-01-01'
```
