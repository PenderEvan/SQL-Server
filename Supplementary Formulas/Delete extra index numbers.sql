WITH RankedData AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Code, MONTH(PerformanceDate), YEAR(PerformanceDate) ORDER BY PerformanceDate DESC) AS RowNum
    FROM Indices
),
ToDelete AS (
    SELECT *
    FROM RankedData
    WHERE RowNum > 1
)
DELETE FROM Indices
WHERE ID IN (SELECT ID FROM ToDelete);

SELECT * FROM Indices;


DECLARE @startOfCurrentMonth DATETIME = DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0);
DECLARE @startOfPerf DATETIME = DATEADD(month, -2, @startOfCurrentMonth);
DECLARE @endOfPerf DATETIME = EOMONTH(@startOfPerf);

WITH FundAverages AS (
	SELECT Code, AVG(MonthlyReturn) AS AvgMonthlyReturn
	FROM ClosingPrices
	WHERE PerformanceDate <= @endOfPerf
	GROUP BY Code
),
BenchmarkAverages AS (
	SELECT t2.Code AS BenchmarkCode, AVG(ReturnsOriginal) AS AvgReturnsOriginal, p.Code AS Code
	FROM Indices AS t2
	INNER JOIN Performance AS p ON t2.Code = p.BenchmarkCode
	WHERE t2.PerformanceDate <= @endOfPerf
	AND t2.PerformanceDate >= p.PerformanceInception
	GROUP BY t2.Code, p.Code
)
SELECT t1.Code, t2.Code, t1.PerformanceDate, t2.PerformanceDate AS IndexPerformanceDate, t1.MonthlyReturn, t2.ReturnsOriginal, AvgMonthlyReturn, AvgReturnsOriginal
FROM ClosingPrices AS t1
	INNER JOIN Indices AS t2 ON EOMONTH(t1.PerformanceDate) = EOMONTH(t2.PerformanceDate) AND (SELECT BenchmarkCode FROM Performance WHERE t1.Code = Code) = t2.Code
	INNER JOIN FundAverages AS fa ON t1.Code = fa.Code
	INNER JOIN BenchmarkAverages AS ba ON t2.Code = ba.BenchmarkCode AND t1.Code = ba.Code
WHERE t1.PerformanceDate <= @endOfPerf
ORDER BY t1.Code, PerformanceDate;