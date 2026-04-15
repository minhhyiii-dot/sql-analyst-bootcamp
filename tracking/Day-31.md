# --- DAY 31 UPDATE ---

DAY 31 | COMPLETED | Time: not recorded | Level: 4.7/5

Focus Topic: Debug & Refactor Session

Session Notes:

- Practiced identifying silent logic errors in SQL queries that still execute but produce incorrect results.
- Reinforced understanding of join explosion caused by combining multiple 1-to-many relationships before aggregation.
- Correctly distinguished between different metric definitions:
    • average order value (AVG)
    • total customer spending (SUM)
- Improved ability to detect when SQL output does not match intended business meaning.
- Practiced refactoring queries using proper aggregation layers (order-level → customer-level).
- Applied defensive data validation:
    • filtered payment_status = 'paid'
    • handled missing payment cases using LEFT JOIN
- Replaced weak average-based segmentation with percentile-based segmentation using PERCENT_RANK().
- Strengthened ability to separate:
    • query logic correctness
    • business logic correctness

Minhyi Notes:

- Initially focused too much on rewriting queries instead of clearly identifying the exact logical failure.
- Missed critical data validation condition (payment_status) in early attempt.
- Improved after correction by applying defensive aggregation logic.
- Still need to improve precision in explanation (e.g., “duplicate” vs “row multiplication”).
- Business explanation sometimes mixes concepts (frequency vs monetary distribution).

Key Lesson:

"A query that runs is not necessarily correct. Analysts must validate both the logic and the data assumptions behind every metric."

Performance Evaluation:

Debugging accuracy: 4.6/5  
Data validation awareness: 4.7/5  
Query refactoring: 4.8/5  
Business reasoning: 4.5/5  

Final Score: 4.7/5

Progress Update:

SQL Maturity Level: ~4.6 / 5 (Strong Analyst SQL)

Critical Weakness:

"Still needs higher precision in explanation and more consistent defensive thinking when handling real-world data conditions."

# My work:

## TASK 1 — CLASSIC JOIN EXPLOSION

### Broken Query:
```sql
SELECT 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) AS item_total,
    SUM(p.paid_amount) AS paid_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY o.order_id;
````

### Problem:

Duplicated

### Why it breaks:

lets clarify it by an example, if an order have 2 or more item, in the first join with order item this order id will appear in 2 row. But if this order have 2 or more payment, when we join it again with this table, the total order id will duplicate 2 x 2 = 4 row, this will double the total payment of this order

### Fix:

```sql
WITH item_total AS(
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS item_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id
)

SELECT
it.order_id,
it.item_total,
SUM(p.paid_amount) AS paid_total
FROM item_total it 
JOIN payments p ON p.order_id = it.order_id
WHERE p.payment_status = 'paid'
GROUP BY it.order_id;
```

---

## TASK 2 — WRONG METRIC DEFINITION

### Broken Query:

```sql
SELECT 
    customer_id,
    AVG(total_amount) AS avg_spending
FROM orders
GROUP BY customer_id;
```

### Explanation:

If the question is ‘average spending per order by customer’ then the query is right

But if the question is 'customer spending’ then the query is wrong because it use AVG instead of SUM

### Fix:

```sql
WITH paid_total AS(
    SELECT
    p.order_id,
    SUM(p.paid_amount) AS paid_total
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
)

SELECT
o.customer_id,
SUM(pt.paid_total) AS total_spending
FROM orders o 
JOIN paid_total pt ON o.order_id = pt.order_id
GROUP BY o.customer_id;
```

---

## TASK 3 — SILENT BUSINESS BUG

### Broken Query:

```sql
SELECT 
    customer_id,
    CASE 
        WHEN SUM(total_amount) > AVG(SUM(total_amount)) OVER () THEN 'high_value'
        ELSE 'low_value'
    END AS segment
FROM orders
GROUP BY customer_id;
```

### Explanation:

Using average to segmentation is weak bacause it can easily break by the high spender (not visit much but each times they come they spend a lot)

### Fix:

```sql
WITH order_total AS(
    SELECT
    o.customer_id,
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id 
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

validated AS(
    SELECT
    ot.customer_id,
    ot.order_id,
    ot.order_total
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id 
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01 
),

total_spending AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending
    FROM validated v 
    GROUP BY v.customer_id
),

scoring AS(
    SELECT
    ts.customer_id,
    ts.total_spending,
    percent_rank() over(ORDER BY ts.total_spending) AS score
    FROM total_spending ts 
)

SELECT
s.customer_id,
s.total_spending,
CASE 
WHEN s.score >= 0.8 THEN 'high value'
WHEN s.score >= 0.4 THEN 'mid value'
ELSE 'low value'
END AS segment
FROM scoring s
ORDER BY s.customer_id;
```

---

## TASK 4 — DATA VALIDATION FAILURE

### Broken Query:

```sql
SELECT 
    o.order_id,
    o.total_amount,
    SUM(p.paid_amount) AS paid_total
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
GROUP BY o.order_id;
```

### Explanation:

Wrong validation

We should trust the quantity * unit price + shipping fee  than the total amount

### Fix:

```sql
WITH order_total AS(
    SELECT
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id 
    GROUP BY o.order_id
)

SELECT
ot.order_id,
ot.order_total,
SUM(
    CASE
    WHEN p.payment_status = 'paid' THEN p.paid_amount
    ELSE 0
    END
) AS total_paid
FROM order_total ot 
LEFT JOIN payments p ON p.order_id = ot.order_id 
GROUP BY ot.order_id, ot.order_total;
```
