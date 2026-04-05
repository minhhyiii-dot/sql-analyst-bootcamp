WITH order_total AS(
    SELECT 
    o.customer_id, 
    o.order_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
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
    ot.order_total, 
    ot.order_id
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
last_order AS(
    SELECT 
    v.customer_id,
    MAX(o.order_date) AS last_order_date
    FROM validated v
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY v.customer_id
),
calculate AS(
    SELECT 
    v.customer_id,
    SUM(v.order_total) AS monetary,
    COUNT(DISTINCT v.order_id) AS frequency
    FROM validated v
    GROUP BY v.customer_id
),
recency AS(
    SELECT 
    lo.customer_id,
    timestampdiff(day, lo.last_order_date, (SELECT MAX(order_date) FROM orders)) AS recency
    FROM last_order lo
),
pct_ranking AS(
    SELECT
    c.customer_id, 
    r.recency, 
    c.frequency, 
    c.monetary,
    percent_rank() over(ORDER BY r.recency DESC) AS pct_recency,
    percent_rank() over(ORDER BY c.frequency ASC) AS pct_frequency,
    percent_rank() over(ORDER BY c.monetary ASC) AS pct_monetary
    FROM calculate c 
    JOIN recency r ON c.customer_id = r.customer_id
),
scoring AS(
    SELECT 
    pr.*,
    CASE 
    WHEN pct_recency <= 0.2 THEN 1
    WHEN pct_recency <= 0.4 THEN 2
    WHEN pct_recency <= 0.6 THEN 3
    WHEN pct_recency <= 0.8 THEN 4
    ELSE 5 
    END AS r_score,
    CASE 
    WHEN pct_frequency <= 0.2 THEN 1
    WHEN pct_frequency <= 0.4 THEN 2
    WHEN pct_frequency <= 0.6 THEN 3
    WHEN pct_frequency <= 0.8 THEN 4
    ELSE 5 
    END AS f_score,
    CASE 
    WHEN pct_monetary <= 0.2 THEN 1
    WHEN pct_monetary <= 0.4 THEN 2
    WHEN pct_monetary <= 0.6 THEN 3
    WHEN pct_monetary <= 0.8 THEN 4
    ELSE 5 
    END AS m_score
    FROM pct_ranking pr
),
segment AS(
SELECT
s.*,
SUM(s.frequency) OVER() AS all_order,
SUM(s.monetary) OVER() AS all_revenue,
COUNT(s.customer_id) OVER() AS all_customer,
CASE
WHEN r_score = 5 AND f_score = 5 AND m_score = 5 THEN 'Champion'
WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
WHEN f_score >= 4 AND m_score >= 4 THEN 'Loyal'
WHEN m_score >= 4 THEN 'Big Spender'
WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalist'
WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
ELSE 'General'
END AS RFM_segment
FROM scoring s
),
all_segment AS(
    SELECT 'Champion' AS RFM_segment UNION ALL
    SELECT 'VIP' UNION ALL
    SELECT 'Loyal' UNION ALL
    SELECT 'Big Spender' UNION ALL
    SELECT 'Potential Loyalist' UNION ALL
    SELECT 'New Customer' UNION ALL
    SELECT 'At Risk' UNION ALL
    SELECT 'Lost' UNION ALL
    SELECT 'General'
)
SELECT
    als.RFM_segment,
    COUNT(DISTINCT s.customer_id) AS total_customer,
    SUM(s.frequency) AS total_order,
    SUM(s.monetary) AS total_revenue,
    (COUNT(DISTINCT s.customer_id) * 1.0 / s.all_customer) * 100 AS pct_customer,
    (SUM(s.frequency) * 1.0 / s.all_order) * 100 AS pct_orders,
    (SUM(s.monetary) * 1.0 / s.all_revenue) * 100 AS pct_revenue
FROM all_segment als
LEFT JOIN segment s ON s.RFM_segment = als.RFM_segment
GROUP BY als.RFM_segment
ORDER BY FIELD(als.RFM_segment, 'Champion', 'VIP', 'Loyal', 'Big Spender', 'Potential Loyalist','New Customer','At Risk', 'Lost', 'General')
