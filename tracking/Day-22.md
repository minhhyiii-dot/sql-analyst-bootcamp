## --- DAY 22 UPDATE ---

**DAY 22 | COMPLETED | 1h 19m 04s | Level: 3.8/5**

**Focus Topic:** KPI Design

### Session Notes:
- Defined 4 business KPIs across Revenue, Customer, and Operations dimensions.
- Correctly identified the difference between Gross Revenue (GMV) and Real Revenue (paid orders).
- Recognized that order status = 'completed' is insufficient without validating against the payments table.
- Performed KPI breakdown across Category, City, Time, and Customer Segment dimensions.
- Identified that Gross Revenue is a misleading KPI when not cross-checked with Real Revenue.

### Minhyi Notes:
- Incorrectly defined "Total Customer Order" as a KPI when it is an intermediate metric.
- Designed the "Returning Customer" KPI based on a discount scenario that does not exist in the dataset.
- SQL syntax for cancellation rate was incorrect (used WHERE instead of CASE WHEN).
- Confused "Sale by Day" (a dimension breakdown) with a standalone KPI.
- Mentioned discount as a cause of revenue gap despite dataset having no discount data.

### Key Lesson:
> "Before defining a KPI, ask: which table, which column, is it queryable? If not --- the KPI does not exist."

### Performance Evaluation:
- KPI definition quality: 3.5/5
- Business grounding: 3.2/5
- KPI breakdown: 4.0/5
- Analytical thinking: 4.2/5
- **Final Score: 3.8/5**

### Progress Update:
- SQL Maturity Level: ~4.0 / 5
- **Critical Weakness:** "Tends to design KPIs outside the dataset scope. Must validate every KPI against actual available data before defining it."

### Bootcamp Progress Update:
- Current Streak: 22 Days
- Bootcamp Progress: Day 22 / 42
- Completion: ~52%


# assignment
## TASK 1 — Define KPIs
**KPI Name: Gross Revenue**
- Definition: Total value of all items sold, regardless of order status
- Why it matters: Measures overall business volume, but does not reflect actual collected money
- SQL logic idea: SUM(quantity * unit_price)

**KPI Name: Real Revenue**
- Definition: Total revenue from successfully paid orders
- Why it matters: Reflects the actual money collected by the business
- SQL logic idea: SUM(quantity * unit_price)
- JOIN payments WHERE payment_status = 'paid'

**KPI Name: Average Orders per Customer**
- Definition: Average number of orders placed per customer
- Why it matters: Measures purchase frequency — a higher value indicates a more engaged customer base
- SQL logic idea: COUNT(order_id) / COUNT(DISTINCT customer_id)

**KPI Name: Returning Customer Rate** 
-Definition: Percentage of customers who placed more than 1 order
- Why it matters: Measures customer retention and loyalty
- SQL logic idea: COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*)

**KPI Name: Order Cancellation Rate**
- Definition: Percentage of orders that were cancelled
- Why it matters: Helps identify which categories or customer segments have the highest cancellation rate, enabling targeted solutions
- SQL logic idea: COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*)

## TASK 2 — KPI Breakdown
**KPI Name: Real Revenue**

- Category: Which category generates the most revenue
- City: Which city generates the most revenue
- Time: Revenue by day, week, month, quarter, and year
- Customer Segment: High-value vs low-value customers — what percentage of revenue comes from the top 20%?

## TASK 3 — Dangerous Thinking
**KPI Name: Gross Revenue**

**Why it is misleading:**
Gross Revenue includes revenue from cancelled and refunded orders,
which means it does not reflect the actual money collected by the business.
It inflates the perceived business scale and should always be
cross-checked against Real Revenue.

