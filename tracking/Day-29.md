## DAY 29 UPDATE

**DAY 29 | COMPLETED | 1h 19m 44s | Level: 4.6/5**

### Focus Topic:
Mock Test 1 — Customer Risk Identification

---

### Session Notes:

- Completed a full analyst-level mock test involving multi-layer metric construction, validation logic, and behavioral filtering.

- Built a complete pipeline:
    • order validation (order_total vs paid_total)  
    • customer-level aggregation (total spending, last order date)  
    • global benchmark (average customer spending)  
    • recency-based risk filtering  

- Demonstrated strong control of data grain, maintaining correct aggregation at customer level throughout the query.

- Identified and corrected a critical aggregation mistake:
    • initially used average order value instead of average customer spending  

- Refactored the query multiple times (4 iterations) to:
    • fix metric definition  
    • align data scope (validated orders only)  
    • simplify structure using window functions  

- Successfully reduced query complexity by moving from multi-CTE structure to a more compact window-function-based solution while preserving logic correctness.

---

### Minhyi Notes:

- Initially confused between average order value vs average customer spending, which led to incorrect filtering logic.

- Realized that a query can be structurally correct but still wrong if the metric definition is incorrect.

- Improved control over:
    • aggregation level  
    • data scope (validated vs all orders)  
    • recency logic based on dataset context instead of system date  

- Attempted query optimization using window functions, but still need deeper understanding of actual performance impact.

---

### Key Lesson:

"Correct aggregation level defines the entire analysis. If the metric is wrong, the whole query is wrong — even if the SQL runs perfectly."

---

### Performance Evaluation:

- SQL logic: 4.7/5  
- Data level control: 4.8/5  
- Query structure: 4.6/5  
- Analytical thinking: 4.5/5  

---

### Critical Weakness:

"Still needs stronger discipline in validating metric definition before building full query. Tends to optimize structure before fully locking business logic."

---

### Session Verdict:

Solid analyst-level session.

Initial mistake was at metric level, but successfully identified and corrected through multiple iterations.

Demonstrates ability to debug thinking, not just SQL syntax.


# query:
```sql
WITH order_total AS(
    SELECT
    o.customer_id,
    o.order_id,
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
    ot.customer_id,
    ot.order_id,
    ot.order_total,
    ot.order_date
    FROM order_total ot 
    JOIN paid_total pt ON ot.order_id = pt.order_id
    WHERE abs(ot.order_total - pt.paid_total) <= 0.01 
),
customer_behavior AS(
    SELECT
    v.customer_id,
    SUM(v.order_total) AS total_spending,
    MAX(v.order_date) AS customer_last_order,
    AVG(SUM(v.order_total)) over() AS avg_spending,
    MAX(MAX(v.order_date)) over() AS last_order_date
    FROM validated v 
    GROUP BY v.customer_id
),
risky_hv_cust AS(
    SELECT
    cb.customer_id,
    cb.total_spending,
    cb.customer_last_order,
    timestampdiff(day, cb.customer_last_order, cb.last_order_date) AS days_number
    FROM customer_behavior cb 
    WHERE cb.total_spending > cb.avg_spending
    AND timestampdiff(day, cb.customer_last_order, cb.last_order_date) >= 60
)
SELECT
customer_id,
total_spending,
customer_last_order AS last_order_date
FROM risky_hv_cust
ORDER BY days_number DESC
```
