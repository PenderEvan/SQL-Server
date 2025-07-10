UPDATE fc
SET 
    fc.total_return = fr.total_return/100,
    fc.price_return = fr.price_return/100
FROM ftse_constituent fc
INNER JOIN ftse_returns fr 
    ON fc.performance_date = fr.ending_date 
    AND fc.mucid = fr.mucid
WHERE fc.total_return IS NULL;


DECLARE @startOfPerf DATETIME = '2025-04-01';
DECLARE @endOfPerf DATETIME = '2025-06-30';

DECLARE @number_of_business_days int = (
	SELECT COUNT(DISTINCT(performance_date))
	FROM ftse_constituent
	WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
);

WITH top_ftse_constituent AS (
    SELECT 
        mucid, price, accrued_interest, adjusted_face_value, adj_face_value_orig_par, market_weight, industry_sector, industry_group, industry_sub_group, term, cusip, issuer_name, maturity_date, eff_mat_date, yield, 
		annual_coupon_rate, d_val_01, performance_date, mac_duration, mod_duration, convexity, rating, isin, country, term_to_maturity, market_value, issue_date, first_payment_date, next_call_date, nvcc_flag, lrcn_at1_flag,
		green_bond_flag, social_bond_flag, sustainability_bond_flag, slb_flag, snapshot_time, currency, direct_perm_id, npi_perm_id, ultimate_parent_perm_id, economic_sector_code, economic_sector_desc, business_sector_code, 
		business_sector_desc, industry_group_code, industry_group_desc, industry_code, industy_desc, activity_code, activity_desc, curve_spread_canyc, spread_to_benchmark, benchmark_cusip, ytw, workout_date, oas_spread, 
		oas_mod_duration, oas_convexity, effective_duration, effective_convexity, rpb_factor,
        ROW_NUMBER() OVER (
            PARTITION BY mucid 
            ORDER BY performance_date DESC
        ) AS rn
    FROM ftse_constituent
    WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
)
SELECT t1.*, t2.adjusted_return, t2.average_mkt_weight
FROM top_ftse_constituent AS t1
JOIN (
	SELECT 
		mucid, 
		MAX(performance_date) AS end_date,
		MIN(performance_date) AS start_date,
		PRODUCT(total_return + 1)-1 AS adjusted_return,
		SUM(market_weight)/ @number_of_business_days AS average_mkt_weight
	FROM ftse_constituent
	WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
	GROUP BY mucid
) AS t2 ON t1.mucid = t2.mucid
WHERE rn = 1
ORDER BY mucid;

SELECT index_id,
	SUM(daily_turnover) AS trailing_twelve_month_turnover,
	MAX(performance_date) AS end_date,
	MIN(performance_date) AS start_date
FROM ftse_index_tier_1
WHERE performance_date BETWEEN @startOfPerf AND @endOfPerf
GROUP BY index_id