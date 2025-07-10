DECLARE @performance_date date = (SELECT DISTINCT TOP 1 performance_date FROM historical_pricing ORDER BY performance_date DESC);
DECLARE @year_end date = DATEFROMPARTS(YEAR(DATEADD(year, -1, @performance_date)), 12, 31);

CREATE TABLE #index_code_reference(
code varchar(15));

INSERT INTO #index_code_reference(code)
VALUES 
('SPX'),
('SP400CT'),
('DJI'),
('CCMP'),
('IWC'),
('RTY'),
('RAY'),
('XCS'),
('XBB'),
('JNK'),
('LQD'),
('MXEF'),
('SPTSX');

CREATE TABLE #indices_temp(
	code varchar(15),
	index_name varchar(100),
	index_level decimal(18,8),
	performance_date date
);

INSERT INTO #indices_temp(code, index_name, index_level, performance_date)
	SELECT code, index_name, index_level, performance_date 
	FROM indices
	WHERE performance_date >=  DATEFROMPARTS(YEAR(DATEADD(year, -1, @performance_date)), 12, 01) AND code IN (SELECT code FROM #index_code_reference);

INSERT INTO #indices_temp(code, index_name, index_level, performance_date)
	SELECT cur_start, '$CADUSD', conversion, performance_date
	FROM fx_rates
	WHERE cur_start = 'USA' AND performance_date >=  DATEFROMPARTS(YEAR(DATEADD(year, -1, @performance_date)), 12, 01);
	
WITH latest_index AS (
	SELECT
		code,
		index_name,
		index_level,
		performance_date,
		ROW_NUMBER() OVER (PARTITION BY code ORDER BY performance_date DESC) AS row_num
	FROM #indices_temp
	WHERE performance_date <= @performance_date
)
SELECT index_name, index_level, t1.performance_date,
	(index_level / previous_day) -1 AS daily_change, 
	(index_level / previous_week) -1 AS weekly_change, 
	(index_level / end_of_year) -1 AS yearly_change
FROM latest_index AS t1
INNER JOIN (
	SELECT index_level AS previous_day, Code, performance_date, row_num
	FROM latest_index
	) AS t2 ON t2.Code = t1.Code AND t2.row_num = 2
INNER JOIN (
	SELECT index_level AS previous_week, Code, performance_date, row_num
	FROM latest_index
	) AS t3 ON t3.Code = t1.Code AND t3.row_num = 6
INNER JOIN (
	SELECT index_level AS end_of_year, code, performance_date, ROW_NUMBER() OVER (PARTITION BY Code ORDER BY performance_date DESC) AS row_num
	FROM #indices_temp WHERE performance_date <= @year_end
) AS t4 ON t4.code = t1.code AND t4.row_num = 1
WHERE t1.row_num = 1
ORDER BY
	CASE WHEN t1.code = 'USA' THEN 1 ELSE 0 END,
	t1.Code DESC;

DROP TABLE #index_code_reference, #indices_temp;