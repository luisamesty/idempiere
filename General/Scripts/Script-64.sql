SELECT  
cperiod.C_period_ID, cta.name, bstm.*, cperiod.*  
FROM c_bankaccount cta
LEFT JOIN (
	SELECT 
	C_Year_ID, C_period_ID, fiscalyear, periodno, periodname, description as fy_description,
	startdate as start_date, enddate  as end_date,
	CAST(EXTRACT(DAY FROM(startdate)) AS int) as day_start_per,
	CAST(EXTRACT(MONTH FROM(startdate)) AS int) as month_start_per,
	CAST(EXTRACT(YEAR FROM(startdate)) AS int) as year_start_per,
	CAST(EXTRACT(DAY FROM(enddate)) AS int) as day_end_per,
	CAST(EXTRACT(MONTH FROM(enddate)) AS int) as month_end_per,
	CAST(EXTRACT(YEAR FROM(enddate)) AS int) as year_end_per
	FROM (
		SELECT
		yea.C_Year_ID, yea.fiscalyear, COALESCE(yea.description,yea.fiscalyear,'') as description,
		per.C_period_ID, per.periodno, per.name as periodname, per.startdate, per.enddate
		FROM C_Year yea
		LEFT JOIN C_period per ON per.C_Year_ID = yea.C_Year_ID
		LEFT JOIN (SELECT ad_client_id, C_Year_ID, startdate FROM C_Period WHERE C_Period_ID = $P{C_Period_ID} ) per1 ON per1.C_Year_ID = yea.C_Year_ID
		LEFT JOIN (SELECT ad_client_id, C_Year_ID, startdate FROM C_Period WHERE C_Period_ID = $P{C_PeriodEnd_ID} ) per2 ON per.C_Year_ID = yea.C_Year_ID
		WHERE yea.AD_Client_ID = $P{AD_Client_ID}
		AND per.startdate >= per1.startdate AND per.startdate <= per2.startdate
		AND yea.C_Year_ID=$P{C_Year_ID}
		ORDER BY per.startdate ASC
	) as perds 
) AS cperiod ON 1=1
LEFT JOIN (
		SELECT 
		bs.ad_client_id, bs.ad_org_id,
		bs.c_bankstatement_id, bs.c_bankaccount_id,  bs.c_currency_id, bs.C_ConversionType_ID,
		bs.docstatus, bs.beginningbalance, bs.endingbalance, bs.convertedamt,
		bs.dateacct , bs.isoverridecurrencyrate, ct.value AS ct_value, ct.name AS ct_name,
		CASE WHEN bs.isoverridecurrencyrate='Y' THEN bs.currencyrate ELSE
			adempiere.currencyrate(bs.c_currency_id, $P{C_Currency_ID},bs.DateAcct, bs.C_ConversionType_ID,bs.ad_client_id,bs.ad_org_id)
		END AS bs_currencyrate,
		CAST(EXTRACT(YEAR FROM bs.dateacct)  AS int) AS year_bstm,
		CAST(EXTRACT(MONTH FROM bs.dateacct)  AS int) AS month_bstm,
		CAST(EXTRACT(DAY FROM bs.dateacct)  AS int) AS day_bstm
		FROM C_BankStatement bs 
		LEFT JOIN C_ConversionType ct ON ct.c_conversiontype_id = bs.c_conversiontype_id 
) AS bstm  ON bstm.c_bankaccount_id = cta.c_bankaccount_id AND  cperiod.year_end_per =bstm.year_bstm AND cperiod.month_end_per =bstm.month_bstm AND cperiod.day_end_per =bstm.day_bstm
WHERE cta.c_bankaccount_id = $P{C_Bankaccount_ID}
