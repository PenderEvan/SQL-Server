UPDATE t1
SET FundName = t2.FundName
FROM dbo.HistoricalPricing as t1
INNER JOIN dbo.FundNameReference AS t2 on t1.Code = t2.FundCode
WHERE t1.FundName = ''
AND t2.FundName <> '';

SELECT * FROM HistoricalPricing ORDER BY PerformanceDate DESC, Code