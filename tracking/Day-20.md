### --- DAY 20 UPDATE ---

**DAY 20 | COMPLETED | 46 minutes | Level: 4.3/5**

## Focus Topic CTE (Common Table Expression)

## Session Notes

* Practiced structuring multi-layer queries using CTE to separate logical steps clearly.
* Demonstrated ability to convert nested subqueries into cleaner CTE-based structure.
* Applied metric → analysis pattern using CTE (customer_spending → compare with average).
* Practiced combining CTE with window functions for ranking logic (top N per group).
* Improved control over query complexity by breaking logic into manageable layers.
* Identified key difference between scalar aggregation vs window aggregation in CTE design.

## Minhyi Notes

* Initially overused window function for global average, causing unnecessary duplication of values.
* Learned that global metrics should remain scalar instead of being expanded across rows.
* Understood that CTE is mainly for readability and debugging, not performance optimization.
* Still slightly confused when choosing between CTE vs subquery in simple cases.

## Key Lesson

"CTE helps break complex queries into logical steps, allowing better control, readability, and step-by-step debugging."

Performance Evaluation:

CTE usage: 4.5/5
Query structure: 4.3/5
Data level control: 4.6/5
Analytical thinking: 3.8/5

Final Score: 4.3/5

Progress Update:

Window Functions: ~72%
SQL Maturity Level: ~3.9 / 5

Critical Weakness:

"Still occasionally over-engineers simple logic and hesitates between CTE vs subquery."

## Bootcamp Progress Update

Current Streak: 20 Days
Bootcamp Progress: Day 20 / 42
Completion: ~48%

## Query

### Task 1: Customers Above Average Spending
```sql
WITH total_spending AS(
    SELECT
    o.customer_id,
    SUM(o.total_amount) AS total_spending
    FROM orders o 
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
),
average_spending AS(
    SELECT
    AVG(total_spending) AS average
    FROM total_spending ts
)
SELECT
ts.customer_id,
ts.total_spending
FROM total_spending ts
JOIN average_spending avs 
WHERE ts.total_spending > avs.average 

```

### Task 2: Top 2 Customers by Spending in Each City
```sql
WITH customer_spending AS(
    SELECT
    o.customer_id,
    SUM(o.total_amount) AS customer_spending,
    c.city
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id, c.city
),
ranking AS(
    SELECT
    cs.customer_id,
    cs.customer_spending,
    cs.city,
    dense_rank() over(PARTITION BY cs.city ORDER BY cs.customer_spending DESC) AS rank
    FROM customer_spending cs 
)
SELECT
r.* 
FROM ranking r
WHERE rank <= 2

```

### Task 3: Detect Payment Mismatch Orders
```sql
WITH paid_amount AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS paid_amount
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
order_total AS(
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id, o.shipping_fee
)
SELECT 
pa.order_id,
pa.paid_amount,
ot.order_total,
CASE
WHEN pa.paid_amount <> ot.order_total THEN 'mismatch payment'
WHEN pa.paid_amount = ot.order_total then 'correct paid'
ELSE 'error'
END AS flag
FROM paid_amount pa 
LEFT JOIN order_total ot ON pa.order_id = ot.order_id

```