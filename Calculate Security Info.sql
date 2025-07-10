UPDATE SecurityMaster 
SET SharesOutstanding =
	(SELECT TOP 1 CASE
		WHEN SECURITY_TYPE = 'Warrant' OR SECURITY_TYPE = 'Unit' OR SECURITY_TYPE = 'Stock' OR SECURITY_TYPE = 'Preferred' OR SECURITY_TYPE = 'HoldStock' OR SECURITY_TYPE = 'FXForward' OR SECURITY_TYPE = 'Cash' 
			THEN SHARES_OUTSTANDING
			ELSE FACE_VALUE_OUTSTANDING
		END
	FROM security_data WHERE ISIN = t1.ISIN AND CUSIP = t1.CUSIP AND OTHER_ID = t1.OtherID
	ORDER BY TS DESC)
FROM SecurityMaster AS t1

UPDATE SecurityMaster
SET ValuePCTofNAV = CASE 
	WHEN PortfolioNav = 0 THEN 0
	ELSE (Value / PortfolioNav) * 100
END,
PCTofOutstanding = CASE 
	WHEN SharesOutstanding = 0 THEN 0
	ELSE (Quantity / SharesOutstanding) * 100
END;

SELECT Security, Description, Portfolio, ValuePCTofNAV, PCTofOutstanding, Quantity, SharesOutstanding, PosnDateInt FROM SecurityMaster WHERE PosnDateInt = 20231114