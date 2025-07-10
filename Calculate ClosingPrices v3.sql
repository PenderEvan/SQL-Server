TRUNCATE TABLE dbo.ClosingPrices;
DECLARE @performance_date date = GETDATE();

/* Add data from historical Prices*/

INSERT INTO dbo.ClosingPrices(PerformanceDate, Code) 
SELECT 
    MAX(performance_date) AS LastDayOfMonth,
	Code
FROM dbo.historical_pricing
WHERE performance_date < DATEFROMPARTS(YEAR(@performance_date), MONTH(@performance_date), 01)
GROUP BY YEAR(performance_date), MONTH(performance_date), Code
ORDER BY Code DESC, YEAR(performance_date), MONTH(performance_date);

UPDATE dbo.ClosingPrices
SET FundName = t2.fund_name, ClosingPrice = t2.unit_price, TotalNetAssets = t2.total_net_assets, TotalSharesOutstanding = t2.total_shares_outstanding
FROM dbo.ClosingPrices AS t1
	INNER JOIN (
		SELECT Code, fund_name, performance_date, unit_price, total_net_assets, total_shares_outstanding
		FROM dbo.historical_pricing
	) AS t2 ON t2.Code = t1.Code AND t2.performance_date = t1.PerformanceDate;

/* Add Reinvestment Prices */

UPDATE dbo.ClosingPrices
SET DistributionFactor = t2.distribution_factor, ReinvestmentPrice = t2.unit_price
FROM dbo.ClosingPrices AS t1
	INNER JOIN (
		SELECT Code, EOMONTH(performance_date) AS ClosingDate, distribution_factor, unit_price
		FROM dbo.historical_pricing
		WHERE distribution_factor <> 0 AND distribution_factor IS NOT NULL
	) t2 ON t1.Code = t2.Code AND EOMONTH(t1.PerformanceDate) = t2.ClosingDate;

/* Set NULL ReinvestmentPrice and DistributionFactor to 0 */

UPDATE ClosingPrices
SET DistributionFactor = 0
WHERE DistributionFactor IS NULL;

UPDATE ClosingPrices
SET ReinvestmentPrice = ClosingPrice
WHERE ReinvestmentPrice IS NULL;

/* Calculate Monthly Return based on morningstar formula */
/* Calculation can be found here: https://awgmain.morningstar.com/webhelp/glossary_definitions/mutual_fund/mfglossary_Total_Return.html */

WITH PreviousClosingPrice AS (
    SELECT t1.Code, t1.PerformanceDate, t1.ClosingPrice,
        COALESCE((
            SELECT TOP 1 t2.ClosingPrice
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate < t1.PerformanceDate
            ORDER BY t2.PerformanceDate DESC
        ), (SELECT TOP 1 hp.unit_price
					FROM historical_pricing AS hp
					WHERE hp.Code = t1.Code
					ORDER BY hp.performance_date ASC
        )) AS BeginningPrice
    FROM ClosingPrices AS t1
)
UPDATE t1
SET 
    MonthlyReturn = CASE
        WHEN pcp.BeginningPrice IS NOT NULL AND pcp.BeginningPrice <> 0 THEN 
            (t1.ClosingPrice * (1 + t1.DistributionFactor / t1.ReinvestmentPrice) - pcp.BeginningPrice) / pcp.BeginningPrice
        ELSE
			NULL
    END
FROM ClosingPrices AS t1
JOIN PreviousClosingPrice AS pcp
    ON t1.Code = pcp.Code
   AND t1.PerformanceDate = pcp.PerformanceDate;


/* Calculate Total Return as Sum of monthly return. See morningstar formula above */
UPDATE ClosingPrices
SET TotalReturn = (SELECT EXP (SUM (LOG (MonthlyReturn+1)))-1 FROM ClosingPrices WHERE Code = t1.Code AND PerformanceDate <= t1.PerformanceDate)
FROM ClosingPrices AS t1

UPDATE ClosingPrices
SET GrowthOf10k = (TotalReturn+1) * 10000,
TotalDistribution = (SELECT SUM(DistributionFactor) FROM ClosingPrices WHERE PerformanceDate <= t1.PerformanceDate AND Code = t1.Code)
FROM ClosingPrices AS t1

UPDATE ClosingPrices
SET Peak = (SELECT MAX(GrowthOf10k)
		FROM ClosingPrices AS t2
		WHERE PerformanceDate <= t1.PerformanceDate AND Code = t1.Code),
	DrawDown = (
		SELECT CASE
			WHEN Peak = GrowthOf10k THEN 0
			ELSE GrowthOf10k / Peak - 1
		END)
FROM ClosingPrices AS t1;

WITH previous_prices AS (
    SELECT t1.Code, t1.PerformanceDate,
        (SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(month, -3, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS ThreeMonthPrev,
		(SELECT TOP 1 t2.TotalReturn
            FROM ClosingPrices AS t2
            WHERE t2.Code = t1.Code
              AND t2.PerformanceDate <= EOMONTH(DATEADD(year, -1, t1.PerformanceDate))
            ORDER BY t2.PerformanceDate DESC) AS TwelveMonthPrev 
    FROM ClosingPrices AS t1
)
UPDATE t1
SET ThreeMonthReturn = (TotalReturn+1) / (pp.ThreeMonthPrev+1) - 1,
	TwelveMonthReturn = (TotalReturn+1) / (pp.TwelveMonthPrev+1) - 1
FROM ClosingPrices AS t1
JOIN previous_prices AS pp
   ON t1.Code = pp.Code
   AND t1.PerformanceDate = pp.PerformanceDate;

WITH cda2yr AS (
	SELECT EOMONTH(performance_date) AS performance_date, monthly_return
	FROM closing_indices
	WHERE code = 'CDA2YR'
)
UPDATE t1
SET ExcessReturn = MonthlyReturn - cda2yr.monthly_return
FROM ClosingPrices AS t1
JOIN cda2yr AS cda2yr
	ON EOMONTH(t1.PerformanceDate) = cda2yr.performance_date;

SELECT code, FundName, PerformanceDate, GrowthOf10k
FROM ClosingPrices
ORDER BY PerformanceDate DESC, Code DESC;