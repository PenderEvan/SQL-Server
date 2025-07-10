DROP TABLE indices;
DROP TABLE closing_indices;

CREATE TABLE indices(
	ID int IDENTITY(1,1) PRIMARY KEY,
	code varchar(15),
	index_name varchar(100),
	performance_date date,
	index_level decimal(18, 8)
);

CREATE TABLE closing_indices(
	id int IDENTITY(1,1) PRIMARY KEY,
	code varchar(15),
	index_name varchar(100),
	performance_date date,
	index_level decimal(18, 8),
	monthly_return decimal(18, 8),
	total_return decimal(18, 8),
	excess_return decimal(18, 8),
	blended_index int
);