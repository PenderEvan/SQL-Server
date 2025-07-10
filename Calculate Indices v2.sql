TRUNCATE TABLE closing_indices;
DECLARE @performance_date date = GETDATE();


/* create closing prices for currency conversion */

CREATE TABLE #fx_returns(
	id int IDENTITY(1,1) PRIMARY KEY,
	performance_date date,
	cur_start varchar(4),
	conversion decimal(18,8)
);

INSERT INTO #fx_returns(performance_date, cur_start) 
SELECT 
    MAX(performance_date) AS last_day_of_month,
	cur_start
FROM fx_rates
WHERE performance_date < DATEFROMPARTS(YEAR(@performance_date), MONTH(@performance_date), 01)
GROUP BY YEAR(performance_date), MONTH(performance_date), cur_start
ORDER BY cur_start DESC, YEAR(performance_date), MONTH(performance_date);

UPDATE #fx_returns
SET conversion = t2.conversion
FROM #fx_returns AS t1
	INNER JOIN (
		SELECT cur_start, performance_date, conversion
		FROM fx_rates
	) AS t2 ON t2.cur_start = t1.cur_start AND t2.performance_date = t1.performance_date;

/* Add data from historical Prices*/

INSERT INTO closing_indices(performance_date, code) 
SELECT 
    MAX(performance_date) AS last_day_of_month,
	code
FROM indices
WHERE performance_date < DATEFROMPARTS(YEAR(@performance_date), MONTH(@performance_date), 01)
GROUP BY YEAR(performance_date), MONTH(performance_date), code
ORDER BY Code DESC, YEAR(performance_date), MONTH(performance_date);


UPDATE closing_indices
SET index_name = t2.index_name, index_level = t2.index_level
FROM closing_indices AS t1
	INNER JOIN (
		SELECT code, index_name, performance_date, index_level
		FROM indices
	) AS t2 ON t2.code = t1.code AND t2.performance_date = t1.performance_date;

/* currency conversions for relevant funds */

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'DEXU' AS code, 'FTSE/TMX Canada Universe Bond Index (USD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'CDN'
WHERE t1.code = 'DEX';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'RTYC' AS code, 'Russell 2000 Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'RTY';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'MIDC' AS code, 'S&P Mid Cap 400 (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'MID';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'RAYC' AS code, 'Russell 3000 Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'RAY';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'SPXC' AS code, 'S&P 500 Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'SPX';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'RMICROC' AS code, 'Russell Microcap Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'RMICRO';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'H0A0C' AS code, 'ICE BofA US High Yield Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'H0A0';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'MXEFC' AS code, 'MSCI Emerging Market Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'MXEF';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'CCMPC' AS code, 'NASDAQ Composite Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'CCMP';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'R2500C' AS code, 'Russell 2500 Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'R2500';

INSERT INTO closing_indices (code, index_name, performance_date, index_level, blended_index)
SELECT 'R2500C' AS code, 'Russell 2500 Index (CAD)' AS index_name, t1.performance_date, ((t2.conversion)*(index_level)) AS index_level, 1
FROM closing_indices AS t1
	INNER JOIN #fx_returns AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.cur_start = 'USA'
WHERE t1.code = 'R2500';

/* Calculate Monthly Return based on morningstar formula */
/* Calculation can be found here: https://awgmain.morningstar.com/webhelp/glossary_definitions/mutual_fund/mfglossary_Total_Return.html */

WITH previous_level AS (
    SELECT t1.code, t1.performance_date, t1.index_level,
        COALESCE((
            SELECT TOP 1 t2.index_level
            FROM closing_indices AS t2
            WHERE t2.code = t1.code
              AND t2.performance_date < t1.performance_date
            ORDER BY t2.performance_date DESC
        ), (
            SELECT TOP 1 hp.index_level
            FROM indices AS hp
            WHERE hp.code = t1.code
            ORDER BY hp.performance_date ASC
        )) AS BeginningPrice
    FROM closing_indices AS t1
)
UPDATE t1
SET 
    monthly_return = CASE
        WHEN pcp.BeginningPrice IS NOT NULL AND pcp.BeginningPrice <> 0 THEN 
            (t1.index_level) / pcp.BeginningPrice - 1
        ELSE
			NULL
    END
FROM closing_indices AS t1
JOIN previous_level AS pcp
    ON t1.code = pcp.code
   AND t1.performance_date = pcp.performance_date;

/* Create blended indices */

INSERT INTO closing_indices(code, index_name, performance_date, monthly_return, blended_index)
SELECT  'BLEND1' AS code, 'Blended Benchmark (50% DEX, 35% S&P/TSX, 15% S&P500 CAD)' AS index_name, t1.performance_date, (t1.monthly_return * 0.5 + t2.monthly_return * 0.35 + t3.monthly_return * 0.15) AS monthly_return, 1
FROM closing_indices AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.code = 'SPTSX'
	INNER JOIN closing_indices AS t3 ON EOMONTH(t1.performance_date) = EOMONTH(t3.performance_date) AND t3.code = 'SPXC'
WHERE t1.code = 'DEX';

INSERT INTO closing_indices(code, index_name, performance_date, monthly_return, blended_index)
SELECT  'BLEND2' AS code, 'Blended Benchmark (50% S&P/TSX, 50% S&P500 CAD)' AS index_name, t1.performance_date, (t1.monthly_return * 0.5 + t2.monthly_return * 0.5) AS monthly_return, 1
FROM closing_indices AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.code = 'SPTSX'
WHERE t1.code = 'SPXC';

INSERT INTO closing_indices(code, index_name, performance_date, monthly_return, blended_index)
SELECT  'BLEND3U' AS code, 'Blended Benchmark (75% ICE BofA, 25% FTSE/TMX USD)' AS index_name, t1.performance_date, (t1.monthly_return * 0.75 + t2.monthly_return * 0.25) AS monthly_return, 1
FROM closing_indices AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.code = 'DEXU'
WHERE t1.code = 'H0A0';

INSERT INTO closing_indices(code, index_name, performance_date, monthly_return, blended_index)
SELECT  'BLEND3C' AS code, 'Blended Benchmark (75% ICE BofA, 25% FTSE/TMX CAD)' AS index_name, t1.performance_date, (t1.monthly_return * 0.75 + t2.monthly_return * 0.25) AS monthly_return, 1
FROM closing_indices AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.code = 'DEX'
WHERE t1.code = 'H0A0C';

INSERT INTO closing_indices(code, index_name, performance_date, monthly_return, blended_index)
SELECT  'BLEND4' AS code, 'Blended Benchmark (9% DEX, 25% ICE BofA, 33% HFRICRDT, 33% HFRIMAI)' AS index_name, t1.performance_date, (t1.monthly_return * 0.09 + t2.monthly_return * 0.25 + t3.monthly_return * 0.33 + t4.monthly_return * 0.33) AS monthly_return, 1
FROM closing_indices AS t1
	INNER JOIN closing_indices AS t2 ON EOMONTH(t1.performance_date) = EOMONTH(t2.performance_date) AND t2.code = 'H0A0'
	INNER JOIN closing_indices AS t3 ON EOMONTH(t1.performance_date) = EOMONTH(t3.performance_date) AND t3.code = 'HFRICRDT'
	INNER JOIN closing_indices AS t4 ON EOMONTH(t1.performance_date) = EOMONTH(t4.performance_date) AND t4.code = 'HFRIMAI'
WHERE t1.code = 'DEXU';

/* Calculate Total Return as Sum of monthly return. See morningstar formula above */
UPDATE closing_indices
SET total_return = (
	SELECT EXP (SUM (LOG (monthly_return+1)))-1 
	FROM closing_indices 
	WHERE code = t1.code AND performance_date <= t1.performance_date)
FROM closing_indices AS t1; 

UPDATE closing_indices 
SET monthly_return = (POWER((1+index_level/100), 0.5)-1)/6
WHERE code = 'CDA2YR';

UPDATE closing_indices
SET excess_return = monthly_return - (
	SELECT TOP 1 monthly_return 
	FROM closing_indices
	WHERE code = 'CDA2YR' AND MONTH(performance_date) = MONTH(t1.performance_date) AND YEAR (performance_date) = YEAR(t1.performance_date))
FROM closing_indices AS t1
WHERE t1.code <> 'CADUSD' AND t1.code <> 'USDCAD' AND t1.code <> 'CDA2YR';

DROP TABLE #fx_returns;

SELECT *
FROM closing_indices
ORDER BY performance_date DESC, code DESC;