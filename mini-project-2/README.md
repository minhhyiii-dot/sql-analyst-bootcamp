#  Mini Project 2: Product Performance & Revenue Contribution

##  Objective

This project analyzes product performance within each category to understand how revenue is distributed and to identify potential business risks.

---

##  Business Questions

* Which products generate the highest revenue in each category?
* How much does each product contribute to its category revenue?
* Is revenue concentrated in a few products or evenly distributed?
* Which categories have higher risk due to product dependency?

---

##  Approach

The analysis is built using a 3-layer SQL structure:

* **Layer 1 — Product Revenue**
  Calculate total revenue per product using completed orders only.

* **Layer 2 — Category Revenue**
  Compute total revenue per category using window functions.

* **Layer 3 — Ranking & Contribution**
  Rank products within each category and calculate their contribution percentage.

---

##  SQL File

* `product_performance.sql`
  Contains the full query to generate:

  * Top 3 products per category
  * Product revenue
  * Category revenue
  * Contribution percentage
  * Ranking within category

---

##  Key Insights

* No category is highly dependent on a single product (no product exceeds 50% contribution).
* Some categories (e.g., Category 10, 12) show balanced revenue distribution → lower risk.
* Category 14 has the highest risk due to low total revenue and higher concentration (~34% from top 3 products).
* Category 2 is the strongest category with the highest revenue and stable distribution.

---

##  Business Recommendations

* **Category 14**: Improve product diversity to reduce dependency on top products.
* **Category 2**: Maintain and scale as a key revenue driver.
* **Balanced categories (10, 12)**: Focus on overall category growth.
* **Moderate concentration categories (3, 4, 5, 9)**: Test promoting top products to increase revenue.

---

##  Dataset

This project uses an e-commerce dataset with the following tables:

* `orders`
* `order_items`
* `products`
* `categories`

---

##  How to Use

1. Set up the database using the provided SQL file.
2. Run the query in `product_performance.sql` to reproduce the analysis.

Dataset file:
[ecommerce_db.sql](https://github.com/user-attachments/files/26117482/ecommerce_db.sql)

---

## Skills Demonstrated

* SQL (CTE, Window Functions)
* Data aggregation & data level control
* Business analysis & insight generation
* Translating data into business recommendations

---
