DROP TABLE fx_rates;
CREATE TABLE fx_rates(
	id int IDENTITY(1,1) PRIMARY KEY,
	performance_date date,
	cur_start varchar(3),
	cur_end varchar(3),
	conversion decimal(18,8)
)

DROP TABLE fund_name_reference;
CREATE TABLE fund_name_reference(
	id int IDENTITY(1,1) PRIMARY KEY,
	fund_code int,
	fund_name_short varchar(15),
	fund_name varchar(100)
);

INSERT INTO fund_name_reference(fund_code, fund_name_short, fund_name)
VALUES (2000, 'PAAR', 'PENDER ALTERNATIVE ABSOLUTE RETURN FUND'),
(2100, 'PAAF', 'PENDER ALTERNATIVE ARBITRAGE FUND'),
(2200, 'PAAP', 'PENDER ALTERNATIVE ARBITRAGE PLUS FUND'),
(1200, 'PAMSF', 'PENDER ALTERNATIVE MULTI-STRATEGY INCOME FUND'),
(1500, 'PASSF', 'PENDER ALTERNATIVE SPECIAL SITUATIONS FUND'),
(1400, 'PBUF', 'PENDER BOND UNIVERSE FUND'),
(500, 'PCBF', 'PENDER CORPORATE BOND FUND'),
(1600, 'PIAF', 'PENDER INCOME ADVANTAGE FUND'),
(1100, 'PPF', 'PENDER PARTNERS FUND'),
(300, 'PSCF', 'PENDER SMALL CAP OPPORTUNITIES FUND'),
(371, 'PSCF-2', 'PENDER SMALL CAP OPPORTUNITIES FUND'),
(1000, 'PSGF', 'PENDER STRATEGIC GROWTH & INCOME FUND'),
(1800, 'PUSM', 'PENDER US SMALL/MID CAP EQUITY FUND'),
(200, 'PVLF', 'PENDER VALUE FUND'),
(150, 'PCOF', 'PENDER CREDIT OPPORTUNITIES FUND'),
(141, 'PTIF', 'PENDER TECH INFLECTION (VCC) INC.'),
(150, 'PGF', 'PENDER GROWTH FUND')

DROP TABLE position_summary;
CREATE TABLE position_summary(
	id int IDENTITY(1,1) PRIMARY KEY,
	dealer_rep_code varchar(12),
	fund_name_short varchar(15),
	fund_name varchar(100),
	sum_aum_base decimal(18,2),
	sum_aum_local decimal(18,2),
	sum_gain_loss_local decimal(18,6),
	sum_gain_loss_base decimal(18,6),
	last_process_date date
);

DROP TABLE transaction_summary;
CREATE TABLE transaction_summary (
	id int IDENTITY(1,1) PRIMARY KEY,
	dealer_rep_code varchar(12),
	fund_name_short varchar(15),
	total_redemptions_fy decimal(18,8),
	total_purchases_fy decimal(18,8),
	net_purchases decimal(18,8),
	last_proc_date date
);

DROP TABLE dealer_rep_code_summary;
CREATE TABLE dealer_rep_code_summary (
	id int IDENTITY(1,1) PRIMARY KEY,
	dealer_rep_code varchar(12),
	last_proc_date date, -- position_summary
	sum_aum_base decimal(18,2), -- position_summary
	sum_gain_loss_base decimal(18,6), -- position_summary
	total_purchases_FY decimal(18,8), -- transaction_summary
	total_redemptions_FY decimal(18,8), -- transaction_summary
	net_purchases_FY decimal(18,8), -- transaction_summary
);

DROP TABLE transaction_history
CREATE TABLE transaction_history(
	id int IDENTITY(1,1) PRIMARY KEY,
	account_number int,
	dealer_account_number varchar(16),
	short_name varchar(100),
	trade_date date,
	tran_type varchar(3),
	tran_type_detail varchar(50),
	fund_code int,
	fund_name varchar(50),
	fund_name_short varchar(15),
	dealer_code varchar(4),
	rep_code varchar(7),
	dealer_rep_code varchar(12),
	to_account int,
	to_fund int,
	taxable varchar(6),
	transaction_status varchar(3),
	transaction_number int,
	gross_amount_base decimal(18,2),
	gross_amount_local decimal(18,2),
	commission	decimal(18,2),
	nav decimal(18,4),
	shares decimal(18,4),
	cost_basis decimal(18,6),
	net_sales_base decimal(18,4),
	net_sales_local decimal(18,4),
	account_dealer_rep_code varchar(12),
);

DROP TABLE pending_transactions;
CREATE TABLE pending_transactions(
	Id int IDENTITY(1,1) PRIMARY KEY,
	placement_date date,
	wire_order_no varchar(15),
	trantype varchar(3),
	sub_trantype varchar(3),
	tran_type_description varchar(12),
	acct_at_fund int,
	short_name varchar(100),
	cfs_mgt_code int,
	fund_code int, 
	fund_name varchar(50),
	fund_name_short varchar(15),
	trade_date date,
	settlement_dt int,
	acct_at_brkr varchar(15),
	broker_id int,
	dlr_name_1 varchar(50),
	dealer_code varchar(4),
	rep_code varchar(7),
	dealer_rep_code varchar(12),
	dealer_rep_first_name varchar(50),
	dealer_rep_last_name varchar(50),
	original_amtor_shr_type varchar(50),
	column_20 varchar(3),
	from_acct_at_fund int,
	from_fund int,
	bluesky varchar(2),
	acct_type varchar(4),
	trans int,
	gross_amount_base decimal(18,8),
	gross_amount_local decimal(18,8),
	units decimal(18,8),
);

DROP TABLE trial_balance;
CREATE TABLE trial_balance(
	id int IDENTITY(1,1) PRIMARY KEY,
	account_number int,
	short_name varchar(100),
	fund_code int,
	fund_name varchar(50),
	fund_name_short varchar(15),
	name_1 varchar(50),
	name_2 varchar(50),
	address_1 varchar(50),
	address_2 varchar(50),
	address_3 varchar(50),
	city varchar(50),
	province_code varchar(2),
	postal_code varchar(10),
	dealer_code varchar(4),
	rep_code varchar(10),
	dealer_rep_code varchar(12),
	dealer_name varchar(50),
	dealer_rep_name varchar(50),
	xrefaccount varchar(15),
	account_type varchar(4),
	nominee_account_type varchar(4),
	nominee_flag varchar(1),
	bookshares decimal(18,4),
	nav	decimal(18,4),
	cost_basis decimal(18,2),
	last_process_date date,
	aum_local decimal(18,2),
	aum_base decimal(18,2),
	gain_loss_local decimal(18,2),
	gain_loss_base decimal(18,2)
);

DROP TABLE transaction_history_check;
CREATE TABLE transaction_history_check (
	id int IDENTITY(1,1) PRIMARY KEY,
	management_compay_code varchar(3),
	placement_date int,
	trans_no int,
	batch_date int,
	batch_code varchar(8),
	process_date int,
	trade_date int,
	trans_type_code varchar(3),
	trans_origin_code varchar(3),
	account_no int,
	investment_code int,
	industry_fund_code int,
	gross_amount decimal(18,2),
	net_amount decimal(18,2),
	percent_amt int,
	unit_amt decimal(18,6),
	unit_price decimal(18,6),
	closing_unit_bal decimal(18,6),
	trans_proc_seq_no int,
	rejection_code varchar(3),
	gross_or_net varchar(1),
	trans_seq_no int,
	dealer_code varchar(4),
	dealer_rep_code varchar(6),
	wire_order_no varchar(7),
	settlement_date int,
	settlement_gross_or_net varchar(1),
	settlement_amount decimal(18,2),
	suppress_confirmation varchar(1),
	contr_redem_code varchar(6),
	trans_status_code varchar(3),
	original_documents_recvd varchar(1),
	hidden_trans varchar(1),
	average_unit_cost decimal(18,6),
	resultant_average_unit_cost decimal(18,6),
	split_option_code varchar(1),
	receipted varchar(1),
	receipt_number varchar(10),
	institution_code varchar(5),
	branch_code varchar(5),
	reversal_code varchar(4),
	reverse varchar(1),
	adjust varchar(1),
	payment_type_code varchar(1),
	method_of_delivery varchar(3),
	changed_date int,
	changed_time int,
	changed_by_user varchar(10),
	entered_by varchar(10),
	time_placed int,
	wire_order_flag varchar(1),
	net_settlement_flag varchar(1),
	nominee_code varchar(5)
);