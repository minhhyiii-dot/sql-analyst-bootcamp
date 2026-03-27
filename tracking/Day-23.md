# DAY 23 | Revenue Breakdown Analysis

### Overview
- Duration: ~3h
- Difficulty Level: 4.3 / 5.0
- Bootcamp Progress: Day 23 / 42 (55%)
- Current Streak: 23 Days
- Current SQL Maturity Level: ~4.1 / 5.0 (Transitioning to Business Analyst Thinking)

---

### Key Achievements

#### 1. Technical & Query Structure
- Production-Safe Logic: Validated revenue based on actual payment data (Single Source of Truth).
- Advanced Query Architecture: Applied multi-layer Common Table Expressions (CTEs) to maintain clean data scoping.
- Multi-Dimensional Breakdown: Sliced revenue across Category, City, and Time dimensions.

#### 2. Business Intelligence & Risk Analysis
- Metric Decomposition: Broke down Revenue into its core drivers: $\text{Revenue} = \text{Orders} \times \text{Average Order Value (AOV)}$.
- Customer Concentration Risk: Analyzed Pareto-like effects (Top 10% customer contribution and Top 5 dependency risk).

---

### Critical Weaknesses & Notes

- Logic Edge-cases: Still occasionally relied on order status ('completed') instead of strictly checking payment validation.
- Output vs. Insight: Tendency to stop at getting the query output rather than pushing for the business implication.

> Key Lesson Learned:
> "Revenue must be decomposed into its drivers (Orders and AOV) to understand the true underlying business performance."

---

### Performance Evaluation

| Category | Score |
| :--- | :---: |
| SQL Logic | 4.7 / 5.0 |
| Data Level Control | 4.6 / 5.0 |
| Query Structure | 4.5 / 5.0 |
| Business Thinking | 4.3 / 5.0 |
| **Final Session Score** | **4.3 / 5.0** |

# query: 
**Task 1 – Real Revenue**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi on 	o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validation AS(
    SELECT
    ot.order_id,
    ot.order_total,
    pt.paid_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
)
SELECT 
SUM(v.paid_total) AS real_revenue
FROM validation v
```
**Task 2 – Revenue by Category**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi on 	o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validations AS(
    SELECT
    ot.order_id
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
product_revenue AS(
    SELECT
    oi.product_id,
    SUM(oi.quantity * oi.unit_price) AS product_revenue
    FROM validations v 
    JOIN order_items oi ON oi.order_id = v.order_id
    GROUP BY oi.product_id
)
SELECT 
c.category_name,
SUM(pr.product_revenue) AS category_revenue
FROM product_revenue pr 
JOIN products pro ON pr.product_id = pro.product_id
JOIN categories c ON c.category_id = pro.category_id
GROUP BY pro.category_id
```
**Task 3 – Revenue by City**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi on 	o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validations AS(
    SELECT
    ot.order_id,
    pt.paid_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
customer_revenue AS(
    SELECT
    o.customer_id,
    SUM(v.paid_total) AS customer_revenue
    FROM validations v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY o.customer_id
)
SELECT
c.city,
SUM(cr.customer_revenue) AS city_revenue
FROM customer_revenue cr 
JOIN customers c ON c.customer_id = cr.customer_id
GROUP BY c.city
ORDER BY city_revenue DESC
```
**Task 4 – Revenue Breakdown (Time + Orders + AOV)**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o JOIN order_items oi on o.order_id = oi.order_id 
    WHERE o.status = 'completed' GROUP BY o.order_id 
), 
paid_total AS( 
    SELECT 
    p.order_id, 
    SUM(p.paid_amount) AS paid_total 
    FROM payments p WHERE p.payment_status = 'paid' 
    GROUP BY p.order_id 
), 
validations AS( 
    SELECT 
    ot.order_id, 
    pt.paid_total 
    FROM order_total ot 
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01 
)
SELECT 
DATE_FORMAT(o.order_date, '%Y-%m') AS year_months, 
SUM(v.paid_total) AS monthly_revenue,
COUNT(DISTINCT v.order_id) AS total_order,
SUM(v.paid_total) / COUNT(DISTINCT v.order_id) AS AOV
FROM validations v 
JOIN orders o ON o.order_id = v.order_id 
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
```
**Task 5 – Top 10% Contribution**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi on 	o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validations AS(
    SELECT
    ot.order_id,
    pt.paid_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
customer_revenue AS(
    SELECT
    o.customer_id,
    SUM(v.paid_total) AS customer_revenue
    FROM validations v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY o.customer_id
),
pct AS(
SELECT
cr.customer_id,
c.full_name,
cr.customer_revenue,
SUM(cr.customer_revenue) over() AS total_revenue,
cr.customer_revenue * 1.0 / SUM(cr.customer_revenue) over() * 100 AS contribute_pct
FROM customer_revenue cr 
JOIN customers c ON c.customer_id = cr.customer_id
),
rank AS(
    SELECT
    pct.*,
row_number() over(ORDER BY pct.customer_revenue DESC) AS rank,
    COUNT(*) over() AS total_customer
FROM pct
)
SELECT 
SUM(contribute_pct) AS top_contribute
FROM rank
WHERE rank <= total_customer * 1.0 / 10
```
**Task 6 – Top 5 Risk**
```sql
WITH order_total AS(
    SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi on 	o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id
),
paid_total AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
validations AS(
    SELECT
    ot.order_id,
    pt.paid_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
customer_revenue AS(
    SELECT
    o.customer_id,
    SUM(v.paid_total) AS customer_revenue
    FROM validations v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY o.customer_id
),
pct AS(
SELECT
cr.customer_id,
c.full_name,
cr.customer_revenue,
SUM(cr.customer_revenue) over() AS total_revenue,
cr.customer_revenue * 1.0 / SUM(cr.customer_revenue) over() * 100 AS contribute_pct
FROM customer_revenue cr 
JOIN customers c ON c.customer_id = cr.customer_id
),
rank AS(
    SELECT
    pct.*,
row_number() over(ORDER BY pct.customer_revenue DESC) AS rank,
    COUNT(*) over() AS total_customer
FROM pct
)
SELECT 
SUM(contribute_pct) AS pct_lost
FROM rank
WHERE rank <= 5
```
