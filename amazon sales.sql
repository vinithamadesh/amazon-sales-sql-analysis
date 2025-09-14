CREATE DATABASE AmazonSalesDB;

ALTER TABLE amazon_sales
RENAME COLUMN `Invoice ID` TO Invoice_ID,
RENAME COLUMN `Customer type` TO Customer_type,
RENAME COLUMN `Product line` TO Product_line,
RENAME COLUMN `Unit price` TO Unit_price,
RENAME COLUMN `Tax 5%` TO Tax,
RENAME COLUMN `gross margin percentage` TO gross_margin_percentage,
RENAME COLUMN `gross income` TO gross_income,
RENAME COLUMN `Payment` TO Payment_method,
RENAME COLUMN `Total` TO Total_Price
;
/* Add a new column named timeofday to give insight of sales in the Morning, Afternoon and Evening. 
This will help answer the question on which part of the day most sales are made.*/

ALTER TABLE amazon_sales ADD COLUMN Time_of_day VARCHAR(20);
SET SQL_SAFE_UPDATES = 0;
UPDATE amazon_sales
SET Time_of_day = CASE
    WHEN HOUR(Time) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN HOUR(Time) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN HOUR(Time) BETWEEN 18 AND 23 THEN 'Evening'
    ELSE 'Late Night'
END;

-- added new column order date and changed the type text to date
ALTER TABLE amazon_sales ADD COLUMN Order_date DATE;
UPDATE amazon_sales
SET Order_date = STR_TO_DATE(Date, '%d-%m-%Y');


/*
 Add a new column named dayname that contains the extracted days of the week on 
 which the given transaction took place (Mon, Tue, Wed, Thur, Fri). 
 This will help answer the question on which week of the day each branch is busiest.
*/
ALTER TABLE amazon_sales Add COLUMN Dayname VARCHAR(15);
UPDATE amazon_sales
SET Dayname = dayname(Order_date);

 /* Add a new column named monthname that contains the extracted months of the year 
 on which the given transaction took place (Jan, Feb, Mar). Help determine which
 month of the year has the most sales and profit.
 */
 ALTER TABLE amazon_sales ADD COLUMN Monthname VARCHAR(20);
 UPDATE amazon_sales
 SET Monthname = monthname(Order_date);

 ALTER TABLE amazon_sales ADD COLUMN Month_Number VARCHAR(20);
 UPDATE amazon_sales
 SET Month_Number = month(Order_date);

-- SELECT LEFT(MONTHNAME(Order_date), 3) AS MonthAbbrev
-- FROM amazon;
ALTER TABLE amazon_sales
ADD COLUMN Month_3char VARCHAR(10);
UPDATE amazon_sales
SET Month_3char = left(monthname(Order_date),3);

-- Business Questions To Answer:
-- 1. What is the count of distinct cities in the dataset?
SELECT count(DISTINCT City) AS Distinct_City 
FROM amazon_sales;

-- 2.For each branch, what is the corresponding city?
SELECT DISTINCT Branch, city FROM amazon_sales;

-- 3.What is the count of distinct product lines in the dataset?
SELECT DISTINCT Product_line FROM amazon_sales;

-- 4.Which payment method occurs most frequently?
SELECT Payment_method, count(payment_method) AS Frequent_payment_method FROM amazon_sales
GROUP BY payment_method
ORDER BY count(payment_method) DESC
LIMIT 1;

-- 5.Which product line has the highest sales?
SELECT Product_line, count(Quantity) AS Total_Sales
FROM amazon_sales
GROUP BY Product_line
ORDER BY Total_Sales DESC
LIMIT 1;

-- 6.How much revenue is generated each month?
SELECT Monthname, CAST(sum(Total_price) as decimal(10,2)) AS Revenue_by_month
FROM amazon_sales
GROUP BY Monthname;

-- 7.In which month did the cost of goods sold reach its peak?
SELECT Monthname, CAST(sum(cogs) as decimal(10,2)) AS Cost_Of_cogs_Sold_by_month
FROM amazon_sales
GROUP BY Monthname
ORDER BY Cost_Of_cogs_Sold_by_month DESC
LIMIT 1;

-- 8.Which product line generated the highest revenue?
SELECT Product_line, CAST(sum(Total_Price) as decimal(10,2)) AS Total_Revenue
FROM amazon_sales
GROUP BY Product_line
ORDER BY sum(Total_Price) 
LIMIT 1;

-- 9.In which city was the highest revenue recorded?
SELECT city, CAST(SUM(Total_Price) as decimal(10,2)) as Highest_revenue 
FROM amazon_sales
GROUP BY city
ORDER BY SUM(Total_Price) DESC
LIMIT 1;

-- 10.Which product line incurred the highest Value Added Tax?
SELECT Product_line, SUM(Tax) AS Highest_tax_added
FROM amazon_sales
GROUP BY Product_line
ORDER BY Highest_tax_added DESC
LIMIT 1;

-- 11.For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
SELECT Product_line, SUM(Total_Price) AS Total_Sales,
CASE
    WHEN SUM(Total_Price) > (SELECT AVG(Total_Sales)
                           FROM(
                                SELECT Product_line, SUM(Total_Price) AS Total_Sales
                                FROM amazon_sales
                                GROUP BY Product_line
                                ) AS Subquery)
	THEN 'Good'
    ELSE 'Bad'
END AS Sales_Status
From amazon_sales
GROUP BY Product_line;

-- 12.Identify the branch that exceeded the average number of products sold.
SELECT 
    branch, 
    SUM(quantity) AS total_products,
    CASE 
        WHEN SUM(quantity) > (
             SELECT AVG(total_products)
             FROM (
                  SELECT Branch, SUM(Quantity) AS total_products
                  FROM amazon_sales
                  GROUP BY Branch 
             ) AS Subquery
        ) THEN 'Above Average'
        ELSE 'Below Average'
    END AS avg_product_status
FROM amazon_sales
GROUP BY branch
Order by total_products DESC
limit 1;

-- 13.Calculate the average rating for each product line.
SELECT product_line, AVG(Rating) AS avg_rating FROM amazon_sales
GROUP BY Product_line;

-- 14.Count the sales occurrences for each time of day on every weekday.
SELECT dayname, Time_of_day, count(payment_method) AS payment_count 
FROM amazon_sales
WHERE dayname != 'Saturday' AND dayname != 'Sunday'
GROUP BY dayname, Time_of_day;

-- 15.Identify the customer type contributing the highest revenue.
SELECT customer_type, sum(total_price) AS total_revenue 
FROM amazon_sales
GROUP BY Customer_type
ORDER BY total_revenue DESC
LIMIT 1;

-- 16.Determine the city with the highest VAT percentage.
SELECT city, (SUM(Tax) / SUM(Total_price)) * 100 AS vat_percentage
FROM amazon_sales
GROUP BY city
ORDER BY vat_percentage DESC
LIMIT 1;

-- 17.Identify the customer type with the highest VAT payments.
SELECT Customer_type, SUM(Tax) AS total_vat
FROM amazon_sales
GROUP BY Customer_type
ORDER BY total_vat DESC
LIMIT 1;

-- 18.What is the count of distinct customer types in the dataset?
SELECT count(DISTINCT customer_type) AS customer_count 
FROM amazon_sales;

-- 19.What is the count of distinct payment methods in the dataset?
SELECT count(DISTINCT Payment_method) AS Payment_method_count 
FROM amazon_sales;

-- 20.Which customer type occurs most frequently?
SELECT customer_type, count(Customer_type) AS Total_customer FROM amazon_sales
GROUP BY Customer_type
ORDER BY count(Customer_type) DESC
LIMIT 1;

-- 21.Identify the customer type with the highest purchase frequency.
SELECT customer_type, count(Customer_type) AS cust_type_count FROM amazon_sales
GROUP BY Customer_type
ORDER BY count(Customer_type) DESC
LIMIT 1;

-- 22.Determine the predominant gender among customers.
SELECT gender, count(gender) AS gender_count FROM amazon_sales
GROUP BY gender
ORDER BY gender_count DESC
LIMIT 1;

-- 23.Examine the distribution of genders within each branch.
SELECT branch, gender, count(gender) Gender_count FROM amazon_sales
GROUP BY branch, gender;

-- 24.Identify the time of day when customers provide the most ratings
SELECT time_of_day, count(rating) AS Rating_count from amazon_sales
GROUP BY Time_of_day
ORDER BY count(rating) DESC
LIMIT 1;

-- 25.Identify the day of the week with the highest average ratings.
SELECT dayname, AVG(rating) AS Avg_Rating FROM amazon_sales
GROUP BY dayname
ORDER BY avg(rating) DESC
LIMIT 1;


-- 26.Determine the day of the week with the highest average ratings for each branch.
SELECT branch, dayname, avg_rating
FROM (
    SELECT 
        branch,
        dayname,
        avg(rating) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY avg(rating) DESC) AS r_number
    FROM amazon_sales
    GROUP BY branch, dayname
) AS ranked
WHERE r_number = 1;





