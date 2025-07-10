/* DELETE FROM transaction_history WHERE TranType <> 'BUY' AND TranType <> 'SEL' AND TranType <> 'SWO' AND TranType <> 'SWI'; */

UPDATE transaction_history 
SET gross_amount_base = 
	CASE
		WHEN t1.fund_code % 10 = 1 AND t1.fund_code > 200 THEN gross_amount_local * (SELECT TOP 1 conversion FROM fx_rates WHERE performance_date <= t1.trade_date AND cur_start = 'USA' ORDER BY performance_date DESC)
		ELSE gross_amount_local
	END
FROM transaction_history AS t1


UPDATE transaction_history 
SET net_sales_local = gross_amount_local - (gross_amount_local * commission / 100),
net_sales_base = gross_amount_base - (gross_amount_base * commission / 100),
dealer_rep_code = dealer_code + '-' + rep_code,
fund_name_short = t2.fund_name_short
FROM transaction_history AS t1
LEFT JOIN fund_name_reference AS t2 ON t2.fund_code = (CASE 
        WHEN t1.fund_code > 370 AND t1.fund_code < 400 THEN 371  -- Group 371–399 as 370
		WHEN t1.fund_code = 141 THEN 141
        ELSE (t1.fund_code / 100) * 100  -- Otherwise group by fund_code/100
    END);

UPDATE transaction_history 
SET net_sales_local = net_sales_local * -1,
net_sales_base = net_sales_base * -1
WHERE tran_type = 'SEL' OR tran_type = 'SWO';

UPDATE transaction_history 
SET net_sales_local = net_sales_local * -1,
net_sales_base = net_sales_base * -1
WHERE transaction_status = 'RVS';

/* Unrealized Gain/Loss */
UPDATE trial_balance SET aum_base = 
	CASE
		WHEN t1.fund_code % 10 = 1 AND t1.fund_code > 200 THEN aum_local * (SELECT TOP 1 conversion FROM fx_rates WHERE performance_date <= t1.last_process_date AND cur_start = 'USA' ORDER BY performance_date DESC)
		ELSE aum_local
	END,
fund_name_short = t2.fund_name_short
FROM trial_balance AS t1
LEFT JOIN fund_name_reference AS t2 ON t2.fund_code = (CASE 
        WHEN t1.fund_code > 370 AND t1.fund_code < 400 THEN 371  -- Group 371–399 as 370
		WHEN t1.fund_code = 141 THEN 141
        ELSE (t1.fund_code / 100) * 100  -- Otherwise group by fund_code/100
    END);

UPDATE trial_balance SET dealer_rep_code = dealer_code + '-' + rep_code,
gain_loss_local = aum_local - cost_basis;

UPDATE trial_balance SET 
gain_loss_base = CASE
		WHEN fund_code % 10 = 1 AND fund_code > 200 THEN gain_loss_local * (SELECT TOP 1 conversion FROM fx_rates WHERE performance_date <= t1.last_process_date AND cur_start = 'USA' ORDER BY performance_date DESC)
		ELSE gain_loss_local
	END
FROM trial_balance AS t1;

/* Pull account dealer rep codes from trial balance */
UPDATE transaction_history
SET account_dealer_rep_code = t2.dealer_rep_code
FROM transaction_history AS t1
LEFT JOIN (
	SELECT account_number, dealer_rep_code
	FROM trial_balance
) t2 ON t1.account_number = t2.account_number 
WHERE t1.dealer_rep_code = '9190-1G8' OR t1.dealer_rep_code = '9190-01G8'

UPDATE transaction_history
SET account_dealer_rep_code = dealer_rep_code
WHERE account_dealer_rep_code IS NULL

/* generate position summary table */

TRUNCATE TABLE position_summary;

INSERT INTO position_summary(dealer_rep_code, fund_name_short, sum_aum_local, sum_aum_base, sum_gain_loss_local, sum_gain_loss_base, last_process_date)
SELECT dealer_rep_code,fund_name_short,
	SUM(aum_local) AS sum_aum_local, SUM(aum_base) AS sum_aum_base, SUM(gain_loss_local) AS sum_gain_loss, SUM(gain_loss_base) AS sum_gain_loss_base, last_process_date
FROM trial_balance AS t1
GROUP BY dealer_rep_code, last_process_date,fund_name_short
ORDER BY dealer_rep_code DESC;

UPDATE position_summary
SET fund_name = t2.fund_name
FROM position_summary AS t1
LEFT JOIN fund_name_reference AS t2 ON t1.fund_name_short = t2.fund_name_short

TRUNCATE TABLE transaction_summary;

WITH sells AS (
	SELECT dealer_rep_code, fund_name_short,
		SUM(net_sales_base) AS total_redemptions_fy, 
		MAX(trade_date) AS last_proc_date
	FROM transaction_history
	WHERE net_sales_base < 0
	GROUP BY CASE 
        WHEN MONTH(trade_date) >= 4 THEN YEAR(trade_date) + 1
        ELSE YEAR(trade_date)
    END,
	dealer_rep_code,
	fund_name_short
),
buys AS (
	SELECT dealer_rep_code, fund_name_short,
		SUM(net_sales_base) AS total_purchases_fy,
		MAX(trade_date) AS last_proc_date
	FROM transaction_history
	WHERE net_sales_base > 0
	GROUP BY CASE 
        WHEN MONTH(trade_date) >= 4 THEN YEAR(trade_date) + 1
        ELSE YEAR(trade_date)
    END,
	dealer_rep_code,
	fund_name_short
)
INSERT INTO transaction_summary (dealer_rep_code, fund_name_short, last_proc_date, total_redemptions_fy, total_purchases_fy, net_purchases)
SELECT ISNULL(t1.dealer_rep_code, t2.dealer_rep_code), 
ISNULL(t1.fund_name_short, t2.fund_name_short),
ISNULL(t1.last_proc_date, t2.last_proc_date), 
ISNULL(total_redemptions_fy, 0), 
ISNULL(total_purchases_fy, 0), 
ISNULL(total_purchases_fy, 0) + ISNULL(total_redemptions_fy, 0)
FROM sells AS t1
FULL JOIN buys AS t2 
	ON t1.dealer_rep_code = t2.dealer_rep_code 
	AND t1.last_proc_date = t2.last_proc_date;

TRUNCATE TABLE dealer_rep_code_summary;

INSERT INTO dealer_rep_code_summary(dealer_rep_code, last_proc_date, total_purchases_fy, total_redemptions_FY, net_purchases_FY)
SELECT t1.dealer_rep_code, last_proc_date, SUM(t1.total_purchases_fy), SUM(t1.total_redemptions_FY), SUM(t1.net_purchases)
FROM transaction_summary AS t1
GROUP BY dealer_rep_code, last_proc_date;

UPDATE dealer_rep_code_summary
SET sum_aum_base =  t2.sum_aum_base,
sum_gain_loss_base = t2.sum_gain_loss_base
FROM dealer_rep_code_summary AS t1
LEFT JOIN (
	SELECT ps.dealer_rep_code,
       ps.last_process_date,
       ps.sum_aum_base,
       ps.sum_gain_loss_base
FROM position_summary ps
WHERE ps.last_process_date = (
    SELECT MAX(ps2.last_process_date)
    FROM position_summary ps2
    WHERE ps2.dealer_rep_code = ps.dealer_rep_code
)) AS t2 ON t1.dealer_rep_code = t2.dealer_rep_code;

UPDATE pending_transactions
SET dealer_rep_code = dealer_code + '-' + rep_code,
gross_amount_base = CASE
		WHEN t1.fund_code % 10 = 1 THEN gross_amount_local * (SELECT TOP 1 conversion FROM fx_rates WHERE performance_date <= t1.trade_date AND cur_start = 'USA' ORDER BY performance_date DESC)
		ELSE gross_amount_local
	END,
fund_name_short = t2.fund_name_short
FROM pending_transactions AS t1
LEFT JOIN fund_name_reference AS t2 ON t2.fund_code = (CASE 
        WHEN t1.fund_code > 370 AND t1.fund_code < 400 THEN 371
		WHEN t1.fund_code = 141 THEN 141
        ELSE (t1.fund_code / 100) * 100
    END);