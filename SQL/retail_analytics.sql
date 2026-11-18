
/*
====================================================
PROJECT: RETAIL ANALYTICS
AUTHOR: Tushar Sathe
DATABASE: retail_sales_analytics
TOOL: PostgreSQL / pgAdmin 4

OBJECTIVES:
1. Data Exploration
2. Data Cleaning
3. Business KPI Analysis
4. Sales Analysis
5. Product Analysis
6. Customer Analysis
7. Regional Analysis
8. Discount Analysis
9. Business Reporting

TOTAL: 30 SIMPLE SQL QUERIES
====================================================
*/


/* ================================================
   PHASE 1: DATA EXPLORATION
   ================================================ */

-- QUERY 01: Check total records
SELECT COUNT(*) AS total_records
FROM retail_raw;


-- QUERY 02: Display first 10 records
SELECT *
FROM retail_raw
LIMIT 10;


-- QUERY 03: Count unique orders, customers and products
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT product_id) AS total_products
FROM retail_raw;


-- QUERY 04: Check dataset date range
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM retail_raw;


/* ================================================
   PHASE 2: DATA QUALITY AND CLEANING
   ================================================ */

-- QUERY 05: Check missing values
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE sales IS NULL) AS missing_sales,
    COUNT(*) FILTER (WHERE profit IS NULL) AS missing_profit
FROM retail_raw;


-- QUERY 06: Check duplicate records
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT ROW(
        order_id, order_date, ship_date, ship_mode,
        customer_id, customer_name, segment, country,
        city, state, postal_code, region, product_id,
        category, sub_category, product_name, sales,
        quantity, discount, profit, delivery_days,
        order_year, order_month, month_name,
        profit_margin, discount_category
    )) AS unique_records
FROM retail_raw;


-- QUERY 07: Check invalid sales and quantities
SELECT *
FROM retail_raw
WHERE sales < 0 OR quantity <= 0;


-- QUERY 08: Create cleaned table
-- DISTINCT removes exact duplicate records.
-- Original raw table remains unchanged.

DROP TABLE IF EXISTS retail_clean;

CREATE TABLE retail_clean AS
SELECT DISTINCT *
FROM retail_raw;


-- QUERY 09: Verify cleaned data
SELECT
    (SELECT COUNT(*) FROM retail_raw) AS raw_records,
    (SELECT COUNT(*) FROM retail_clean) AS clean_records;


/* ================================================
   PHASE 3: BUSINESS KPI ANALYSIS
   ================================================ */

-- QUERY 10: Calculate overall business performance
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT product_id) AS total_products,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean;


-- QUERY 11: Calculate average order value
SELECT
    ROUND(
        SUM(sales) / COUNT(DISTINCT order_id), 2
    ) AS average_order_value
FROM retail_clean;


-- QUERY 12: Calculate category-wise sales and profit
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY category
ORDER BY total_sales DESC;


-- QUERY 13: Calculate region-wise sales
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY region
ORDER BY total_sales DESC;


-- QUERY 14: Analyse customer segments
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY segment
ORDER BY total_sales DESC;


/* ================================================
   PHASE 4: SALES TREND ANALYSIS
   ================================================ */

-- QUERY 15: Year-wise sales analysis
SELECT
    order_year,
    ROUND(SUM(sales), 2) AS yearly_sales,
    ROUND(SUM(profit), 2) AS yearly_profit
FROM retail_clean
GROUP BY order_year
ORDER BY order_year;


-- QUERY 16: Month-wise sales analysis
SELECT
    order_year,
    order_month,
    month_name,
    ROUND(SUM(sales), 2) AS monthly_sales
FROM retail_clean
GROUP BY order_year, order_month, month_name
ORDER BY order_year, order_month;


-- QUERY 17: Quarterly sales analysis
SELECT
    order_year,
    EXTRACT(QUARTER FROM order_date) AS quarter,
    ROUND(SUM(sales), 2) AS quarterly_sales
FROM retail_clean
GROUP BY order_year, EXTRACT(QUARTER FROM order_date)
ORDER BY order_year, quarter;


-- QUERY 18: Find the top 10 highest sales orders
SELECT
    order_id,
    ROUND(SUM(sales), 2) AS order_sales
FROM retail_clean
GROUP BY order_id
ORDER BY order_sales DESC
LIMIT 10;


/* ================================================
   PHASE 5: PRODUCT ANALYSIS
   ================================================ */

-- QUERY 19: Find top 10 best-selling products
SELECT
    product_name,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(sales), 2) AS total_sales
FROM retail_clean
GROUP BY product_id, product_name
ORDER BY total_quantity DESC
LIMIT 10;


-- QUERY 20: Find top 10 profitable products
SELECT
    product_name,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY product_id, product_name
ORDER BY total_profit DESC
LIMIT 10;


-- QUERY 21: Find loss-making sub-categories
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY category, sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit;


/* ================================================
   PHASE 6: CUSTOMER ANALYSIS
   ================================================ */

-- QUERY 22: Find top 10 customers by spending
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS total_spending
FROM retail_clean
GROUP BY customer_id, customer_name
ORDER BY total_spending DESC
LIMIT 10;


-- QUERY 23: Find repeat customers
SELECT
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM retail_clean
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY total_orders DESC;


-- QUERY 24: Categorise customers by spending
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(sales), 2) AS total_spending,
    CASE
        WHEN SUM(sales) >= 5000 THEN 'High Value'
        WHEN SUM(sales) >= 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_category
FROM retail_clean
GROUP BY customer_id, customer_name
ORDER BY total_spending DESC;


/* ================================================
   PHASE 7: REGIONAL AND SHIPPING ANALYSIS
   ================================================ */

-- QUERY 25: Find top 10 states by sales
SELECT
    state,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY state
ORDER BY total_sales DESC
LIMIT 10;


-- QUERY 26: Analyse shipping modes
SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days,
    ROUND(SUM(sales), 2) AS total_sales
FROM retail_clean
GROUP BY ship_mode
ORDER BY total_orders DESC;


/* ================================================
   PHASE 8: DISCOUNT AND PROFITABILITY ANALYSIS
   ================================================ */

-- QUERY 27: Analyse discount impact on profit
SELECT
    discount,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean
GROUP BY discount
ORDER BY discount;


-- QUERY 28: Find high-discount loss-making products
SELECT
    product_name,
    category,
    discount,
    ROUND(sales, 2) AS sales,
    ROUND(profit, 2) AS profit
FROM retail_clean
WHERE discount >= 0.30
AND profit < 0
ORDER BY profit;


/* ================================================
   PHASE 9: ADVANCED SQL
   ================================================ */

-- QUERY 29: Rank products based on profit
SELECT
    product_name,
    category,
    ROUND(SUM(profit), 2) AS total_profit,
    RANK() OVER (
        PARTITION BY category
        ORDER BY SUM(profit) DESC
    ) AS product_rank
FROM retail_clean
GROUP BY product_id, product_name, category
ORDER BY category, product_rank;


/* ================================================
   PHASE 10: BUSINESS REPORTING
   ================================================ */

-- QUERY 30: Create a business KPI view
CREATE OR REPLACE VIEW vw_retail_kpis AS
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT product_id) AS total_products,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_clean;


-- Final verification of business KPI view
SELECT *
FROM vw_retail_kpis;


/* ================================================
   END OF RETAIL ANALYTICS PROJECT
   ================================================ */
