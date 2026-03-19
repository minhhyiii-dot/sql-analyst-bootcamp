WITH totalpaid AS(
    SELECT 
    p.order_id,
    SUM(p.paid_amount) AS total_paid
    FROM payments p 
    WHERE p.payment_status = 'paid'
    GROUP BY p.order_id
),
calcamount AS(
    SELECT
    oi.order_id,
    SUM(oi.quantity * oi.unit_price) + o.shipping_fee AS calculated_amount
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY oi.order_id
)
SELECT
ca.order_id,
ca.calculated_amount,
tp.total_paid,
CASE
WHEN tp.total_paid IS NULL THEN 'no payment record'
WHEN tp.total_paid = 0 THEN 'not paid'
WHEN ca.calculated_amount = tp.total_paid THEN 'correct paid'
WHEN ca.calculated_amount > tp.total_paid THEN 'underpaid'
WHEN ca.calculated_amount < tp.total_paid THEN 'overpaid'
ELSE 'other'
END AS payment_validation
FROM calcamount ca  
LEFT JOIN totalpaid tp ON tp.order_id = ca.order_id;
