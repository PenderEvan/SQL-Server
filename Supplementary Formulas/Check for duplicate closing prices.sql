SELECT t1.code, FundName, PerformanceDate, t3.PerformanceInception, t2.total
FROM ClosingPrices t1
JOIN (SELECT code, MONTH(PerformanceDate) AS p_month, YEAR(PerformanceDate) AS p_year, COUNT(*) AS total
	FROM ClosingPrices
	GROUP BY code, MONTH(PerformanceDate), YEAR(PerformanceDate)
	HAVING COUNT(*) > 1 ) t2
ON t1.code = t2.code
AND MONTH(t1.PerformanceDate) = p_month
AND YEAR(t1.PerformanceDate) = p_year
JOIN (SELECT PerformanceInception, code
FROM Performance) t3
ON t1.code = t3.code
ORDER BY t1.code, PerformanceDate

