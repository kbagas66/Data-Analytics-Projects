# Here is the SQL file to answer the business queries (requests)

USE gdb023;


# Request 1
SELECT market as Atliq FROM dim_customer
WHERE customer = "Atliq Exclusive"
	AND region = "APAC";


# Request 2
# Using Subquery
SELECT P2020.PCode AS unique_products_2020
	, P2021.PCode AS unique_products_2021
	, ROUND(abs(P2020.PCode - P2021.PCode)/P2020.PCode*100,2) percentage_chg
FROM 
	(SELECT COUNT(DISTINCT(product_code)) AS PCode 
	FROM fact_gross_price
	WHERE fiscal_year = 2020) AS P2020
    ,
	(SELECT COUNT(DISTINCT(product_code)) AS PCode 
	FROM fact_gross_price
	WHERE fiscal_year = 2021) AS P2021;

# Using CTE
WITH 
P2020 AS
	(SELECT DISTINCT(COUNT(product_code)) AS PCount
		, fiscal_year
	FROM fact_gross_price
    WHERE fiscal_year = 2020),
P2021 AS
	(SELECT DISTINCT(COUNT(product_code)) PCount 
		, fiscal_year
	FROM fact_gross_price
    WHERE fiscal_year = 2021)
SELECT P2020.PCount unique_products_2020 
	, P2021.Pcount unique_products_2021
	, ROUND(ABS(P2021.Pcount-P2020.PCount) / P2020.PCount * 100, 2) percentage_chg
FROM P2020, P2021;


# Request 3
SELECT segment, 
	COUNT(DISTINCT(product_code)) product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


# Request 4
# Using Subquery
SELECT P2020.segment 
	, P2020.PCount unique_products_2020 
	, P2021.PCount unique_products_2021
	, P2021.PCount-P2020.PCount difference
FROM 
	(SELECT DP.segment segment 
		, COUNT(DISTINCT(FGP.product_code)) PCount
	FROM dim_product DP, fact_gross_price FGP
	WHERE DP.product_code = FGP.product_code
		AND fiscal_year = 2020
	GROUP BY DP.segment) AS P2020
    ,
	(SELECT DP.segment segment
		, COUNT(DISTINCT(FGP.product_code)) PCount 
	FROM dim_product DP, fact_gross_price FGP
    WHERE DP.product_code = FGP.product_code
		AND fiscal_year = 2021
	GROUP BY DP.segment) AS P2021
WHERE 
	P2020.segment = P2021.segment;

# Using CTE (and JOIN)
WITH
P2020 AS
	(SELECT DP.segment segment
		, COUNT(DISTINCT(FGP.product_code)) PCount
    FROM fact_gross_price FGP
    JOIN dim_product DP ON
		FGP.product_code = DP.product_code
    WHERE fiscal_year = 2020
    GROUP BY segment),
P2021 AS
	(SELECT DP.segment segment
		, COUNT(DISTINCT(FGP.product_code)) PCount
    FROM fact_gross_price FGP
    JOIN dim_product DP ON
		FGP.product_code = DP.product_code
    WHERE fiscal_year = 2021
    GROUP BY segment)
SELECT P2020.segment segment 
	, P2020.PCount product_count_2020
	, P2021.PCount product_count_2021
	, P2021.PCount - P2020.PCount difference
FROM P2020
JOIN P2021 ON
	P2020.segment = P2021.segment
GROUP BY segment;
   

# Request 5
SELECT DP.product_code product_code 
	, DP.product product
	, FMC.manufacturing_cost manufacturing_cost
FROM dim_product DP, fact_manufacturing_cost FMC
WHERE DP.product_code = FMC.product_code
AND manufacturing_cost IN 
	(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
	UNION
	SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY FMC.manufacturing_cost DESC;


# Request 6
SELECT DC.customer_code 
	, DC.customer
	, AVG(FPID.pre_invoice_discount_pct) average_discount_percentage
FROM dim_customer DC, fact_pre_invoice_deductions FPID
WHERE DC.customer_code = FPID.customer_code
	AND market = "India"
    AND fiscal_year = 2021
GROUP BY DC.customer_code, DC.customer
ORDER BY AVG(pre_invoice_discount_pct) DESC
LIMIT 5;


# Request 7
SELECT EXTRACT(MONTH FROM date) "Month"
    , EXTRACT(YEAR FROM date) "Year"
	, SUM(sold_quantity) Gross_sales_Amount
FROM dim_customer DC, fact_sales_monthly FSM
WHERE DC.customer_code = FSM.customer_code
	AND customer = "Atliq Exclusive"
GROUP BY Month, Year;


# Request 8
SELECT EXTRACT(QUARTER FROM date + INTERVAL 4 MONTH) Quarter
    , SUM(sold_quantity) total_sold_quantity
FROM fact_sales_monthly FSM
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;


# Request 9
WITH
GROSS_SALES AS
	(SELECT channel
		, SUM(gross_price*sold_quantity) gross_sales_mln
	FROM dim_customer DC, fact_sales_monthly FSM, fact_gross_price FGP
	WHERE FSM.product_code = FGP.product_code
		AND DC.customer_code = FSM.customer_code
		AND FSM.fiscal_year = 2021
	GROUP BY channel)
SELECT channel
	, gross_sales_mln
	, gross_sales_mln / (SELECT SUM(gross_sales_mln) FROM GROSS_SALES) *100 percentage
FROM GROSS_SALES;


# Request 10
WITH
PRank AS
	(SELECT division 
		, DP.product_code product_code 
        , product
		, SUM(FSM.sold_quantity) total_sold_quantity
        , RANK() OVER(PARTITION BY division 
			ORDER BY SUM(FSM.sold_quantity) DESC) rank_order
	FROM dim_product DP, fact_sales_monthly FSM
	WHERE DP.product_code = FSM.product_code
		AND FSM.fiscal_year = 2021
    GROUP BY product_code, product, division)
SELECT *
FROM PRank
WHERE rank_order <= 3;