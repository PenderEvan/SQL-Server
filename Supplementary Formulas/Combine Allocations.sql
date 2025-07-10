INSERT INTO sector_allocation (fund_name, fund_code, sector_type, sector_value, sector_value_short)
SELECT DISTINCT fund_name, fund_code, 'Other Sectors', 0, 0
FROM sector_allocation AS sa
WHERE NOT EXISTS (
    SELECT 1
    FROM sector_allocation AS sa2
    WHERE sa2.fund_code = sa.fund_code
      AND sa2.sector_type = 'Other Sectors'
);

UPDATE sector_allocation
SET sector_value = sector_value + 
	(SELECT SUM(sector_value) 
	FROM sector_allocation 
	WHERE fund_code = t1.fund_code AND sector_value < 0.03 AND sector_type <> 'Cash' AND sector_type <> 'Other Sectors' AND (sector_value_short = 0 OR sector_value_short IS NULL))
FROM sector_allocation AS t1
WHERE sector_type = 'Other Sectors';

UPDATE sector_allocation
SET sector_value = 0
WHERE sector_value < 0.03 AND sector_type <> 'Cash' AND sector_type <> 'Other Sectors' AND (sector_value_short = 0 OR sector_value_short IS NULL);


INSERT INTO asset_allocation(fund_name, fund_code, asset_type, asset_value, asset_value_short)
SELECT DISTINCT fund_name, fund_code, 'Other Assets', 0, 0
FROM asset_allocation AS aa
WHERE NOT EXISTS (
    SELECT 1
    FROM asset_allocation AS aa2
    WHERE aa2.fund_code = aa.fund_code
      AND aa2.asset_type = 'Other Assets'
);

UPDATE asset_allocation
SET asset_value = asset_value + 
	(SELECT SUM(asset_value) 
	FROM asset_allocation 
	WHERE fund_code = t1.fund_code AND asset_value < 0.03 AND asset_type <> 'Cash' AND asset_type <> 'Other Assets'  AND (asset_value_short = 0 OR asset_value_short IS NULL))
FROM asset_allocation AS t1
WHERE asset_type = 'Other Assets';

UPDATE asset_allocation
SET asset_value = 0
WHERE asset_value < 0.03 AND asset_type <> 'Cash' AND asset_type <> 'Other Assets' AND (asset_value_short = 0 OR asset_value_short IS NULL);

UPDATE top_ten_holdings
SET ticker = ''
WHERE ticker = '0' OR ticker = '(Invalid Identifier)'

DELETE FROM sector_allocation
WHERE (sector_value = 0 OR sector_value IS NULL) AND (sector_value_short = 0 OR sector_value_short IS NULL);

DELETE FROM asset_allocation
WHERE (asset_value = 0 OR asset_value IS NULL) AND (asset_value_short = 0 OR asset_value_short IS NULL);

DELETE FROM currency_allocation
WHERE (currency_value = 0 OR currency_value IS NULL) AND (currency_value_short = 0 OR currency_value_short IS NULL); 

DELETE FROM geography_allocation
WHERE (geography_value = 0 OR geography_value IS NULL) AND (geography_value_short = 0 OR geography_value_short IS NULL); 

DELETE FROM market_cap_allocation
WHERE (market_cap_value = 0 OR market_cap_value IS NULL) AND (market_cap_value_short = 0 OR market_cap_value_short IS NULL); 

UPDATE top_ten_holdings
SET fund_name = 'Pender Strategic Growth and Income Fund'
WHERE fund_name = 'Pender Strategic Growth & Income Fund'

UPDATE asset_info
SET fund_name = 'Pender Strategic Growth and Income Fund'
WHERE fund_name = 'Pender Strategic Growth & Income Fund'

UPDATE asset_allocation
SET fund_name = 'Pender Strategic Growth and Income Fund'
WHERE fund_name = 'Pender Strategic Growth & Income Fund'

UPDATE sector_allocation
SET fund_name = 'Pender Strategic Growth and Income Fund'
WHERE fund_name = 'Pender Strategic Growth & Income Fund'

UPDATE currency_allocation
SET fund_name = 'Pender Strategic Growth and Income Fund'
WHERE fund_name = 'Pender Strategic Growth & Income Fund'

DELETE FROM top_ten_holdings
WHERE top_ten_holding = '0';