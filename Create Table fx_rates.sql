DROP TABLE fx_rates;

CREATE TABLE fx_rates (
	ID int IDENTITY(1,1) PRIMARY KEY,
	performance_date date,
	cur_start varchar(4),
	cur_end varchar(4),
	conversion decimal(18,8)
);