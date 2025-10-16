CREATE DATABASE Retail_Sales;
USE Retail_Sales;

-- 1. Top 10 highest revenue generating products
SELECT product_id, SUM(list_price * quantity * (1 - discount_percent / 100)) AS sales
FROM df_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;

-- 2. Top 5 highest selling products per region
WITH cte AS (
  SELECT region, product_id, SUM(list_price * quantity * (1 - discount_percent / 100)) AS sales
  FROM df_orders
  GROUP BY region, product_id
)
SELECT *
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY sales DESC) AS rn
  FROM cte
) AS t
WHERE rn <= 5;

-- 3. Month over month sales growth comparison for 2022 vs 2023
WITH cte AS (
  SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
    SUM(list_price * quantity * (1 - discount_percent / 100)) AS sales
  FROM df_orders
  GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_month,
  SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
  SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte
GROUP BY order_month
ORDER BY order_month;

-- 4. Month with highest sales per category
WITH cte AS (
  SELECT category, DATE_FORMAT(order_date, '%Y%m') AS year_month,
    SUM(list_price * quantity * (1 - discount_percent / 100)) AS sales
  FROM df_orders
  GROUP BY category, year_month
)
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
  FROM cte
) AS t WHERE rn = 1;

-- 5. Sub-category with highest growth in sales 2023 vs 2022
WITH cte AS (
  SELECT sub_category, YEAR(order_date) AS order_year,
    SUM(list_price * quantity * (1 - discount_percent / 100)) AS sales
  FROM df_orders
  GROUP BY sub_category, YEAR(order_date)
),
cte2 AS (
  SELECT sub_category,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
  FROM cte
  GROUP BY sub_category
)
SELECT sub_category,
  sales_2022, sales_2023,
  (sales_2023 - sales_2022) AS sales_growth
FROM cte2
ORDER BY sales_growth DESC
LIMIT 1;

-- 6. Profit margin analysis per product
SELECT product_id,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS revenue,
  SUM(cost_price * quantity) AS cost,
  SUM((list_price - cost_price) * quantity) AS profit
FROM df_orders
GROUP BY product_id
ORDER BY profit DESC;

-- 7. Regional sales summary
SELECT region,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS revenue
FROM df_orders
GROUP BY region
ORDER BY revenue DESC;

-- 8. Average discount percent and total quantity by category
SELECT category,
  AVG(discount_percent) AS avg_discount,
  SUM(quantity) AS total_quantity
FROM df_orders
GROUP BY category
ORDER BY avg_discount DESC;

-- 9. Shipping mode total sales
SELECT ship_mode,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS revenue
FROM df_orders
GROUP BY ship_mode
ORDER BY revenue DESC;

-- 10. Customer segment revenue
SELECT segment,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS revenue
FROM df_orders
GROUP BY segment
ORDER BY revenue DESC;

-- 11. Frequent customers by number of orders (assuming customer_id exists)
SELECT customer_id,
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS total_spent
FROM df_orders
GROUP BY customer_id
ORDER BY total_orders DESC;

-- 12. Customer segmentation: customers with high average order value and repeat purchases
WITH cte AS (
  SELECT customer_id,
    COUNT(DISTINCT order_id) AS order_count,
    AVG(list_price * quantity * (1 - discount_percent / 100)) AS avg_order_value
  FROM df_orders
  GROUP BY customer_id
)
SELECT * FROM cte
WHERE order_count > 1
ORDER BY avg_order_value DESC;

-- 13. Product lifecycle: monthly sales trends per product for last 12 months
SELECT product_id,
  DATE_FORMAT(order_date, '%Y%m') AS year_month,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS monthly_sales
FROM df_orders
WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY product_id, year_month
ORDER BY product_id, year_month;

-- 14. Cross-sell opportunities: frequently bought together products (simplified)
WITH order_products AS (
  SELECT order_id, product_id
  FROM df_orders
)
SELECT op1.product_id AS product_1, op2.product_id AS product_2, COUNT(DISTINCT op1.order_id) AS order_count
FROM order_products op1
JOIN order_products op2 ON op1.order_id = op2.order_id AND op1.product_id <> op2.product_id
GROUP BY op1.product_id, op2.product_id
ORDER BY order_count DESC
LIMIT 10;

-- 15. Price elasticity per product category
SELECT category,
  AVG(list_price) AS avg_price,
  SUM(quantity) AS total_quantity
FROM df_orders
GROUP BY category
ORDER BY category;

-- 18. Geo-level city sales ranking
SELECT city,
  SUM(list_price * quantity * (1 - discount_percent / 100)) AS revenue
FROM df_orders
GROUP BY city
ORDER BY revenue DESC
LIMIT 10;

-- 19. Discount and profitability correlation per category
SELECT category,
  AVG(discount_percent) AS avg_discount,
  SUM((list_price - cost_price) * quantity) AS total_profit
FROM df_orders
GROUP BY category
ORDER BY avg_discount DESC;
