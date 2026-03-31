# Day 26 — Customer Segmentation

**Status:** Completed | **Duration:** 1h 32m 10s | **Level:** 4.5/5

---

## Focus Topic
Customer Segmentation

---

## Session Notes
- Successfully built full customer segmentation pipeline using validated paid order logic.
- Maintained consistent metric definition from Day 24–25 (`order_total` vs `paid_total`).
- Constructed correct customer-level metric table (spending, order count, last activity).
- Applied multi-layer CTE structure: metric layer → segmentation layer → aggregation layer.
- Segmented customers using behavioral dimensions: spending, frequency, and recency.
- Built final segment labels combining multiple behavioral signals into business-readable groups.
- Aggregated segment performance including customer count, total revenue, and average value.
- Demonstrated stable control of data grain (1 row per customer before segmentation).

---

## Self-Review
- Used strict equality (`order_total = paid_total`), which is not robust for real-world data.
- Used `CURRENT_DATE` for recency calculation, making segmentation non-reproducible.
- Some segment labels are correct but not fully precise from a business action perspective.
- Included unnecessary `ORDER BY` inside CTEs, showing minor inefficiency in query structure.

---

## Key Lesson
> "Customer segmentation is only reliable when metric definition, data grain, and time reference are all strictly controlled."

---

## Performance Evaluation

| Dimension | Score |
|---|---|
| SQL Logic | 4.7 / 5 |
| Data Level Control | 4.7 / 5 |
| Query Structure | 4.5 / 5 |
| Business Thinking | 4.2 / 5 |
| **Final Score** | **4.5 / 5** |

**SQL Maturity Level:** ~4.2 / 5 *(Solid Business Analyst Level)*

**Critical Weakness:** Business definition and segmentation quality still lag behind technical SQL execution.

---

## Bootcamp Progress

| | |
|---|---|
| Current Streak | 26 days |
| Progress | Day 26 / 42 |
| Completion | ~62% |
# query:
**Query 1 — Build customer metric table**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
paid_total AS(
    SELECT 
    p.order_id,
    sum(p.paid_amount) AS paid_total
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
last_order AS(
    SELECT
    v.customer_id,
    MAX(order_date) AS last_order_date
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY v.customer_id
),
total_count AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending,
    COUNT(DISTINCT v.order_id) AS total_order
    FROM validated v 
    GROUP BY v.customer_id
)
SELECT
tc.customer_id,
tc.total_spending,
tc.total_order,
lo.last_order_date
FROM total_count tc
JOIN last_order lo ON tc.customer_id = lo.customer_id 
ORDER BY tc.customer_id;
```
**Query 2 — Derive spending, frequency, and recency segments**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
paid_total AS(
    SELECT 
    p.order_id,
    sum(p.paid_amount) AS paid_total
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
last_order AS(
    SELECT
    v.customer_id,
    MAX(order_date) AS last_order_date
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY v.customer_id
),
total_count AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending,
    COUNT(DISTINCT v.order_id) AS total_order
    FROM validated v 
    GROUP BY v.customer_id
),
customer_behavior AS(
SELECT
tc.customer_id,
tc.total_spending,
tc.total_order,
lo.last_order_date
FROM total_count tc
JOIN last_order lo ON tc.customer_id = lo.customer_id 
),
avg_spend AS(
    SELECT 
    AVG(cb.total_spending) AS average_spending
    FROM customer_behavior cb 
)
SELECT
cb.customer_id,
cb.total_spending,
avs.average_spending,
CASE
WHEN cb.total_spending > avs.average_spending THEN 'High'
ELSE 'Low'
END AS spending_segment,
cb.total_order,
CASE 
WHEN cb.total_order >= 3 THEN 'High'
ELSE 'Low'
END AS frequency_segment,
timestampdiff(day, cb.last_order_date, CURRENT_DATE) AS days_number,
CASE
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 30 THEN 'Active'
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 90 THEN 'At Risk'
ELSE 'Churned'
END AS recency_segment
FROM customer_behavior cb
CROSS JOIN avg_spend avs  
ORDER BY cb.customer_id
```
**Query 3 — Create final segment labels**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
paid_total AS(
    SELECT 
    p.order_id,
    sum(p.paid_amount) AS paid_total
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
last_order AS(
    SELECT
    v.customer_id,
    MAX(order_date) AS last_order_date
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY v.customer_id
),
total_count AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending,
    COUNT(DISTINCT v.order_id) AS total_order
    FROM validated v 
    GROUP BY v.customer_id
),
customer_behavior AS(
SELECT
tc.customer_id,
tc.total_spending,
tc.total_order,
lo.last_order_date
FROM total_count tc
JOIN last_order lo ON tc.customer_id = lo.customer_id 
ORDER BY tc.customer_id
),
avg_spend AS(
    SELECT 
    AVG(cb.total_spending) AS average_spending
    FROM customer_behavior cb 
),
customer_segment AS(
SELECT
cb.customer_id,
cb.total_spending,
avs.average_spending,
CASE
WHEN cb.total_spending > avs.average_spending THEN 'High'
ELSE 'Low'
END AS spending_segment,
cb.total_order,
CASE 
WHEN cb.total_order >= 3 THEN 'High'
ELSE 'Low'
END AS frequency_segment,
timestampdiff(day, cb.last_order_date, CURRENT_DATE) AS days_number,
CASE
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 30 THEN 'Active'
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 90 THEN 'At Risk'
ELSE 'Churned'
END AS recency_segment
FROM customer_behavior cb
CROSS JOIN avg_spend avs  
)
SELECT
cs.customer_id,
CASE
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'Active' THEN 'Champion'
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'At Risk' THEN 'Champion At Risk'
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'Churned' THEN 'Lost Champion'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'Active' THEN 'Big Spender'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'At Risk' THEN 'Big Spender At Risk'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'Churned' THEN 'Lost Big Spender'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'Active' THEN 'Loyal'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'At Risk' THEN'Loyal At Risk'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'Churned' THEN 'Lost Loyal'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'Active' THEN 'Occasional'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'At Risk' THEN 'Slipping'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'Churned' THEN 'Lost'
ELSE 'not enough information'
END AS segment_label
FROM customer_segment cs
```
**Query 4 — Aggregate final segment performance**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee,0) AS order_total
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
paid_total AS(
    SELECT 
    p.order_id,
    sum(p.paid_amount) AS paid_total
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
last_order AS(
    SELECT
    v.customer_id,
    MAX(order_date) AS last_order_date
    FROM validated v 
    JOIN orders o ON o.order_id = v.order_id
    GROUP BY v.customer_id
),
total_count AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending,
    COUNT(DISTINCT v.order_id) AS total_order
    FROM validated v 
    GROUP BY v.customer_id
),
customer_behavior AS(
SELECT
tc.customer_id,
tc.total_spending,
tc.total_order,
lo.last_order_date
FROM total_count tc
JOIN last_order lo ON tc.customer_id = lo.customer_id 
),
avg_spend AS(
    SELECT 
    AVG(cb.total_spending) AS average_spending
    FROM customer_behavior cb 
),
customer_segment AS(
SELECT
cb.customer_id,
cb.total_spending,
avs.average_spending,
CASE
WHEN cb.total_spending > avs.average_spending THEN 'High'
ELSE 'Low'
END AS spending_segment,
cb.total_order,
CASE 
WHEN cb.total_order >= 3 THEN 'High'
ELSE 'Low'
END AS frequency_segment,
timestampdiff(day, cb.last_order_date, CURRENT_DATE) AS days_number,
CASE
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 30 THEN 'Active'
WHEN timestampdiff(day, cb.last_order_date, CURRENT_DATE) <= 90 THEN 'At Risk'
ELSE 'Churned'
END AS recency_segment
FROM customer_behavior cb
CROSS JOIN avg_spend avs  
),
segment_label AS(
SELECT
cs.customer_id,
    cs.total_spending,
CASE
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'Active' THEN 'Champion'
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'At Risk' THEN 'Champion At Risk'
WHEN spending_segment = 'High' AND frequency_segment = 'High' AND recency_segment = 'Churned' THEN 'Lost Champion'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'Active' THEN 'Big Spender'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'At Risk' THEN 'Big Spender At Risk'
WHEN spending_segment = 'High' AND frequency_segment = 'Low' AND recency_segment = 'Churned' THEN 'Lost Big Spender'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'Active' THEN 'Loyal'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'At Risk' THEN'Loyal At Risk'
WHEN spending_segment = 'Low' AND frequency_segment = 'High' AND recency_segment = 'Churned' THEN 'Lost Loyal'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'Active' THEN 'Occasional'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'At Risk' THEN 'Slipping'
WHEN spending_segment = 'Low' AND frequency_segment = 'Low' AND recency_segment = 'Churned' THEN 'Lost'
ELSE 'not enough information'
END AS segment_label
FROM customer_segment cs
),
all_segments_label AS (
    SELECT 'Champion' AS segment_label
    UNION ALL SELECT 'Champion At Risk'
    UNION ALL SELECT 'Lost Champion'
    UNION ALL SELECT 'Big Spender'
    UNION ALL SELECT 'Big Spender At Risk'
    UNION ALL SELECT 'Lost Big Spender'
    UNION ALL SELECT 'Loyal'
    UNION ALL SELECT 'Loyal At Risk'
    UNION ALL SELECT 'Lost Loyal'
    UNION ALL SELECT 'Occasional'
    UNION ALL SELECT 'Slipping'
    UNION ALL SELECT 'Lost'
)
SELECT
asl.segment_label,
COUNT(DISTINCT sl.customer_id) AS number_of_customer,
COALESCE(SUM(sl.total_spending),0) AS total_revenue,
COALESCE(AVG(sl.total_spending),0) AS avg_customer_value
FROM all_segments_label asl
LEFT JOIN segment_label sl ON asl.segment_label = sl.segment_label
GROUP BY asl.segment_label
ORDER BY FIELD(asl.segment_label, 'Champion', 'Champion At Risk', 'Lost Champion',
    'Big Spender', 'Big Spender At Risk', 'Lost Big Spender',
    'Loyal', 'Loyal At Risk', 'Lost Loyal',
    'Occasional', 'Slipping', 'Lost')
```
