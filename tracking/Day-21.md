# DAY 21 UPDATE

**DAY 21 | COMPLETED | 2h | Level: 4.2/5**

## Focus Topic Project 3 — Product Performance & Revenue Contribution

## Session Notes

- Successfully built a multi-layer query using CTE and window functions to analyze product performance within each category.
- Correctly structured the logic: product-level revenue → category-level aggregation → ranking and contribution analysis.
- Demonstrated strong control of data level by aggregating before applying window functions.
- Calculated contribution percentage and ranking within category accurately.
- Avoided common pitfalls such as join explosion and mixing aggregation levels.

- Performed basic business analysis on revenue distribution across categories.
- Identified differences between concentrated vs evenly distributed categories.
- Detected risk levels based on revenue concentration and category size.

## Minhyi Notes

- Query structure is now stable, even with multiple layers.
- Still weak in turning numbers into strong business insights.
- Tendency to describe data instead of explaining its meaning.
- Need to improve depth of reasoning and business interpretation.

## Key Lesson

"Writing correct SQL is not enough — real value comes from interpreting what the numbers mean for the business."

Performance Evaluation:

Query structure: 4.7/5  
Data level control: 4.7/5  
Window function usage: 4.6/5  
Business insight: 3.8/5  

Final Score: 4.2/5

Progress Update:

Window Functions: ~78%  
SQL Maturity Level: ~4.0 / 5 (Entering Advanced SQL)

Critical Weakness:

"Can build correct queries, but insight is still surface-level and not fully business-driven."

## Bootcamp Progress Update

Current Streak: 21 Days  
Bootcamp Progress: Day 21 / 42  
Completion: ~50%

## Query
Identify top-performing products within each category and evaluate their contribution to total revenue
```sql
WITH product_revenue AS(
    SELECT
    oi.product_id,
    p.product_name,
    p.category_id,
    SUM(oi.quantity * oi.unit_price) AS product_revenue
    FROM order_items oi 
    JOIN orders o ON o.order_id = oi.order_id 
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY oi.product_id, p.product_name, p.category_id
),
rank_and_totalrev AS(
    SELECT
    pr.*,
    SUM(pr.product_revenue) over(PARTITION BY pr.category_id) AS category_revenue,
    rank() over(PARTITION BY pr.category_id ORDER BY pr.product_revenue DESC) AS rank_in_category
    FROM product_revenue pr 
)
SELECT
cate.category_name,
r.product_id,
r.product_name,
r.product_revenue,
r.category_revenue,
r.product_revenue * 1.0 / r.category_revenue * 100 AS contribution_pct,
r.rank_in_category
FROM rank_and_totalrev r 
JOIN categories cate on cate.category_id = r.category_id
WHERE r.rank_in_category <= 3
ORDER BY cate.category_name, r.rank_in_category ASC

```