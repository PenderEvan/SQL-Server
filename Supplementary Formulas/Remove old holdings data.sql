DELETE FROM currency_allocation
WHERE performance_date <> (SELECT TOP 1 performance_date FROM currency_allocation ORDER BY performance_date DESC);

DELETE FROM asset_allocation
WHERE performance_date <> (SELECT TOP 1 performance_date FROM asset_allocation ORDER BY performance_date DESC);

DELETE FROM sector_allocation
WHERE performance_date <> (SELECT TOP 1 performance_date FROM sector_allocation ORDER BY performance_date DESC);

DELETE FROM top_ten_holdings
WHERE performance_date <> (SELECT TOP 1 performance_date FROM top_ten_holdings ORDER BY performance_date DESC);

DELETE FROM asset_info
WHERE performance_date <> (SELECT TOP 1 performance_date FROM asset_info ORDER BY performance_date DESC);

DELETE FROM asset_allocation
WHERE asset_value = 0;

DELETE FROM sector_allocation
WHERE sector_value = 0;

DELETE FROM currency_allocation
WHERE currency_value = 0;