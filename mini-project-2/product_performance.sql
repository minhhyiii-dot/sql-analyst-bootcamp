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
