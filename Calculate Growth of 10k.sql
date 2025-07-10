TRUNCATE TABLE dbo.growth_of_10k;

/* Insert starting NAVs that do not start month end */
INSERT INTO growth_of_10k(code, fund_name, performance_date, growth_of_10k)
VALUES
/* Pender Growth Fund */
	(100, 'Pender Growth Fund - C', '2010-07-26', 10000),
	(101, 'Pender Growth Fund - C (IFRS)', '2010-07-26', 10000),
/* Pender Small Cap Opps Funds */
	(315, 'Pender Small Cap Opportunities Fund - A', '2009-06-01', 10000),
	(320, 'Pender Small Cap Opportunities Fund - F', '2009-06-01', 10000),
	(340, 'Pender Small Cap Opportunities Fund - O', '2011-06-24', 10000),
	(372, 'Pender Small Cap Opportunities Fund - M', '2021-06-25', 10000),
/* Pender Corporate Bond Fund */
	(500, 'Pender Corporate Bond Fund - A', '2009-06-01', 10000),
	(510, 'Pender Corporate Bond Fund - F', '2009-06-01', 10000),
	(530, 'Pender Corporate Bond Fund - O', '2010-11-24', 10000),
	(540, 'Pender Corporate Bond Fund - H', '2012-06-19', 10000),
/* Pender Strategic Growth and Income Fund */
	(1000, 'Pender Enhanced Income Fund - A', '2019-12-15', 10000),
	(1010, 'Pender Enhanced Income Fund - F', '2019-12-15', 10000),
	(1040, 'Pender Strategic Growth & Income Fund - H', '2023-06-27', 10000),
/* Pender Partners Fund */
	(1113, 'Pender Partners Fund - F2', '1998-04-03', 10000),
/* Pender Alternative Multi-Strategy Income Fund */
	(1200, 'Pender Alternative Multi-Strategy Income Fund - A', '2022-09-01', 10000),
	(1208, 'Pender Alternative Multi-Strategy Income Fund - E', '2022-09-01', 10000),
	(1210, 'Pender Alternative Multi-Strategy Income Fund - F', '2022-09-01', 10000),
	(1230, 'Pender Alternative Multi-Strategy Income Fund - O', '2022-09-01', 10000),
	(1250, 'Pender Alternative Multi-Strategy Income Fund - I', '2022-09-01', 10000),
/* Pender Alternative Special Situations Fund */
	(1500, 'Pender Alternative Special Situations Fund - A', '2020-07-10', 10000),
	(1508, 'Pender Alternative Special Situations Fund - E', '2021-06-25', 10000),
	(1510, 'Pender Alternative Special Situations Fund - F', '2020-07-10', 10000),
	(1530, 'Pender Alternative Special Situations Fund - O', '2021-06-25', 10000),
	(1540, 'Pender Alternative Special Situations Fund - H', '2021-06-25', 10000),
	(1550, 'Pender Alternative Special Situations Fund - I', '2021-06-25', 10000),
/* Pender Alt Absolute Return Fund */
	(2000, 'Pender Alternative Absolute Return Fund - A', '2021-09-01', 10000),
	(2001, 'Pender Alternative Absolute Return Fund - A (USD)', '2022-09-01', 10000),
	(2002, 'Pender Alternative Absolute Return Fund - AF', '2021-09-01', 10000),
	(2008, 'Pender Alternative Absolute Return Fund - E', '2022-09-01', 10000),
	(2010, 'Pender Alternative Absolute Return Fund - F', '2021-09-01', 10000),
	(2011, 'Pender Alternative Absolute Return Fund - F (USD)', '2022-09-01', 10000),
	(2012, 'Pender Alternative Absolute Return Fund - FF', '2021-09-01', 10000),
	(2030, 'Pender Alternative Absolute Return Fund - O', '2021-09-01', 10000),
	(2040, 'Pender Alternative Absolute Return Fund - H', '2021-09-01', 10000),
	(2041, 'Pender Alternative Absolute Return Fund - H (USD)', '2022-09-01', 10000),
	(2050, 'Pender Alternative Absolute Return Fund - I', '2021-09-01', 10000),
	(2051, 'Pender Alternative Absolute Return Fund - I (USD)', '2022-09-01', 10000),
	(2070, 'Pender Alternative Absolute Return Fund - N', '2021-09-01', 10000),
/* Pender Alt Arbitrage Fund */
	(2100, 'Pender Alternative Arbitrage Fund - A', '2021-09-08', 10000),
	(2101, 'Pender Alternative Arbitrage Fund - A (USD)', '2022-09-01', 10000),
	(2102, 'Pender Alternative Arbitrage Fund - AF', '2021-09-08', 10000),
	(2108, 'Pender Alternative Arbitrage Fund - E', '2022-09-01', 10000),
	(2110, 'Pender Alternative Arbitrage Fund - F', '2021-09-08', 10000),
	(2111, 'Pender Alternative Arbitrage Fund - F (USD)', '2022-09-01', 10000),
	(2112, 'Pender Alternative Arbitrage Fund - FF', '2021-09-08', 10000),
	(2130, 'Pender Alternative Arbitrage Fund - O', '2021-09-08', 10000),
	(2140, 'Pender Alternative Arbitrage Fund - H', '2021-09-08', 10000),
	(2150, 'Pender Alternative Arbitrage Fund - I', '2021-09-08', 10000),
	(2151, 'Pender Alternative Arbitrage Fund - I (USD)', '2022-09-01', 10000),
/* Pender Alt Arbitrage Plus Fund */
	(2200, 'Pender Alternative Arbitrage Plus Fund - A', '2022-09-01', 10000),
	(2208, 'Pender Alternative Arbitrage Plus Fund - E', '2022-09-01', 10000),
	(2210, 'Pender Alternative Arbitrage Plus Fund - F', '2022-09-01', 10000),
	(2211, 'Pender Alternative Arbitrage Plus Fund - F (USD)', '2022-09-01', 10000),
	(2230, 'Pender Alternative Arbitrage Plus Fund - O', '2022-09-01', 10000),
	(2250, 'Pender Alternative Arbitrage Plus Fund - I', '2022-09-01', 10000),
	(2251, 'Pender Alternative Arbitrage Plus Fund - I (USD)', '2022-09-01', 10000);

/* Calculate DistributionProduct, calculating year end values using temporary reinvestment price rows
Then calculate growth of 10k before deleting temporary values */

INSERT INTO growth_of_10k
SELECT Code, FundName, PerformanceDate, GrowthOf10k FROM ClosingPrices

SELECT *
FROM growth_of_10k
ORDER BY performance_date DESC, code DESC