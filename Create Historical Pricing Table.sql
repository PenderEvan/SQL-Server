DROP TABLE historical_pricing;

CREATE TABLE historical_pricing (
	Id int IDENTITY(1,1) PRIMARY KEY,
	code varchar(50),
	fund_name varchar(255),
	performance_date date,
	unit_price decimal(18, 8),
	distribution_factor decimal(18, 8),
	total_shares_outstanding decimal(18, 8),
	total_net_assets decimal(18,8)
);