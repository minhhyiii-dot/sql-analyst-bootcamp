# Mini Project 1: E-commerce SQL Analysis

This project contains a set of SQL queries to analyze an e-commerce database. The main goal is to find key business insights and check for data consistency.

## Analysis Tasks

This project answers four main business questions:

1.  **Customer Revenue**: Calculates the total money spent by each customer on completed orders.
2.  **Top Products**: Finds the top 5 products that generated the most revenue.
3.  **Payment Validation**: Checks for differences between the calculated order total and the amount paid by the customer. This is important to find underpaid or overpaid orders.
4.  **Above Average Customers**: Lists customers who have spent more than the average of all customers.

## SQL Techniques Used

*   **JOINs**: To combine data from multiple tables (`orders`, `order_items`, `products`, `customers`).
*   **GROUP BY**: To group data for calculations (e.g., total spent per customer).
*   **SUM() & AVG()**: To perform calculations like total revenue and average spending.
*   **Common Table Expressions (CTEs)**: To make complex queries easier to read and manage, especially in the Payment Validation and Above Average Customer tasks.
*   **CASE Statements**: To create conditional logic for the Payment Validation status (e.g., 'correct paid', 'underpaid').

## How to Use

1.  Set up the database using your `ecommerce_db.sql` file.
2.  Run the queries in the `.sql` files to see the results of each analysis.

[ecommerce_db.sql](https://github.com/user-attachments/files/26117482/ecommerce_db.sql)
