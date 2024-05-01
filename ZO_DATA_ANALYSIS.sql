
-- Rolling/Moving count of restaurants in Indian cities
SELECT [COUNTRY_NAME], [City], [Locality], COUNT([Locality]) AS TOTAL_REST,
       SUM(COUNT([Locality])) OVER(PARTITION BY [City] ORDER BY [Locality] DESC)
FROM [dbo].[ZomatoData1]
WHERE [COUNTRY_NAME] = 'INDIA'
GROUP BY [COUNTRY_NAME], [City], [Locality]


-- Searching for percentage of restaurants in all the countries
CREATE OR ALTER VIEW TOTAL_COUNT
AS
(
    SELECT DISTINCT([COUNTRY_NAME]), COUNT(CAST([RestaurantID] AS NUMERIC)) OVER() AS TOTAL_REST
    FROM [dbo].[ZomatoData1]
)
SELECT * FROM TOTAL_COUNT


-- Final query after creating view
WITH CT1 AS
(
    SELECT [COUNTRY_NAME], COUNT(CAST([RestaurantID] AS NUMERIC)) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    GROUP BY [COUNTRY_NAME]
)
SELECT A.[COUNTRY_NAME], A.[REST_COUNT], ROUND(CAST(A.[REST_COUNT] AS DECIMAL) / CAST(B.[TOTAL_REST] AS DECIMAL) * 100, 2)
FROM CT1 A JOIN TOTAL_COUNT B
ON A.[COUNTRY_NAME] = B.[COUNTRY_NAME]
ORDER BY 3 DESC


-- Which countries and how many restaurants with percentage provide online delivery option
CREATE OR ALTER VIEW COUNTRY_REST
AS
(
    SELECT [COUNTRY_NAME], COUNT(CAST([RestaurantID] AS NUMERIC)) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    GROUP BY [COUNTRY_NAME]
)
SELECT * FROM COUNTRY_REST
ORDER BY 2 DESC

SELECT A.[COUNTRY_NAME], COUNT(A.[RestaurantID]) AS TOTAL_REST, 
       ROUND(COUNT(CAST(A.[RestaurantID] AS DECIMAL)) / CAST(B.[REST_COUNT] AS DECIMAL) * 100, 2)
FROM [dbo].[ZomatoData1] A JOIN COUNTRY_REST B
ON A.[COUNTRY_NAME] = B.[COUNTRY_NAME]
WHERE A.[Has_Online_delivery] = 'YES'
GROUP BY A.[COUNTRY_NAME], B.REST_COUNT
ORDER BY 2 DESC


-- Finding from which city and locality in India where the max restaurants are listed in Zomato
WITH CT1 AS
(
    SELECT [City], [Locality], COUNT([RestaurantID]) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    WHERE [COUNTRY_NAME] = 'INDIA'
    GROUP BY CITY, LOCALITY
)
SELECT [Locality], REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)


-- Types of foods are available in India where the max restaurants are listed in Zomato
WITH CT1 AS
(
    SELECT [City], [Locality], COUNT([RestaurantID]) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    WHERE [COUNTRY_NAME] = 'INDIA'
    GROUP BY CITY, LOCALITY
),
CT2 AS (
    SELECT [Locality], REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)
),
CT3 AS (
    SELECT [Locality], [Cuisines] FROM [dbo].[ZomatoData1]
)
SELECT A.[Locality], B.[Cuisines]
FROM CT2 A JOIN CT3 B
ON A.Locality = B.[Locality]


-- Most popular food in India where the max restaurants are listed in Zomato
CREATE VIEW VF 
AS
(
    SELECT [COUNTRY_NAME], [City], [Locality], N.[Cuisines] FROM [dbo].[ZomatoData1]
    CROSS APPLY (SELECT VALUE AS [Cuisines] FROM string_split([Cuisines], '|')) N
)

WITH CT1 AS
(
    SELECT [City], [Locality], COUNT([RestaurantID]) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    WHERE [COUNTRY_NAME] = 'INDIA'
    GROUP BY CITY, LOCALITY
),
CT2 AS (
    SELECT [Locality], REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)
)
SELECT A.[Cuisines], COUNT(A.[Cuisines])
FROM VF A JOIN CT2 B
ON A.Locality = B.[Locality]
GROUP BY B.[Locality], A.[Cuisines]
ORDER BY 2 DESC


-- Which localities in India have the lowest restaurants listed in Zomato
WITH CT1 AS
(
    SELECT [City], [Locality], COUNT([RestaurantID]) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    WHERE [COUNTRY_NAME] = 'INDIA'
    GROUP BY [City], [Locality]
)
SELECT * FROM CT1 WHERE REST_COUNT = (SELECT MIN(REST_COUNT) FROM CT1) ORDER BY CITY


-- How many restaurants offer table booking option in India where the max restaurants are listed in Zomato
WITH CT1 AS (
    SELECT [City], [Locality], COUNT([RestaurantID]) AS REST_COUNT
    FROM [dbo].[ZomatoData1]
    WHERE [COUNTRY_NAME] = 'INDIA'
    GROUP BY CITY, LOCALITY
),
CT2 AS (
    SELECT [Locality], REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)
),
CT3 AS (
    SELECT [Locality], [Has_Table_booking] AS TABLE_BOOKING
    FROM [dbo].[ZomatoData1]
)
SELECT A.[Locality], COUNT(A.TABLE_BOOKING) AS TABLE_BOOKING_OPTION
FROM CT3 A JOIN CT2 B
ON A.[Locality] = B.[Locality]
WHERE A.TABLE_BOOKING = 'YES'
GROUP BY A.[Locality]


-- How rating affects in max listed restaurants with and without table booking option (Connaught Place)
SELECT 'WITH_TABLE' AS TABLE_BOOKING_OPT, COUNT([Has_Table_booking]) AS TOTAL_REST, ROUND(AVG([Rating]), 2) AS AVG_RATING
FROM [dbo].[ZomatoData1]
WHERE [Has_Table_booking] = 'YES'
AND [Locality] = 'Connaught Place'
UNION
SELECT 'WITHOUT_TABLE' AS TABLE_BOOKING_OPT, COUNT([Has_Table_booking]) AS TOTAL_REST, ROUND(AVG([Rating]), 2) AS AVG_RATING
FROM [dbo].[ZomatoData1]
WHERE [Has_Table_booking] = 'NO'
AND [Locality] = 'Connaught Place'


-- Avg rating of restaurants location wise
SELECT [COUNTRY_NAME], [City], [Locality], 
       COUNT([RestaurantID]) AS TOTAL_REST, ROUND(AVG(CAST([Rating] AS DECIMAL)), 2) AS AVG_RATING
FROM [dbo].[ZomatoData1]
GROUP BY [COUNTRY_NAME], [City], [Locality]
ORDER BY 4 DESC


-- Finding the best restaurants with moderate cost for two in India having Indian cuisines
SELECT *
FROM [dbo].[ZomatoData1]
WHERE [COUNTRY_NAME] = 'INDIA'
AND [Has_Table_booking] = 'YES'
AND [Has_Online_delivery] = 'YES'
AND [Price_range] <= 3
AND [Votes] > 1000
AND [Average_Cost_for_two] < 1000
AND [Rating] > 4
AND [Cuisines] LIKE '%INDIA%'


-- Find all the restaurants those who are offering table booking options with price range and has high rating
SELECT [Price_range], COUNT([Has_Table_booking]) AS NO_OF_REST
FROM [dbo].[ZomatoData1]
WHERE [Rating] >= 4.5
AND [Has_Table_booking] = 'YES'
GROUP BY [Price_range]