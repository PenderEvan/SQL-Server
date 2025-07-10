/*

UPDATE ice_constituent
SET prr_1_day_loc = prr_1_day_loc / 100,
prr_index_val_loc = prr_index_val_loc / 100,
trr_1_day_loc = trr_1_day_loc / 100,
prr_1_day_usd_u = prr_1_day_usd_u / 100,
prr_1_day_cad_u = prr_1_day_cad_u / 100,
trr_1_day_usd_u = trr_1_day_usd_u / 100,
trr_1_day_cad_u = trr_1_day_cad_u / 100

*/

UPDATE t1
SET t1.total_market_value = t2.total_market_value
FROM ice_constituent AS t1
JOIN (
	SELECT performance_date, 
	SUM(full_market_value_loc) AS total_market_value
	FROM ice_constituent
	GROUP BY performance_date
) AS t2 ON t1.performance_date = t2.performance_date
WHERE t1.total_market_value IS NULL

UPDATE ice_constituent
SET market_weight = full_market_value_loc / total_market_value
WHERE market_weight IS NULL

DECLARE @startOfPerf DATETIME = '2025-01-01';
DECLARE @endOfPerf DATETIME = '2025-06-30';

DECLARE @number_of_business_days int = (
	SELECT COUNT(DISTINCT(performance_date))
	FROM ftse_constituent
	WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
);

WITH top_ice_constituent AS (
    SELECT 
        cusip, isin_number, index_description, maturity_date, issue_date, par_amount, convexity, current_yield, current_coupon, eff_duration, macaulay_duration, modified_duration, spread_duration, rating, accrued_interest, cash, price, full_market_value_loc, oas, yield_to_maturity, semi_yield_to_worst, rating_middle_of_three,
        ROW_NUMBER() OVER (
            PARTITION BY cusip 
            ORDER BY performance_date DESC
        ) AS rn
    FROM ice_constituent
    WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
)
SELECT t1.*, t2.adjusted_return, t2.average_mkt_weight
FROM top_ice_constituent AS t1
JOIN (
	SELECT 
		cusip, 
		MAX(performance_date) AS end_date,
		MIN(performance_date) AS start_date,
		-- EXP (SUM (LOG (trr_1_day_cad_u + 1)))-1 AS adjusted_return,
		PRODUCT(trr_1_day_cad_u + 1)-1 AS adjusted_return,
		SUM(ISNULL(market_weight,0) )/ @number_of_business_days AS average_mkt_weight
	FROM ice_constituent
	WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
		AND cusip <> 'CASHUSD0'
	GROUP BY cusip
) AS t2 ON t1.cusip = t2.cusip
WHERE rn = 1;

WITH id_list AS (
	SELECT DISTINCT(cusip) AS id
	FROM ice_constituent
	WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
),
id_start AS (
	SELECT DISTINCT(cusip) AS id
	FROM ice_constituent
	WHERE performance_date = (
		SELECT MIN(performance_date) 
		FROM ice_constituent 
		WHERE performance_date >= @startOfPerf
	) 
),
id_end AS (
	SELECT DISTINCT(cusip) AS id
	FROM ice_constituent
	WHERE performance_date = (
		SELECT MAX(performance_date) 
		FROM ice_constituent 
		WHERE performance_date <= @endOfPerf
	)
)
SELECT id, t2.buys, t3.sells
FROM id_list AS t1
FULL OUTER JOIN (
	SELECT cusip, full_market_value_loc AS buys
	FROM (
		SELECT cusip, full_market_value_loc,
			   ROW_NUMBER() OVER (PARTITION BY cusip ORDER BY performance_date ASC) AS rn
		FROM ice_constituent
		WHERE cusip IN (SELECT id FROM id_list)
		  AND cusip NOT IN (SELECT id FROM id_start)
		  AND performance_date BETWEEN @startOfPerf AND @endOfPerf
	) AS ranked_buys
	WHERE rn = 1
) AS t2 ON t1.id = t2.cusip
FULL OUTER JOIN (
	SELECT cusip, full_market_value_loc AS sells
	FROM (
		SELECT cusip, full_market_value_loc,
			   ROW_NUMBER() OVER (PARTITION BY cusip ORDER BY performance_date DESC) AS rn
		FROM ice_constituent
		WHERE cusip IN (SELECT id FROM id_list)
		  AND cusip NOT IN (SELECT id FROM id_end)
		  AND performance_date BETWEEN @startOfPerf AND @endOfPerf
	) AS ranked_sells
	WHERE rn = 1
) AS t3 ON t1.id = t3.cusip
WHERE buys IS NOT NULL OR sells IS NOT NULL

SELECT MAX(performance_date) AS performance_start, 
	SUM(full_market_value_loc) AS total_full_market_value_loc_beginning
FROM ice_constituent
WHERE performance_date = (
	SELECT MIN(performance_date) 
	FROM ice_constituent 
	WHERE performance_date >= @startOfPerf
) 

SELECT MAX(performance_date) AS performance_end, 
	SUM(full_market_value_loc) AS total_full_market_value_loc_end
FROM ice_constituent
WHERE performance_date = (
	SELECT MAX(performance_date) 
	FROM ice_constituent 
	WHERE performance_date <= @endOfPerf
) 