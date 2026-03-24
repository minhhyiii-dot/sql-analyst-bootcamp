# DAY 17 UPDATE

**DAY 17 | COMPLETED | ~60 minutes | Level: 4.4/5**

## Focus Topic RANK() & DENSE_RANK()

## Session Notes

- Practiced ranking functions (RANK, DENSE_RANK) with PARTITION BY across business scenarios.
- Successfully built Top N queries (top customers per city, top products per category).
- Demonstrated correct use of multi-layer aggregation to avoid double counting (order_value → customer_spending).
- Understood key difference between RANK() (with gaps) vs DENSE_RANK() (no gaps).
- Identified business implication of ranking functions when handling ties.

## Minhyi Notes

- Initially made a mistake when combining shipping_fee with aggregated item values, causing potential duplication.
- Fixed by separating order-level and customer-level aggregation.
- Still had confusion in detecting tie scenarios due to incorrect grouping logic.

## Key Lesson

"Ranking functions must be applied on the correct aggregation level, and tie detection requires grouping by the metric — not the entity."

Performance Evaluation:

Window function usage: 4.5/5  
Ranking logic understanding: 4.3/5  
Data level awareness: 4.2/5  
Handling edge cases (tie): 3.8/5  

Final Score: 4.4/5

Progress Update:

Window Functions: ~55%  
SQL Maturity Level: ~3.6 / 5  

Critical Weakness:

"Still weak in detecting ties and grouping by correct analytical dimension."

## Query



Problem: Find top 3 customers by total spending in each city.
```sql
WITH order_value AS (
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS order_value
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id, o.shipping_fee
),
total_spending AS (
    SELECT
        customer_id,
        SUM(order_value) AS total_spending
    FROM order_value
    GROUP BY customer_id
)
SELECT *
FROM (
    SELECT
        c.customer_id,
        c.city,
        ts.total_spending,
        RANK() OVER (
            PARTITION BY c.city 
            ORDER BY ts.total_spending DESC
        ) AS rank
    FROM customers c
    JOIN total_spending ts ON c.customer_id = ts.customer_id
) t
WHERE rank <= 3;

Problem: Find top 3 products by revenue in each category
WITH product_revenue AS (
    SELECT
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS product_revenue
    FROM order_items oi
    GROUP BY oi.product_id
)
SELECT *
FROM (
    SELECT
        p.product_id,
        p.product_name,
        pr.product_revenue,
        p.category_id,
        RANK() OVER (
            PARTITION BY p.category_id
            ORDER BY pr.product_revenue DESC
        ) AS rank
    FROM products p
    JOIN product_revenue pr ON p.product_id = pr.product_id
) t
WHERE rank <= 3

Problem: Find products that have the same revenue within the same category.
WITH product_revenue AS(
    SELECT
    oi.product_id,
    p.category_id,
    SUM(oi.quantity * oi.unit_price) AS product_revenue
    FROM order_items oi 
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY oi.product_id, p.category_id
)
SELECT
pr.category_id,
pr.product_revenue
FROM product_revenue pr 
GROUP BY pr.category_id, pr.product_revenue
HAVING COUNT(*) >= 2

```