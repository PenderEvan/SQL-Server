DECLARE @startOfCurrentMonth DATETIME = DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0);
DECLARE @startOfPerf DATETIME = DATEADD(month, -1, @startOfCurrentMonth);
DECLARE @endOfPerf DATETIME = EOMONTH(@startOfPerf);

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
	WHERE performance_date <= @endOfPerf AND performance_date > PerformanceInception
	GROUP BY t1.Code, p.Code
)
SELECT t1.Code, t1.FundName, t1.PerformanceDate, AvgMonthlyReturn, AvgReturnsOriginal AS AvgMonthlyReturnIndex, CountMonthlyReturn
FROM Performance AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.PerformanceDate) = EOMONTH(t2.performance_date) AND (SELECT BenchmarkCode FROM Performance WHERE t1.Code = Code) = t2.Code
	INNER JOIN FundAverages AS fa ON t1.Code = fa.Code
	INNER JOIN BenchmarkAverages AS ba ON t2.Code = ba.Code AND t1.Code = fund_code
WHERE t1.PerformanceDate <= @endOfPerf AND t1.Code IN (SELECT Code FROM Performance)
ORDER BY Code
