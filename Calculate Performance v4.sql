TRUNCATE TABLE dbo.Performance;
DECLARE @startOfCurrentMonth DATETIME = DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0);
DECLARE @startOfPerf DATETIME = DATEADD(month, -1, @startOfCurrentMonth);
DECLARE @endOfPerf DATETIME = EOMONTH(@startOfPerf);

INSERT INTO Performance(Code, FundName, PerformanceDate, NAVPU, OneMonth, ThreeMonth, OneYear, TotalReturn) 
SELECT 
	Code, FundName, PerformanceDate, ClosingPrice, MonthlyReturn, ThreeMonthReturn,
	TwelveMonthReturn, TotalReturn
FROM ClosingPrices
WHERE EOMONTH(PerformanceDate) = @endOfPerf;

UPDATE Performance
SET PerformanceInception = (SELECT MIN(performance_date) FROM historical_pricing WHERE code = t1.Code),
BenchmarkCode = (SELECT benchmark_code FROM benchmark_codes WHERE fund_code = t1.Code)
FROM Performance AS t1;

WITH prev_prices AS (
    SELECT t1.Code, t1.PerformanceDate,
        (SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(month, -6, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS SixMonthPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -2, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS TwoYearPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -3, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS ThreeYearPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -5, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS FiveYearPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -10, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS TenYearPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -15, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS FifteenYearPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND MONTH(t2.PerformanceDate) = 12
			  AND YEAR(t2.PerformanceDate) = YEAR(t1.PerformanceDate)-1
            ORDER BY t2.PerformanceDate DESC) AS EndOfYear
    FROM ClosingPrices AS t1
	WHERE EOMONTH(PerformanceDate) = @endOfPerf
)
UPDATE t1
SET SixMonth = (TotalReturn+1) / (pp.SixMonthPrev+1) - 1,
	TwoYear = POWER((TotalReturn+1) / (pp.TwoYearPrev+1), 0.5) - 1,
	ThreeYear = POWER((TotalReturn+1) / (pp.ThreeYearPrev+1), 0.33333333) - 1,
	FiveYear = POWER((TotalReturn+1) / (pp.FiveYearPrev+1), 0.2) - 1,
	TenYear = POWER((TotalReturn+1) / (pp.TenYearPrev+1), 0.1) - 1,
	FifteenYear = POWER((TotalReturn+1) / (pp.FifteenYearPrev+1), 0.06666666) - 1,
	YTD = (TotalReturn+1) / (pp.EndOfYear+1) - 1
FROM Performance AS t1
JOIN prev_prices AS pp
   ON t1.Code = pp.Code

UPDATE Performance 
SET SinceInceptionAnn = CASE 
	WHEN DATEDIFF(DAY, PerformanceInception, PerformanceDate) > 364
	THEN 
		CASE
			WHEN TotalReturn+1 > 0 
			THEN POWER(TotalReturn+1, 365.0/DATEDIFF(DAY, PerformanceInception, PerformanceDate))-1
			ELSE -POWER(-(TotalReturn+1), 365.0/DATEDIFF(DAY, PerformanceInception, PerformanceDate)) - 1
			END
	ELSE TotalReturn
	END;

WITH index_return AS (
	SELECT t1.Code,
		(SELECT EXP (SUM (LOG (monthly_return+1)))-1 FROM closing_indices WHERE code = t1.BenchmarkCode AND performance_date >= t1.PerformanceInception AND performance_date <= t1.PerformanceDate) AS total_return
	FROM Performance AS t1
)
UPDATE Performance 
SET IndexSinceInceptionAnn = CASE 
	WHEN DATEDIFF(DAY, PerformanceInception, PerformanceDate) > 364
	THEN 
		CASE
			WHEN index_return.total_return+1 > 0 
			THEN POWER(index_return.total_return+1, 365.0/DATEDIFF(DAY, PerformanceInception, PerformanceDate))-1
			ELSE -POWER(-(index_return.total_return+1), 365.0/DATEDIFF(DAY, PerformanceInception, PerformanceDate)) - 1
			END
	ELSE TotalReturn
	END
FROM Performance AS t1
JOIN index_return AS index_return
	ON t1.Code = index_return.Code;

/* ADD IN CLAUSE TO + AND - MONTHS WHERE MONTH MUST BE GREATER THAN 0 */

WITH up_count AS (
	SELECT t1.code, t1.BenchmarkCode, t1.performanceInception, 
		(SELECT COUNT(monthly_return)
		FROM closing_indices
		WHERE code = t1.BenchmarkCode
			AND performance_date <= t1.PerformanceDate
			AND performance_date >= t1.PerformanceInception
			AND monthly_return > 0) AS benchmark_count
	FROM Performance AS t1
),
down_count AS (
	SELECT t1.code, t1.BenchmarkCode, t1.performanceInception, 
		(SELECT COUNT(monthly_return)
		FROM closing_indices
		WHERE code = t1.BenchmarkCode
			AND performance_date <= t1.PerformanceDate
			AND performance_date >= t1.PerformanceInception
			AND monthly_return < 0) AS benchmark_count
	FROM Performance AS t1 
)
UPDATE t1
SET UpCapture = 
	(SELECT COUNT(MonthlyReturn) FROM ClosingPrices WHERE MonthlyReturn > 0 AND code = t1.Code AND PerformanceDate <= t1.PerformanceDate) * 100 / 
	CASE 
		WHEN up_count.benchmark_count <> 0 
		THEN up_count.benchmark_count
		ELSE NULL
	END,
	DownCapture = 
	(SELECT COUNT(MonthlyReturn) FROM ClosingPrices WHERE MonthlyReturn < 0 AND code = t1.Code AND PerformanceDate <= t1.PerformanceDate) * 100 / 
	CASE 
		WHEN down_count.benchmark_count <> 0 
		THEN down_count.benchmark_count
		ELSE NULL
	END
FROM Performance AS t1
JOIN up_count AS up_count
   ON t1.Code = up_count.code
JOIN down_count AS down_count
   ON t1.Code = down_count.code;

UPDATE Performance
SET SinceInceptionDistribution = (SELECT TotalDistribution FROM ClosingPrices WHERE PerformanceDate = t1.PerformanceDate AND Code = t1.Code),
Best3Months = (SELECT MAX(ThreeMonthReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
Worst3Months = (SELECT MIN(ThreeMonthReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
Best12Months = (SELECT MAX(TwelveMonthReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
Worst12Months = (SELECT MIN(TwelveMonthReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
MaxDrawdown = (SELECT MIN(Drawdown) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
StdDev = (SELECT STDEV(MonthlyReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate) * 346.410161514,
MonthsPositive = (SELECT COUNT(MonthlyReturn) FROM ClosingPrices WHERE Code = t1.Code AND MonthlyReturn >= 0 AND PerformanceDate <= t1.PerformanceDate),
MonthsNegative = (SELECT COUNT(MonthlyReturn) FROM ClosingPrices WHERE Code = t1.Code AND MonthlyReturn < 0 AND PerformanceDate <= t1.PerformanceDate),
AvgExcessReturn = (SELECT AVG(ExcessReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
StdDevExcessReturn = (SELECT STDEV(ExcessReturn) FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate),
AvgExcessReturnBenchmark = (SELECT AVG(excess_return) FROM closing_indices WHERE code = t1.BenchmarkCode AND performance_date >= t1.PerformanceInception AND performance_date <= t1.PerformanceDate)
FROM Performance AS t1;

/*
UPDATE Performance
SET Beta = (
	SELECT ABS(
		(COUNT(t1.MonthlyReturn) * SUM(t1.MonthlyReturn * t2.monthly_return) - SUM(t1.MonthlyReturn) * SUM(t2.monthly_return)) / 
		NULLIF(COUNT(t1.MonthlyReturn) * SUM(t2.monthly_return*t2.monthly_return) - SUM(t2.monthly_return) * SUM(t2.monthly_return), 0)
	) AS Slope
	FROM ClosingPrices AS t1
	INNER JOIN (
		SELECT performance_date, monthly_return, Code
		FROM closing_indices
	) AS t2 ON EOMONTH(t1.PerformanceDate) = EOMONTH(t2.performance_date)
	WHERE t1.Code = performance.Code
	AND t1.MonthlyReturn IS NOT NULL
	AND t2.Code = Performance.BenchmarkCode
	AND t2.performance_date >= (
		SELECT TOP 1 PerformanceDate
		FROM ClosingPrices
		WHERE Code = Performance.Code
		AND monthly_return IS NOT NULL
		AND monthly_return <> 0
		ORDER BY PerformanceDate ASC 
	)
); */

WITH FundAverages AS (
	SELECT Code, AVG(MonthlyReturn) AS AvgMonthlyReturn, COUNT(MonthlyReturn) AS CountMonthlyReturn
	FROM ClosingPrices
	WHERE PerformanceDate <= @endOfPerf
	GROUP BY Code
),
BenchmarkAverages AS (
	SELECT t1.Code, p.Code AS fund_code, AVG(monthly_return) AS AvgReturnsOriginal
	FROM closing_indices AS t1
	JOIN (SELECT Code, BenchmarkCode, PerformanceInception FROM Performance) AS p ON p.BenchmarkCode = t1.Code
	WHERE performance_date <= @endOfPerf AND performance_date >= PerformanceInception
	GROUP BY t1.Code, p.Code
)
UPDATE Performance
SET Beta = (
	SELECT
		SUM(
			(t1.MonthlyReturn - fa.AvgMonthlyReturn) * 
			(t2.monthly_return - ba.AvgReturnsOriginal)
		) / 
		SUM(POWER(t2.monthly_return - ba.AvgReturnsOriginal, 2))
	AS Slope
	FROM ClosingPrices AS t1
		INNER JOIN closing_indices AS t2 ON EOMONTH(t1.PerformanceDate) = EOMONTH(t2.performance_date) AND (SELECT BenchmarkCode FROM Performance WHERE t1.Code = Code) = t2.Code
		INNER JOIN FundAverages AS fa ON t1.Code = fa.Code
		INNER JOIN BenchmarkAverages AS ba ON t2.Code = ba.Code AND t1.Code = fund_code
	WHERE t1.Code = Performance.Code AND t1.PerformanceDate <= @endOfPerf
);


/* SELECT Code, FundName, PerformanceDate, Beta, OneMonth FROM Performance ORDER BY Code ASC */

UPDATE Performance
SET Correlation = CASE 
	WHEN ThreeMonth IS NOT NULL THEN (
		SELECT
			((SUM(t1.MonthlyReturn*t2.monthly_return) - (SUM(t1.MonthlyReturn) * SUM(t2.monthly_return) /  COUNT(t1.MonthlyReturn))) /
			NULLIF(SQRT(
				(SUM(t1.MonthlyReturn * t1.MonthlyReturn) - POWER(SUM(t1.MonthlyReturn), 2.0) /  COUNT(t1.MonthlyReturn)) * 
				(SUM(t2.monthly_return * t2.monthly_return) - POWER(SUM(t2.monthly_return), 2.0) /  COUNT(t1.MonthlyReturn))),0)) AS "Corr"
		FROM ClosingPrices AS t1
		INNER JOIN (
			SELECT performance_date, monthly_return, code
			FROM closing_indices
		) AS t2 ON EOMONTH(t1.PerformanceDate) = EOMONTH(t2.performance_date)
		WHERE t1.Code = performance.Code
		AND t2.Code = Performance.BenchmarkCode
		AND t1.MonthlyReturn IS NOT NULL
		AND Performance.BenchmarkCode IS NOT NULL
		AND t2.performance_date >= Performance.PerformanceInception
	)
	ELSE NULL
	END;

UPDATE Performance
SET Alpha = (AvgExcessReturn - (Beta * AvgExcessReturnBenchmark)) * 1200,
SharpeRatio = (AvgExcessReturn/StdDevExcessReturn) * 3.46410161514;

UPDATE Performance 
SET Y2010 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2010 AND
			MONTH(previous.PerformanceDate) = 12
		) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2009 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2011 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2011 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2010 AND
			MONTH(previous.PerformanceDate) = 12
		) - 1),
	Y2012 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2012 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2011 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2013 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2013 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2012 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2014 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2014 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2013 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2015 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2015 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2014 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2016 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2016 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2015 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2017 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2017 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2016 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2018 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2018 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2017 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2019 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2019 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2018 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2020 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2020 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2019 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2021 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2021 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2020 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2022 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2022 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2021 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2023 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2023 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2022 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1),
	Y2024 = ((SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2024 AND
			MONTH(previous.PerformanceDate) = 12
	) / 
	(SELECT TOP 1 previous.GrowthOf10k
		FROM ClosingPrices previous
		WHERE previous.Code = Performance.Code AND
			YEAR(previous.PerformanceDate) = 2023 AND
			MONTH(previous.PerformanceDate) = 12
	) - 1);

SELECT * FROM Performance ORDER BY FundName ASC