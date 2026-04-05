# Customer Segmentation Using RFM Model (SQL)

## Business Objective

This project aims to segment customers based on purchasing behavior to identify:

* High-value customers to retain
* At-risk customers to recover
* Growth opportunities across segments

---

## Key Data Constraint

Revenue cannot be directly trusted from orders.total_amount.

To ensure accuracy, this project:

* Recalculates order value from order_items
* Validates against payments.paid_amount
* Only includes orders where:

ABS(order_total - paid_total) <= 0.01

---

## RFM Model Definition

* **Recency (R):** Days since last valid purchase
* **Frequency (F):** Number of valid orders
* **Monetary (M):** Total validated spending

---

## Scoring Approach

This project uses PERCENT_RANK() instead of NTILE(5).

### Reason:

* NTILE forces equal-sized groups
* Tied values may be split across buckets
* Results can vary across executions

PERCENT_RANK():

* Preserves behavioral distribution
* Produces more consistent segmentation for this dataset

---

## Customer Segments

* Champion
* VIP
* Loyal
* Big Spender
* Potential Loyalist
* New Customer
* At Risk
* Lost
* General

---

## Output Metrics

Each segment is evaluated by:

* Total customers
* Total orders
* Total revenue
* % customer contribution
* % order contribution
* % revenue contribution

---

## Project Structure

* `rfm_segmentation.sql` → full SQL pipeline
* `rfm_analysis.md` → business insights
* `dataset.md` → data logic & validation rules

---

## Key Takeaway

Customer segmentation is not only about scoring.

The choice of scoring method must reflect:

* data distribution
* business behavior
* analytical objective

This project prioritizes behavioral consistency over forced equal segmentation.
