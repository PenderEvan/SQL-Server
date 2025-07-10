TRUNCATE TABLE index_performance;
DECLARE @startOfCurrentMonth DATETIME = DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0);
DECLARE @startOfPerf DATETIME = DATEADD(month, -1, @startOfCurrentMonth);
DECLARE @endOfPerf DATETIME = EOMONTH(@startOfPerf);

INSERT INTO index_performance(code, index_name, performance_date, one_month, total_return) 
SELECT 
	code, index_name, performance_date, monthly_return, total_return
FROM closing_indices
WHERE EOMONTH(performance_date) = @endOfPerf;


WITH prev_prices AS (
    SELECT t1.Code, t1.performance_date,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(month, -3, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS three_month_prev,
        (SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(month, -6, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS six_month_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -1, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS one_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -2, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS two_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -3, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS three_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -5, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS five_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -10, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS ten_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND t2.performance_date <= EOMONTH(DATEADD(year, -15, t1.performance_date))
            ORDER BY t2.performance_date DESC) AS fifteen_year_prev,
		(SELECT TOP 1 t2.total_return
            FROM closing_indices AS t2
            WHERE t2.Code = t1.Code
              AND MONTH(t2.performance_date) = 12
			  AND YEAR(t2.performance_date) = YEAR(t1.performance_date)-1
            ORDER BY t2.performance_date DESC) AS end_of_year
    FROM closing_indices AS t1
	WHERE EOMONTH(performance_date) = @endOfPerf
)
UPDATE t1
SET three_month = (total_return+1) / (pp.three_month_prev+1) - 1,
	six_month = (total_return+1) / (pp.six_month_prev+1) - 1,
	one_year = (total_return+1) / (pp.one_year_prev+1) - 1,
	two_year = POWER((total_return+1) / (pp.two_year_prev+1), 0.5) - 1,
	three_year = POWER((total_return+1) / (pp.three_year_prev+1), 0.33333333) - 1,
	five_year = POWER((total_return+1) / (pp.five_year_prev+1), 0.2) - 1,
	ten_year = POWER((total_return+1) / (pp.ten_year_prev+1), 0.1) - 1,
	fifteen_year = POWER((total_return+1) / (pp.fifteen_year_prev+1), 0.06666666) - 1,
	YTD = (total_return+1) / (pp.end_of_year+1) - 1
FROM index_performance AS t1
JOIN prev_prices AS pp
   ON t1.Code = pp.Code

UPDATE index_performance 
SET Y2010 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2010 AND
			MONTH(previous.performance_date) = 12
		) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2009 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2011 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2011 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2010 AND
			MONTH(previous.performance_date) = 12
		) - 1),
	Y2012 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2012 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2011 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2013 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2013 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2012 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2014 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2014 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2013 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2015 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2015 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2014 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2016 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2016 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2015 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2017 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2017 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2016 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2018 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2018 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2017 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2019 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2019 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2018 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2020 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2020 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2019 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2021 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2021 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2020 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2022 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2022 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2021 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2023 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2023 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2022 AND
			MONTH(previous.performance_date) = 12
	) - 1),
	Y2024 = ((SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2024 AND
			MONTH(previous.performance_date) = 12
	) / 
	(SELECT TOP 1 previous.total_return
		FROM closing_indices previous
		WHERE previous.Code = index_performance.Code AND
			YEAR(previous.performance_date) = 2023 AND
			MONTH(previous.performance_date) = 12
	) - 1);

SELECT * FROM index_performance ORDER BY Code