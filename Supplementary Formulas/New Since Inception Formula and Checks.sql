UPDATE Performance 
SET SinceInceptionSimple2 = t2.SinceInceptionReturn
FROM Performance AS t1
	INNER JOIN (
		(SELECT Code, PerformanceDate,
			(GrowthOf10k / (SELECT TOP 1 previous.UnitPrice * 1000
				FROM HistoricalPricing previous
				WHERE previous.Code = t.Code
				ORDER BY previous.PerformanceDate ASC
			) - 1) AS SinceInceptionReturn
		FROM
			ClosingPrices AS t)
	)t2 ON t1.Code = t2.Code AND t1.PerformanceDate = t2.PerformanceDate;


CREATE TABLE #temp_table (Code int, PerformanceDate date, UnitPrice decimal(18,6));

WITH RankedPrices AS (
    SELECT Code, PerformanceDate, UnitPrice, ROW_NUMBER() OVER (PARTITION BY Code ORDER BY PerformanceDate ASC) AS RowNum
    FROM HistoricalPricing
    WHERE Code IN (
		SELECT Code 
		FROM Performance 
		WHERE SinceInceptionSimple <> SinceInceptionSimple2
	)
)
INSERT INTO #temp_table(code, PerformanceDate, UnitPrice)
SELECT Code, PerformanceDate, UnitPrice
FROM RankedPrices AS historical
WHERE RowNum = 1
ORDER BY PerformanceDate ASC


SELECT t1.code, t1.PerformanceDate AS NewPerformanceDate, UnitPrice AS NewUnitPrice, t2.PerformanceDate AS OldPerformanceDate, t2.ClosingPrice AS OldClosingPrice, t2.GrowthOf10k
FROM #temp_table AS t1
INNER JOIN(
SELECT Code, PerformanceDate, ClosingPrice, GrowthOf10k, ROW_NUMBER() OVER (PARTITION BY Code ORDER BY PerformanceDate ASC) AS RowNum
FROM ClosingPrices
) t2 ON t1.Code = t2.Code AND RowNum = 1

DROP TABLE #temp_table