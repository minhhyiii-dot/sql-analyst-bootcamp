SELECT
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) AS total_spent
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY o.customer_id;
