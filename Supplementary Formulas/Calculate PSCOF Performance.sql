DECLARE @performance_start_date date = '2021-01-31';

WITH six_month_previous AS (
    SELECT t1.Code, t1.PerformanceDate,
        (SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(month, -6, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS BeginningPrice
    FROM ClosingPrices AS t1
),
two_year_previous AS (
    SELECT t1.Code, t1.PerformanceDate,
        (SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -2, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS BeginningPrice
    FROM ClosingPrices AS t1
),
three_year_previous AS (
    SELECT t1.Code, t1.PerformanceDate,
        (SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -3, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS BeginningPrice
    FROM ClosingPrices AS t1
)
SELECT t1.Code, FundName, t1.PerformanceDate, ClosingPrice, MonthlyReturn, ThreeMonthReturn,
	(TotalReturn+1) / (sm.BeginningPrice+1) - 1 AS SixMonthReturn,
	TwelveMonthReturn AS OneYearReturn,
	POWER((TotalReturn+1) / (twy.BeginningPrice+1), 0.5) - 1 AS TwoYearReturn,
	POWER((TotalReturn+1) / (thy.BeginningPrice+1), 0.33333333) - 1 AS ThreeYearReturn,
	DistributionFactor
FROM ClosingPrices AS t1
JOIN two_year_previous AS twy
   ON t1.Code = twy.Code
   AND t1.PerformanceDate = twy.PerformanceDate
JOIN six_month_previous AS sm
   ON t1.Code = sm.Code
   AND t1.PerformanceDate = sm.PerformanceDate
JOIN three_year_previous AS thy
   ON t1.Code = thy.Code
   AND t1.PerformanceDate = thy.PerformanceDate
WHERE t1.Code = 350 OR t1.Code = 340 AND t1.PerformanceDate >= @performance_start_date
ORDER BY Code, PerformanceDate ASC;