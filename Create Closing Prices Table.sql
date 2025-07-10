DROP TABLE ClosingPrices;

CREATE TABLE ClosingPrices(
	ID int IDENTITY(1,1) PRIMARY KEY,
	Code int,
	FundName varchar(100),
	PerformanceDate date,
	ClosingPrice decimal(18, 8),
	TotalSharesOutstanding decimal(18,8),
	TotalNetAssets decimal(18,8),
	DistributionFactor decimal(18, 8),
	ReinvestmentPrice decimal(18, 8),
	TotalDistribution decimal(18,8),
	TotalReturn decimal(18,8),
	GrowthOf10k decimal(18, 8),
	Peak decimal(18, 8),
	Drawdown decimal(18, 8),
	MonthlyReturn decimal(18, 8),
	ThreeMonthReturn decimal(18, 8),
	TwelveMonthReturn decimal(18, 8),
	ExcessReturn decimal(18,8),
	TempColumn int
);

DROP TABLE growth_of_10k;

CREATE TABLE growth_of_10k (
	id int IDENTITY(1,1) PRIMARY KEY,
	code int,
	fund_name varchar(100),
	performance_date date,
	growth_of_10k decimal(18, 8),
);