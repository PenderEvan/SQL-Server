DROP TABLE general_info;
DROP TABLE fund_info;
DROP TABLE class_info;
DROP TABLE category_info;
DROP TABLE portfolio_manager_info;
DROP TABLE award_info;
DROP TABLE fund_pms;

DROP TABLE asset_translations;
DROP TABLE currency_translations;
DROP TABLE sector_translations;
DROP TABLE geography_translations;
DROP TABLE market_cap_translations;

DROP TABLE general_info_french;
DROP TABLE fund_info_french;
DROP TABLE class_info_french;
DROP TABLE category_info_french;
DROP TABLE portfolio_manager_info_french;

CREATE TABLE general_info (
	Id int IDENTITY(1,1) PRIMARY KEY,
	copyright varchar(100),
	about_pender varchar(1000),
	street_address varchar(50),
	city varchar(20),
	province varchar(2),
	postal_code varchar(6),
	toll_free_number varchar(15),
	phone_number varchar(15),
	fax varchar(15),
	website varchar(50),
	twitter varchar(100),
	linkedin varchar(100),
	email varchar(255),
	performance_fee_footnote varchar(200)
);

Create TABLE category_info(
	category varchar(50) PRIMARY KEY,
	disclaimer varchar(1500)
);

CREATE TABLE fund_info (
	code int PRIMARY KEY,
	fund_name varchar(50),
	class varchar(7),
	holdings_source varchar(50),
	nav_footnote varchar(100),
	fund_description varchar(1000),
	legal_counsel varchar(50),
	fund_administrator varchar(30),
	auditor varchar(30),
	category varchar(50),
	asset_class varchar(50),
	valuation varchar(20),
	eligibility varchar(50),
	distributions varchar(50),
	waiver_of_fees_footnote varchar(200),
	since_inception_footnote varchar(200),
);

CREATE TABLE class_info (
	code int PRIMARY KEY,
	fund_name varchar(50),
	class varchar(7),
	mer decimal(6,4),
	mer_without_perf_fee decimal(6,4),
	mer_without_hst_gst_perf_fee decimal(6,4),
	mgnt decimal(6,4),
	admin_fee decimal(6,4),
	trailer decimal(6,4),
	performance_fee varchar(100),
	performance_fee_footnote varchar(250),
	min_initial_investment int,
	min_subsequent_investment int,
	fund_type varchar(50),
	mer_date date
);

CREATE TABLE portfolio_manager_info (
	pm_name varchar(50) PRIMARY KEY,
	title varchar(100),
	designation varchar(20), /* CFA, etc. */
	excerpt varchar(250), /* Shortened description */
	pm_description varchar(2000),
	pm_url varchar(255),
	phone_number varchar(15),
	twitter varchar(255),
	linkedin varchar(255),
	email varchar(255)
);

CREATE TABLE award_info (
	Id int IDENTITY(1,1) PRIMARY KEY,
	code int, /* this is the fund code that received the award */
	award_name varchar(150),
	award_year int
);

CREATE TABLE fund_pms (
	Id int IDENTITY(1,1) PRIMARY KEY,
	fund_name varchar(50),
	pm_name varchar(50),
	pm_priority int
);

CREATE TABLE general_info_french (
	Id int IDENTITY(1,1) PRIMARY KEY,
	copyright varchar(100),
	about_pender varchar(1000),
	street_address varchar(50),
	performance_fee_footnote varchar(200)
);

Create TABLE category_info_french(
	category varchar(50) PRIMARY KEY,
	category_french varchar(50),
	disclaimer varchar(1500)
);

CREATE TABLE fund_info_french (
	code int PRIMARY KEY,
	fund_name varchar(50),
	fund_name_french varchar(100),
	holdings_source varchar(50),
	fund_description varchar(1500),
	category varchar(50),
	asset_class varchar(50),
	valuation varchar(20),
	eligibility varchar(100),
	distributions varchar(50),
	waiver_of_fees_footnote varchar(200),
	since_inception_footnote varchar(200),
);

CREATE TABLE class_info_french (
	code int PRIMARY KEY,
	fund_name varchar(50),
	fund_name_french varchar(100),
	performance_fee varchar(100),
	performance_fee_footnote varchar(250),
	fund_type varchar(50)
);

CREATE TABLE portfolio_manager_info_french (
	pm_name varchar(50) PRIMARY KEY,
	title varchar(100),
	pm_description varchar(2000),
	pm_url varchar(255)
);

CREATE TABLE asset_translations (
	english varchar(150) PRIMARY KEY,
	french varchar(150)
);

CREATE TABLE currency_translations (
	english varchar(150) PRIMARY KEY,
	french varchar(150)
);

CREATE TABLE sector_translations (
	english varchar(150) PRIMARY KEY,
	french varchar(150)
);

CREATE TABLE geography_translations (
	english varchar(150) PRIMARY KEY,
	french varchar(150)
);

CREATE TABLE market_cap_translations (
	english varchar(150) PRIMARY KEY,
	french varchar(150)
);

INSERT INTO asset_translations(english, french)
VALUES 
	('Cash', 'Trésorerie'),
	('Canadian Equities', 'Actions canadiennes'),
	('Canadian Corporate Bonds', 'Obligations de sociétés can.'),
	('Closed End Funds', 'Fonds de placement à capital fixe'),
	('Credit ETF', 'FNB de titres de créances'),
	('Equity ETF', 'FNB d’actions'),
	('Foreign Corporate Bonds', 'Obligations de sociétés étr.'),
	('Foreign Equities', 'Actions étrangères'),
	('Government Bonds', 'Obligations gouvernementales'), 
	('Term Loans', 'Prêts à terme'),
	('US Corporate Bonds', 'Obligations de sociétés É.-U.'),
	('US Equities', 'Actions américaines'),
	('Other Assets', 'Autres actifs');

INSERT INTO currency_translations(english, french)
VALUES ('Cad', 'Canada'),
	('Usd', 'États-Unis'),
	('Other', 'Autres secteurs'),
	('Cash', 'Trésorerie');

INSERT INTO sector_translations(english, french)
VALUES ('Banks', 'Banques'), 
	('Cash', 'Trésorerie'),
	('Closed End Funds', 'Fonds de placement à capital fixe'), 
	('Consumer Discretionary', 'Consommation discrétionnaire'),
	('Consumer Staples','Biens de consommation de base'),
	('Communication Services', 'Services de communication'),
	('Credit ETF', 'FNB de titres de créances'),
	('Financial Services', 'Services financiers diversifiés'),
	('Energy', 'Énergie'),
	('Equity ETF', 'FNB d’actions'),
	('Exchange Traded Funds', 'Fonds négociés en bourse'), 
	('Government Bonds', 'Obligations gouvernementales'), 
	('Health Care', 'Santé'), 
	('Insurance', 'Assurance'), 
	('Industrials', 'Produits industriels'), 
	('Information Technology', 'Technologie de l’information'), 
	('Materials', 'Matériaux'),
	('Real Estate', 'Immobilier'),
	('Utilities', 'Services aux collectivités'),
	('Other Sectors', 'Autres secteurs');

INSERT INTO geography_translations(english, french)
VALUES ('Canada', 'Canada'),
	('United States', 'États-Unis'),
	('International', 'International'),
	('Cash', 'Trésorerie');

INSERT INTO market_cap_translations(english, french)
VALUES ('Nano', 'Nano'),
	('Micro', 'Micro'),
	('Small', 'Petite'),
	('Mid', 'Moyenne'),
	('Large', 'Grande'),
	('Mega', 'Méga'),
	('Non public equity', 'Actions non cotées en bourse'),
	('Cash', 'Trésorerie');
