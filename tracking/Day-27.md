## DAY 27 | RFM Model (Recency – Frequency – Monetary)

**Status:** COMPLETED
**Duration:** ~6h (over 3 sessions)
**Level:** 4.3/5

---

### Session Notes

- Successfully built full RFM pipeline using validated paid order logic.
- Maintained strict data integrity from previous sessions (order_total vs paid_total).
- Constructed correct customer-level metric table (recency, frequency, monetary).
- Applied NTILE(5) window functions to create distribution-based RFM scoring.
- Built multi-layer query: metric → scoring → segmentation → aggregation.
- Added percentage contribution metrics (customer %, order %, revenue %) for segment evaluation.
- Demonstrated understanding of difference between rule-based segmentation vs distribution-based RFM.
- Learned that RFM creates 125 possible combinations, but real analyst work is grouping them into meaningful business segments.
- Built final segment groups: Champion, VIP, Loyal, Big Spender, Potential Loyalist, New Customer, At Risk, Lost, General.
- Performed business analysis on segment distribution and contribution.

---

### Minhyi Notes

- Struggled heavily with segment definition due to overlapping conditions and unclear business meaning.
- Initially misunderstood RFM as needing to classify all combinations instead of grouping patterns.
- Took significant time to align scoring logic, segment logic, and business interpretation.
- Experienced difficulty translating technical segmentation into precise business insights.
- Realized that correct SQL does not guarantee correct business conclusions.

---

### Key Lesson

> "RFM is not about scoring customers — it is about understanding behavioral patterns and translating them into actionable business decisions."

---

### Performance Evaluation

| Dimension | Score |
|---|---|
| SQL logic | 4.7 / 5 |
| Data level control | 4.7 / 5 |
| RFM scoring logic | 4.5 / 5 |
| Segmentation quality | 4.0 / 5 |
| Business thinking | 3.9 / 5 |
| **Final Score** | **4.3 / 5** |

---

### Progress Update

**SQL Maturity Level:** ~4.2 → 4.3 / 5

**Critical Weakness:**
> "Still struggles to align segment labels with actual customer behavior and tends to rely on generic business actions instead of data-driven reasoning."

# query:
```sql
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
scoring AS(
    SELECT 
    c.customer_id, 
    r.recency, 
    c.frequency, 
    c.monetary,
    (ntile(5) over(ORDER BY r.recency DESC)) AS r_score,
    (ntile(5) over(ORDER BY c.frequency ASC)) AS f_score,
    (ntile(5) over(ORDER BY c.monetary ASC)) AS m_score
    FROM calculate c
    JOIN recency r ON c.customer_id = r.customer_id
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
```
