WITH totalspent AS(
    SELECT
    o.customer_id,
    SUM(o.total_amount) AS total_spent
    FROM orders o 
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
)
SELECT
ts.customer_id,
c.full_name,
ts.total_spent
FROM totalspent ts
JOIN customers c ON c.customer_id = ts.customer_id
WHERE ts.total_spent > (
    SELECT AVG(total_spent)
    FROM totalspent
)
