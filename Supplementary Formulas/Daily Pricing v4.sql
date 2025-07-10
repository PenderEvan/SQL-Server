DECLARE @performance_date date = (SELECT DISTINCT TOP 1 performance_date FROM historical_pricing ORDER BY performance_date DESC)
DECLARE @start_of_month date = DATEADD(month, DATEDIFF(month, 0, @performance_date), 0);
DECLARE @previous_week date = DATEADD(week, -1, @performance_date);
DECLARE @year_end date = DATEFROMPARTS(YEAR(DATEADD(year, -1, @performance_date)), 12, 31);

CREATE TABLE #daily_pricing(
	performance_date date,
	fund_name varchar(100),
	code int,
	unit_price decimal(18, 8),
	current_distribution_factor decimal(18, 8),
	distribution_factor decimal(18, 8),
	week_previous_distribution decimal(18,8),
	reinvestment_price decimal(18,8),
	monthly_return decimal(18,8),
	ytd decimal(18,8),
	monthly_performance decimal(18,8)
);

INSERT INTO #daily_pricing(performance_date, fund_name, code, unit_price, current_distribution_factor, distribution_factor, reinvestment_price)
SELECT t1.performance_date, t1.fund_name, t1.Code, t1.unit_price, t1.distribution_factor, dist.distribution_factor, dist.reinvestment_price
FROM historical_pricing AS t1
LEFT JOIN (
	SELECT distribution_factor, unit_price AS reinvestment_price, code
	FROM historical_pricing 
	WHERE performance_date >= @start_of_month
		AND distribution_factor <> 0
) AS dist ON t1.code = dist.code
WHERE t1.performance_date = @performance_date AND (t1.Code % 100 = 10 OR t1.Code = 320 OR t1.Code = 1113);

UPDATE t1 
SET t1.week_previous_distribution = t2.distribution_factor
FROM #daily_pricing AS t1
CROSS APPLY (
    SELECT TOP 1 t2.distribution_factor
    FROM historical_pricing t2
    WHERE t2.Code = t1.code 
    AND t2.performance_date > @previous_week 
	AND distribution_factor <> 0
    ORDER BY t2.performance_date DESC 
) AS t2;

UPDATE t1 SET t1.week_previous_distribution = 0
FROM #daily_pricing AS t1
WHERE week_previous_distribution IS NULL

UPDATE #daily_pricing
SET distribution_factor = 0,
	reinvestment_price = unit_price
WHERE distribution_factor IS NULL;

INSERT INTO #daily_pricing(performance_date, code, unit_price, monthly_return) 
SELECT PerformanceDate, Code, ClosingPrice, MonthlyReturn
FROM ClosingPrices
WHERE (Code % 100 = 10 OR Code = 320 OR Code = 1113) AND PerformanceDate < @start_of_month AND PerformanceDate > @year_end

UPDATE #daily_pricing
SET monthly_return = ((unit_price * (1 + distribution_factor/reinvestment_price) - previous_price) / previous_price)
FROM #daily_pricing AS t1
INNER JOIN (
	SELECT Code, ClosingPrice AS previous_price
	FROM ClosingPrices AS t2
	WHERE (Code % 100 = 10 OR Code = 320 OR Code = 1113) 
		AND MONTH(PerformanceDate) = MONTH(DATEADD(day, -1, @start_of_month)) 
		AND YEAR(PerformanceDate) = YEAR(DATEADD(day, -1, @start_of_month))
) AS pcp ON t1.Code = pcp.Code
WHERE performance_date = @performance_date

UPDATE #daily_pricing 
SET ytd = (SELECT EXP (SUM (LOG (monthly_return+1)))-1 FROM #daily_pricing WHERE code = t1.code AND performance_date <= t1.performance_date)
FROM #daily_pricing AS t1

DELETE FROM #daily_pricing WHERE performance_date < @performance_date

SELECT t1.performance_date, fund_name, t1.code, unit_price,
	((unit_price + current_distribution_factor) / previous_day - 1) AS daily_change,
	((unit_price + week_previous_distribution) / previous_week - 1) AS weekly_change,
	ytd
FROM #daily_pricing AS t1
INNER JOIN (
	SELECT unit_price AS previous_day, code, performance_date, ROW_NUMBER() OVER (PARTITION BY Code ORDER BY performance_date DESC) AS RowNum
	FROM historical_pricing WHERE performance_date < @performance_date
) t2 ON t1.Code = t2.code AND t2.RowNum = 1
INNER JOIN (
	SELECT unit_price as previous_week, code, performance_date, ROW_NUMBER() OVER (PARTITION BY Code ORDER BY performance_date DESC) AS RowNum
	FROM historical_pricing WHERE performance_date <= @previous_week
) t3 ON t1.Code = t3.code AND t3.RowNum = 1
ORDER BY t1.performance_date DESC;

DROP TABLE #daily_pricing;