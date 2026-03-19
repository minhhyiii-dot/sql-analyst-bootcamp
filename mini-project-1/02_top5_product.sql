SELECT
oi.product_id,
p.product_name,
SUM(oi.quantity * oi.unit_price) AS prod_revenue
FROM order_items oi 
JOIN products p ON p.product_id = oi.product_id
GROUP BY oi.product_id
ORDER BY prod_revenue DESC
LIMIT 5
