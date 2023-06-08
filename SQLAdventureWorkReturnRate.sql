--Overview data of sales in 2016 and 2017

SELECT Top 1000 *
FROM AdventureWorks_Sales_2015
ORDER BY OrderDate, StockDate;


SELECT Top 1000 *
FROM AdventureWorks_Sales_2016
ORDER BY OrderDate, StockDate;

--Check Duplicate data by order by

SELECT *
FROM AdventureWorks_Sales_2015
ORDER BY OrderNumber;
-- 2630 rows 
SELECT DISTINCT OrderNumber, ProductKey
FROM AdventureWorks_Sales_2015
ORDER BY OrderNumber;
--2630 rows

SELECT *
FROM AdventureWorks_Sales_2016
ORDER BY OrderNumber;
--23935 rows
SELECT DISTINCT OrderNumber, ProductKey
FROM AdventureWorks_Sales_2016
ORDER BY OrderNumber;
--23935 rows 

-- UNION 2 Period of time to compare

SELECT *
FROM AdventureWorks_Sales_2015
UNION 
SELECT *
FROM AdventureWorks_Sales_2016;

-- Count the order quantity by month 

SELECT MONTH(OrderDate) AS [month]
	, YEAR(OrderDate) AS [year]
	, SUM(OrderQuantity)
FROM (
	SELECT *
	FROM AdventureWorks_Sales_2015
	UNION 
	SELECT *
	FROM AdventureWorks_Sales_2016
	) AS two_year_sales
GROUP BY MONTH(OrderDate), YEAR(OrderDate) 
ORDER BY YEAR(OrderDate), MONTH(OrderDate);

-- look at return table

select sa.OrderDate, sa.StockDate, sa.OrderQuantity, sa.ProductKey, sa.TerritoryKey, re.ReturnQuantity, re.ReturnDate
from AdventureWorks_Sales_2016
left join 
	on sa.ProductKey = re.ProductKey
	and sa.TerritoryKey = re.TerritoryKey
--Overview data of sales in 2016 and 2017

SELECT Top 1000 *
FROM AdventureWorks_Sales_2015
ORDER BY OrderDate, StockDate;


SELECT Top 1000 *
FROM AdventureWorks_Sales_2016
ORDER BY OrderDate, StockDate;

--Check Duplicate data by order by

SELECT *
FROM AdventureWorks_Sales_2015
ORDER BY OrderNumber;
-- 2630 rows 
SELECT DISTINCT OrderNumber, ProductKey
FROM AdventureWorks_Sales_2015
ORDER BY OrderNumber;
--2630 rows

SELECT *
FROM AdventureWorks_Sales_2016
ORDER BY OrderNumber;
--23935 rows
SELECT DISTINCT OrderNumber, ProductKey
FROM AdventureWorks_Sales_2016
ORDER BY OrderNumber;
--23935 rows 

-- UNION 2 Period of time to compare

SELECT *
FROM AdventureWorks_Sales_2015
UNION 
SELECT *
FROM AdventureWorks_Sales_2016;

-- Count the order quantity by month 

SELECT MONTH(OrderDate) AS [month]
	, YEAR(OrderDate) AS [year]
	, SUM(OrderQuantity)
FROM (
	SELECT *
	FROM AdventureWorks_Sales_2015
	UNION 
	SELECT *
	FROM AdventureWorks_Sales_2016
	) AS two_year_sales
GROUP BY MONTH(OrderDate), YEAR(OrderDate) 
ORDER BY YEAR(OrderDate), MONTH(OrderDate);

-- look at return table

SELECT sa_2016.OrderDate, sa_2016.StockDate, sa_2016.OrderQuantity, sa_2016.ProductKey, sa_2016.TerritoryKey, re.ReturnQuantity, re.ReturnDate
FROM AdventureWorks_Sales_2016 sa_2016
LEFT JOIN AdventureWorks_Returns re
	ON sa_2016.ProductKey = re.ProductKey
	AND sa_2016.TerritoryKey = re.TerritoryKey;

-- calculate return rate each year by Product Key 
-- Part1: Take the data need to be calculated and number of orders
WITH total_order_table AS (
	SELECT YEAR(OrderDate) AS [year]
		, ProductKey
		, TerritoryKey
		, SUM(OrderQuantity) AS total_order -- number of order by Product Key
	FROM (
		SELECT *
		FROM AdventureWorks_Sales_2015
		UNION 
		SELECT *
		FROM AdventureWorks_Sales_2016
		) AS two_year_sales
	GROUP BY  YEAR(OrderDate), ProductKey, TerritoryKey
)
--Part 2: Take the return quantity
, final_table AS(
	SELECT total_order_table.*
		, return_table .num_return 
		, case when return_table .num_return > 0 THEN return_table .num_return ELSE 0 END AS return_quantity -- replace NULL by 0
	FROM total_order_table
	LEFT JOIN (
		SELECT YEAR(ReturnDate) as [year]
			, ProductKey
			, TerritoryKey
			, SUM(ReturnQuantity) as num_return  --number of return by ProductKey
		FROM AdventureWorks_Returns
		GROUP BY YEAR(ReturnDate), ProductKey, TerritoryKey) AS return_table 
	ON total_order_table.[year] = return_table.[year] AND total_order_table.ProductKey = return_table.ProductKey AND total_order_table.TerritoryKey = return_table.TerritoryKey
	)
--Part 3: find out which product has high return rate follow by year
SELECT fn.[year]
	, fn.ProductKey
	, fn.total_order
	, fn.return_quantity
	, p.ProductSKU
	, p.ProductName
	, p.ModelName
	, ProductCost
    , ProductPrice
	, FORMAT(fn.return_quantity*1.0/fn.total_order,'p') AS return_rate
FROM final_table fn
LEFT JOIN AdventureWorks_Products p
ON fn.ProductKey = p.ProductKey
ORDER BY year ASC, total_order DESC, return_rate DESC

--CREATE TempTable
DROP TABLE if exists #Summary_order_return_of_product
CREATE TABLE #Summary_order_return_of_product
(
product_key numeric,
terri_key numeric,
order_qty numeric,
return_number numeric,
return_qty numeric
)
INSERT INTO #Summary_order_return_of_product
SELECT total_order_table.*
		,  return_table .num_return 
		, case when return_table.num_return > 0 THEN return_table .num_return ELSE 0 END AS return_quantity -- replace NULL by 0
FROM (
	SELECT 
		ProductKey
		, TerritoryKey
		, SUM(OrderQuantity) AS total_order -- number of order by Product Key
	FROM (
		SELECT *
		FROM AdventureWorks_Sales_2015
		UNION 
		SELECT *
		FROM AdventureWorks_Sales_2016
		) AS two_year_sales
	GROUP BY ProductKey, TerritoryKey) AS total_order_table
LEFT JOIN (
	SELECT ProductKey
		 , TerritoryKey
		 , SUM(ReturnQuantity) AS num_return  --number of return by ProductKey
	FROM AdventureWorks_Returns
	GROUP BY ProductKey, TerritoryKey) AS return_table 
ON total_order_table.ProductKey = return_table.ProductKey AND total_order_table.TerritoryKey = return_table.TerritoryKey


-- CREATE VIEW
DROP VIEW if exists product_summary
CREATE VIEW product_summary AS
-- Part1: Take the data need to be calculated and number of orders
WITH total_order_table AS (
	SELECT YEAR(OrderDate) AS [year]
		, ProductKey
		, TerritoryKey
		, SUM(OrderQuantity) AS total_order -- number of order by Product Key
	FROM (
		SELECT *
		FROM AdventureWorks_Sales_2015
		UNION 
		SELECT *
		FROM AdventureWorks_Sales_2016
		) AS two_year_sales
	GROUP BY  YEAR(OrderDate), ProductKey, TerritoryKey
)
--Part 2: Take the return quantity
, final_table AS(
	SELECT total_order_table.*
		, return_table .num_return 
		, case when return_table .num_return > 0 THEN return_table .num_return ELSE 0 END AS return_quantity -- replace NULL by 0
	FROM total_order_table
	LEFT JOIN (
		SELECT YEAR(ReturnDate) as [year]
			, ProductKey
			, TerritoryKey
			, SUM(ReturnQuantity) as num_return  --number of return by ProductKey
		FROM AdventureWorks_Returns
		GROUP BY YEAR(ReturnDate), ProductKey, TerritoryKey) AS return_table 
	ON total_order_table.[year] = return_table.[year] AND total_order_table.ProductKey = return_table.ProductKey AND total_order_table.TerritoryKey = return_table.TerritoryKey
	)
--Part 3: find out which product has high return rate follow by year
SELECT fn.[year]
	, fn.ProductKey
	, fn.total_order
	, fn.return_quantity
	, p.ProductSKU
	, p.ProductName
	, p.ModelName
	, ProductCost
    , ProductPrice
	, FORMAT(fn.return_quantity*1.0/fn.total_order,'p') AS return_rate
FROM final_table fn
LEFT JOIN AdventureWorks_Products p
ON fn.ProductKey = p.ProductKey