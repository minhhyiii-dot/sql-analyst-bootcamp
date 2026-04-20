# Day 33 | Partial | 2h 46m | Level: 3.9/5

## Focus Topic
Business Case Simulation (Claim Validation & Revenue Diagnosis)

---

## Session Notes

Attempted to analyze a business claim: *"Revenue growth is slowing while order volume remains stable."*

- Correctly challenged the validity of the problem instead of blindly accepting it
- Identified that the dataset (simulation) does not clearly support the stated issue, especially after excluding incomplete month (2026-03)

**Queries built:**
- AOV trend analysis
- Category-level revenue trend (MoM)
- Customer segmentation (RFM-based, later identified as overengineered)
- Payment validation vs raw revenue comparison

**Metric validation consistency:**
- Constructed `order_total` from `order_items`
- Constructed `paid_total` from `payments`
- Applied validation rule: `ABS(order_total - paid_total) <= 0.01`

**SQL logic issues identified during debugging:**
- Aggregation mismatch when mixing order-level and item-level data
- Incorrect `GROUP BY` coverage
- Inconsistent validation conditions across queries

**Major analytical issue recognized:**
- RFM segmentation introduces **look-ahead bias** when used for time-based trend analysis

Made correct decision to stop overengineering and not force a weak business conclusion.

---

## Minhyi Notes

- Main difficulty was not SQL syntax, but controlling logic across multiple layers and aligning queries with the business question
- Overused complex methods (RFM) for a problem that required simpler analysis
- Struggled to maintain consistency in metric definitions across different queries
- Experienced mental overload when combining validation logic, time-based analysis, and segmentation logic simultaneously
- Successfully identified that forcing a root cause without data support is incorrect analyst behavior

---

## Key Lesson

> "An analyst's job is not to answer the question — it is to validate whether the question itself is correct."

---

## Performance Evaluation

| Dimension | Score |
|---|---|
| SQL Logic | 4.3 / 5 |
| Data Level Control | 4.2 / 5 |
| Query Consistency | 3.8 / 5 |
| Business Reasoning | 4.0 / 5 |
| **Final Score** | **3.9 / 5** |

---

## Critical Weakness

> "Loses control when combining multiple analytical layers and tends to overengineer solutions that do not match the business question."

---

## Session Verdict

**Partial.**

Strong analytical instinct (questioning the premise), but execution breaks when complexity increases and solution design is not simplified early.

---

## Next Focus

- Reduce overengineering
- Match method to question
- Maintain strict consistency in metric definitions

# My work:
**Order mismatch?**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi	 ON o.order_id = oi.order_id
    GROUP BY o.order_id
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
    ot.order_id,
    ot.order_total,
    ot.order_date
    FROM order_total ot 
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
after_validated AS(
    SELECT
    date_format(v.order_date, '%Y-%m') AS month,
    COUNT(v.order_id) AS av_orders,
    SUM(v.order_total) AS av_revenue
    FROM validated v
    GROUP BY month
),
before_validated AS(
    SELECT
    date_format(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS bv_orders,
    SUM(order_total) as bv_revenue
    FROM orders o
    JOIN order_total ot ON o.order_id = ot.order_id
    GROUP BY month
)
SELECT
av.month,
av.av_orders,
bv.bv_orders,
bv.bv_orders - av.av_orders AS order_mismatch,
(bv.bv_orders - av.av_orders) * 1.0 / bv.bv_orders * 100 AS mismatch_pct,
av.av_revenue,
bv.bv_revenue,
bv.bv_revenue - av.av_revenue AS diff,
(bv.bv_revenue - av.av_revenue) * 1.0 / bv.bv_revenue * 100 AS diff_pct
FROM after_validated av 
JOIN before_validated bv ON av.month = bv.month
GROUP BY av.month
ORDER BY av.month
```
<img width="975" height="404" alt="image" src="https://github.com/user-attachments/assets/a61a1017-1a29-4ade-8c55-45f7eaf14c97" />
Mismatch rate was stable at ~15–19% across all months with no anomalies detected. Data is reliable enough to proceed with further analysis.

**Customer spending less?**
```sql
WITH order_total AS(
    SELECT 
    o.customer_id, 
    o.order_id,
    o.order_date,
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
    ot.order_id,
    ot.order_date
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01
),
last_order AS(
    SELECT 
    v.customer_id,
    MAX(v.order_date) AS last_order_date
    FROM validated v
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
monthly AS(
    SELECT
    date_format(v.order_date, '%Y-%m') AS month,
    s.RFM_segment,
    SUM(v.order_total) AS revenue
    FROM validated v 
    JOIN segment s ON v.customer_id = s.customer_id
    GROUP BY month, RFM_segment
),
MoM AS(
    SELECT
    month,
    RFM_segment,
    revenue,
    lag(revenue) over(PARTITION BY RFM_segment ORDER BY month) AS prev_revenue
    FROM monthly
)
SELECT
    month,
    ROUND(SUM(CASE WHEN RFM_segment = 'Champion' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Champion,
    ROUND(SUM(CASE WHEN RFM_segment = 'VIP' THEN (revenue - prev_revenue) * 1.0  / prev_revenue * 100 END), 1) AS VIP,
    ROUND(SUM(CASE WHEN RFM_segment = 'Loyal' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Loyal,
    ROUND(SUM(CASE WHEN RFM_segment = 'Big Spender' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Big_Spender,
    ROUND(SUM(CASE WHEN RFM_segment = 'Potential Loyalist'THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Potential_Loyalist,
    ROUND(SUM(CASE WHEN RFM_segment = 'New Customer' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS New_Customer,
    ROUND(SUM(CASE WHEN RFM_segment = 'At Risk' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS At_Risk,
    ROUND(SUM(CASE WHEN RFM_segment = 'Lost' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Lost,
    ROUND(SUM(CASE WHEN RFM_segment = 'General' THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS General
FROM mom
GROUP BY month
ORDER BY month
```
<img width="975" height="398" alt="image" src="https://github.com/user-attachments/assets/9a7d8672-61a9-4134-b2e4-7c24b31b8323" />
No RFM segment showed a consistently declining revenue trend. Month-over-month changes fluctuated randomly across all segments — customer behavior is not the root cause.


**Category declining?**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi	 ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_date
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
    ot.order_id,
    ot.order_total,
    ot.order_date
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE ABS(ot.order_total - pt.paid_total) <= 0.01
),
product AS(
    SELECT
    v.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price
    FROM validated v 
    JOIN order_items oi	 ON v.order_id = oi.order_id
),
category AS(
    SELECT
    p1.*,
    p.category_id
    FROM product p1
    JOIN products p ON p.product_id = p1.product_id
),
monthly AS(
    SELECT
    date_format(v.order_date, '%Y-%m') AS month,
    c.category_id,
    SUM(c.quantity * c.unit_price) AS revenue
    FROM category c 
    JOIN validated v ON c.order_id = v.order_id
    GROUP BY month, c.category_id
),
MoM AS(
    SELECT
    month,
    category_id,
    revenue,
    lag(revenue) over(PARTITION BY category_id ORDER BY month) AS prev_revenue
    FROM monthly
)
SELECT
month,
ROUND(SUM(CASE WHEN category_id = 1 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_1,
ROUND(SUM(CASE WHEN category_id = 2 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_2,
ROUND(SUM(CASE WHEN category_id = 3 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_3,
ROUND(SUM(CASE WHEN category_id = 4 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_4,
ROUND(SUM(CASE WHEN category_id = 5 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_5,
ROUND(SUM(CASE WHEN category_id = 6 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_6,
ROUND(SUM(CASE WHEN category_id = 7 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_7,
ROUND(SUM(CASE WHEN category_id = 8 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_8,
ROUND(SUM(CASE WHEN category_id = 9 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_9,
ROUND(SUM(CASE WHEN category_id = 10 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_10,
ROUND(SUM(CASE WHEN category_id = 11 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_11,
ROUND(SUM(CASE WHEN category_id = 12 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_12,
ROUND(SUM(CASE WHEN category_id = 13 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_13,
ROUND(SUM(CASE WHEN category_id = 14 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_14,
ROUND(SUM(CASE WHEN category_id = 15 THEN (revenue - prev_revenue) * 1.0 / prev_revenue * 100 END), 1) AS Category_15,
SUM(revenue) AS revenue
FROM MoM
GROUP BY month
ORDER BY month
```
<img width="975" height="203" alt="image" src="https://github.com/user-attachments/assets/3d1b6f52-4a43-4108-8180-64556e7c5080" />
No category showed a sustained revenue decline. MoM % for all 15 categories fluctuated without clear direction — product mix shift is not confirmed as the root cause.


**AOV trend?**
WITH order_total AS(
    SELECT
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total
    FROM orders o 
    JOIN order_items oi	 ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.order_date
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
    ot.order_id,
    ot.order_total,
    ot.order_date
    FROM order_total ot
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE ABS(ot.order_total - pt.paid_total) <= 0.01
),
monthly AS(
    SELECT
    date_format(v.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT v.order_id) AS total_orders,
    SUM(v.order_total) AS revenue,
    AVG(v.order_total) AS aov
    FROM validated v
    GROUP BY month
),
MoM AS(
    SELECT
    month,
    total_orders,
    revenue,
    aov,
    LAG(aov) OVER(ORDER BY month) AS prev_aov
    FROM monthly
)
SELECT
month,
total_orders,
revenue,
round(aov, 2) AS aov,
round((aov - prev_aov) * 1.0 / prev_aov * 100, 2) AS pct_diff
FROM MoM
ORDER BY month
<img width="675" height="598" alt="image" src="https://github.com/user-attachments/assets/50129c36-2df2-4543-b9e2-5997d111bdf9" />
AOV ranged between 1,192 and 1,340 with no clear downtrend. Average order value remained stable throughout the observed period.







