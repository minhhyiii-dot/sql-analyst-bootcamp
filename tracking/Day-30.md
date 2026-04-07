## DAY 30 — COMPLETED

**Time spent:** 55m 54s
**Level:** 4.7 / 5

**Main topic:** Timed SQL Challenge — Customer Risk Segmentation

---

### Session Notes

* Completed a full timed challenge under 60 minutes with strict constraints (no external help).
* Built full validation pipeline:

  * `order_total` (including shipping_fee)
  * `paid_total` (filtered by `payment_status = 'paid'`)
  * validated orders using `ABS(order_total - paid_total) <= 0.01`
* Maintained correct data level separation:

  * order-level aggregation → customer-level aggregation
* Correctly computed `customer_spending` and global average using window function at the correct aggregation level.
* Implemented recency logic using dataset `max_date` instead of system date.
* Built clean segmentation using two dimensions:

  * `value_segment` (high_value vs low_value)
  * `risk_status` (active vs at_risk)
* Avoided join explosion and maintained 1 row per customer in final output.

---

### What I understood

* Average-based threshold is weak:

  * very small differences (e.g. +0.001) still classify as high_value
  * does not reflect true business significance
* Segmentation method ≠ model choice:

  * RFM is not always required
  * rule-based segmentation is valid if defined correctly
* Threshold definition is part of the analysis:

  * percentile / contribution / business rules are stronger than average

---

### What I struggled with

* Choosing a strong and meaningful threshold instead of defaulting to average
* Thinking beyond “query works” → moving toward “logic is meaningful”
* Deciding segmentation structure (flag design vs multiple columns)

---

### Query I’m most proud of today

* Full pipeline from validation → aggregation → segmentation
* Clean separation of data levels
* Correct use of window function for global average
* Final output structured for direct business use (segmentation-ready)

---

### Key Lesson

**Correct SQL is not enough — weak metric definitions lead to weak business conclusions.
Threshold design is part of the analysis, not an afterthought.**

---

### Performance Evaluation

* SQL logic: 4.8 / 5
* Data level control: 4.8 / 5
* Query structure: 4.7 / 5
* Analytical thinking: 4.5 / 5

**Final Score: 4.7 / 5**

---

### Progress Update

* SQL Maturity Level: **~4.4 → 4.5 / 5 (Strong Analyst SQL)**

---

### Critical Weakness

Still relies on convenient thresholds (average) instead of defining business-meaningful segmentation boundaries.

---

### Session Verdict

Strong execution under time pressure.

SQL is stable.
Next bottleneck is decision quality — especially metric thresholds and segmentation logic.


# query:
**Customer Risk Segmentation with Validated Revenue Logic**
```sql
WITH order_total AS(
    SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) + COALESCE(o.shipping_fee, 0) AS order_total 
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id 
    GROUP BY o.order_id, o.customer_id, o.order_date
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
    ot.customer_id,
    ot.order_date,
    ot.order_total
    FROM order_total ot 
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01 
),
customer_behavior AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS customer_spending,
    AVG(SUM(v.order_total)) over() AS average_spending,
    MAX(v.order_date) AS last_order,
    MAX(MAX(v.order_date)) over() AS max_date
    FROM validated v 
    GROUP BY v.customer_id
),
definding AS(
    SELECT
    cb.*,
    CASE
    WHEN customer_spending > average_spending THEN 'high_value'
    ELSE 'low_value'
    END AS value_segment,
    CASE
    WHEN timestampdiff(day, last_order, max_date) < 60 THEN 'active'
    ELSE 'at risk'
    END AS risk_status
    FROM customer_behavior cb
)
SELECT
customer_id,
customer_spending,
last_order,
value_segment,
risk_status
FROM definding
ORDER BY customer_id 

```
