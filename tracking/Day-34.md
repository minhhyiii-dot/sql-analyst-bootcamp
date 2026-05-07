# --- DAY 34 UPDATE ---

## DAY 34 | COMPLETED | ~4h | Level: 4.0/5

Focus Topic: Dashboard Planning Logic

#### Session Notes:

- Practiced designing a revenue health dashboard before writing SQL.
- Learned that dashboard planning must start from business questions, not from available charts or complex SQL.
- Defined the dashboard purpose around monitoring ecommerce revenue health and detecting early business risks.
- Identified the key revenue health logic:
  - How much trustworthy revenue did the business generate?
  - Why did revenue change?
  - Where did revenue come from?
  - Who contributed to revenue?
  - Can the reported revenue be trusted?
- Clarified the difference between:
  - Validated Revenue = money metric
  - Revenue-Valid Orders = order volume metric
  - AOV = revenue per valid order
- Understood that Validated Revenue and Revenue-Valid Orders can use the same validated order base but answer different business questions.
- Avoided using discount as a core dashboard metric because the dataset does not contain a direct discount column.
- Avoided using `orders.status = 'completed'` as the revenue source of truth because completed order status does not guarantee correct payment.
- Designed dashboard sections for:
  - Executive Overview
  - Revenue Trend
  - Revenue Mix
  - Customer Risk
  - Payment Quality
 
What I understood:

- A revenue health dashboard should not only show revenue, but also explain why revenue changes.
- Validated Revenue and Revenue-Valid Orders can use the same validation base, but they are different KPIs:
  - Validated Revenue measures money.
  - Revenue-Valid Orders measures order volume.
- AOV is needed to explain whether revenue changes are driven by order count or order value.
- Payment validation is important because raw reported revenue may be unreliable.
- Revenue concentration is a business risk because the company may depend too much on a small group of customers.

What I struggled with:

- I initially confused paid orders, completed orders, and validated orders.
- I also tried to include discount analysis even though discount is not a direct column in the dataset.
- I struggled to understand why dashboard KPIs can share the same base logic but still measure different business concepts.
- I spent too much time on the planning task and did not control the session duration well.

Logic I’m most proud of today:

The strongest logic today was understanding that revenue health should be monitored through a driver framework:

Validated Revenue = Revenue-Valid Orders × AOV

This helps explain whether revenue change is caused by order volume, average order value, or both.

Key Lesson:

A dashboard should be designed from business questions first, not from charts or complex SQL.

A revenue health dashboard must answer:
1. How much trustworthy revenue did we generate?
2. Why did revenue change?
3. Where did revenue come from?
4. Who drives the revenue?
5. Can we trust the revenue data?

Performance Evaluation:

Dashboard purpose: 4.0/5  
KPI definition: 3.8/5  
Dashboard layout: 4.2/5  
Business risk thinking: 4.0/5  
Time control: 2.5/5  

Final Score: 4.0/5

Progress Update:

SQL Maturity Level: ~4.7 / 5  
Current Position: Strong Analyst SQL, improving dashboard and business logic design

Critical Weakness:

Overthinking and weak time control. The dashboard logic improved, but the session took too long for a planning task.

# My work:

Dashboard Purpose:

This dashboard is for business managers to monitor ecommerce revenue health and detect early business risks.

It helps them understand whether validated revenue is stable, increasing, or decreasing, and whether the change is driven by valid order volume, AOV, customer behavior, or product category performance.

It also shows which customer groups, product categories, and cities contribute most to revenue, and helps detect risks such as significant order decline, revenue concentration, and payment quality issues.

KPI List:

1. Validated Revenue

Business question:
How much trustworthy revenue did the business actually generate?

Definition:
SUM(order_total) from orders where calculated order_total matches successful paid_total.

order_total = SUM(order_items.quantity * order_items.unit_price) + orders.shipping_fee  
paid_total = SUM(payments.paid_amount) where payment_status = 'paid'  
Valid condition: ABS(order_total - paid_total) <= 0.01

Grain:
Order level first, then aggregated by month, category, city, or customer.

Source tables:
orders, order_items, payments

Risk / Warning:
If validated revenue declines, the business may have revenue decline risk.
If validated revenue has a large gap compared to reported revenue, reported revenue may be inflated or unreliable.


2. Revenue-Valid Orders

Business question:
How many orders generated financially reliable revenue?

Definition:
Count of orders where calculated order_total matches successful paid_total.

order_total = SUM(order_items.quantity * order_items.unit_price) + orders.shipping_fee  
paid_total = SUM(payments.paid_amount) where payment_status = 'paid'  
Valid condition: ABS(order_total - paid_total) <= 0.01

Grain:
Order level.

Source tables:
orders, order_items, payments

Risk / Warning:
If revenue-valid orders decline while AOV stays stable, revenue decline may be caused by lower order volume or weaker demand.
If raw paid orders are much higher than revenue-valid orders, payment quality issues may be distorting revenue reporting.


3. AOV

Business question:
How much revenue does each valid order generate on average?

Definition:
AOV = Validated Revenue / Revenue-Valid Orders

Grain:
Order level first, then aggregated by dashboard period or dimension.

Source tables:
orders, order_items, payments

Risk / Warning:
If AOV declines while order volume stays stable, customers may be spending less per order or buying lower-value products.
If AOV increases while order volume declines, revenue may depend on fewer but larger orders, which may be less stable.


4. Active Customers

Business question:
How many customers are currently generating valid revenue?

Definition:
Count of distinct customers with at least one revenue-valid order in the last 3 months from the dataset reference date.

Grain:
Customer level.

Source tables:
customers, orders, order_items, payments

Risk / Warning:
If active customers decline, the business may be losing purchasing customers.
If revenue stays stable while active customers decline, revenue may be becoming more concentrated among fewer customers.


5. Revenue Concentration

Business question:
How dependent is the business on a small group of customers?

Definition:
Revenue share contributed by top customers, such as top 10% customers by validated revenue divided by total validated revenue.

Grain:
Customer level first, then aggregated to concentration metric.

Source tables:
customers, orders, order_items, payments

Risk / Warning:
If top customers contribute too much revenue, the business may be exposed to concentration risk.
If a few high-value customers leave, total revenue may drop sharply.


6. Payment Issue Rate

Business question:
What percentage of orders cannot be trusted as valid revenue because of payment problems?

Definition:
Payment Issue Rate = payment_issue_orders / total_orders

payment_issue_orders include:
- orders without successful payment
- orders where paid_total does not match calculated order_total
- orders with missing payment records

Grain:
Order level.

Source tables:
orders, order_items, payments

Risk / Warning:
If payment issue rate increases, revenue reporting may be unreliable.
It may indicate payment processing issues, missing payment records, or mismatch between order value and collected payment.


Dashboard Layout:

Section 1: Executive Overview

Purpose:
Give managers a high-level overview of ecommerce revenue health.

Chart / KPI:
Validated Revenue, Revenue-Valid Orders, AOV, Active Customers, Payment Issue Rate

Breakdown:
Current month vs previous month

Business question:
Is business revenue performance healthy this month?

Risk detected:
Revenue decline, order volume decline, AOV decline, active customer decline, payment issue increase.


Section 2: Revenue Trend

Purpose:
Show how validated revenue changes over the last 12 months and identify the driver of change.

Chart / KPI:
Validated Revenue, Revenue-Valid Orders, AOV, Active Customers

Breakdown:
Month

Business question:
Is revenue going up or down, and is the change driven by order volume, AOV, or customer activity?

Risk detected:
Revenue decline, order volume decline, AOV decline, or revenue growth driven by fewer large orders.


Section 3: Revenue Mix

Purpose:
Show which product categories and customer cities contribute most to validated revenue.

Chart / KPI:
Validated Revenue by category and city

Breakdown:
Category, city, month

Business question:
Where does revenue come from?

Risk detected:
Revenue dependency on one category, one city, or a narrow revenue source.


Section 4: Customer Risk

Purpose:
Detect whether revenue depends too heavily on a small group of customers.

Chart / KPI:
Top customers by validated revenue, top 10% customer revenue share, active customers

Breakdown:
Month

Business question:
Is revenue relying on a small group of customers?

Risk detected:
Customer concentration risk. If a few high-value customers leave, revenue may drop sharply.


Section 5: Payment Quality

Purpose:
Evaluate whether reported revenue is financially reliable.

Chart / KPI:
Raw Revenue, Validated Revenue, Payment Issue Rate, mismatch orders, unpaid/missing payment orders

Breakdown:
Month

Business question:
What percentage of orders have payment issues, and how much does raw revenue differ from validated revenue?

Risk detected:
Revenue reporting may be unreliable because of payment mismatch, missing payments, or invalid revenue records.
