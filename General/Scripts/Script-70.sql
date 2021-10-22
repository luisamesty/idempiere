-- BankCurrencyRate
SELECT * FROM 
(
  SELECT 
    -- ORGANIZATION
    CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.name,cli.value),' - Consolidado') ELSE coalesce(org.name,org.value,'') END as org_name,
	CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.description,cli.name),' - Consolidado') ELSE COALESCE(org.description,org.name,org.value,'') END as org_description, 
	COALESCE(orginfo.taxid,'') as org_taxid,
	CASE WHEN $P{AD_Org_ID}= 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
    -- Fiscal Year and Periods
    bst.C_Year_ID, bst.C_period_ID,
	bst.fiscalyear, bst.periodno, bst.periodname, bst.fy_description,
	bst.start_date, bst.end_date,
	bst.year_end_per,bst.month_end_per,bst.day_end_per,
    -- BANK ACCOUNT
   	cta.value as codigo, cta.accountno as cta_num, cta.name as cta_name,
    -- CURRENCY
    -- Document Currency
	curr1.iso_code as iso_code1,
	COALESCE(currt1.cursymbol,curr1.cursymbol,curr1.iso_code,'') as cursymbol1,
	COALESCE(currt1.description,curr1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
	-- User Entered currency
    curr2.iso_code as iso_code2,
	COALESCE(currt2.cursymbol,curr2.cursymbol,curr2.iso_code,'') as cursymbol2,
	COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,  
 	-- Default Local Currency	
	curr3.iso_code as iso_code3,
	COALESCE(currt3.cursymbol,curr3.cursymbol,curr3.iso_code,'') as cursymbol3,
	COALESCE(currt3.description,curr3.iso_code,curr3.cursymbol,'') as currname3,
    -- BPARTNER
    cbp.value as bp_value, cbp.name as bp_name,
    -- CHARGE
    coalesce(cha.name,'') as charge_name, coalesce(cha.description,'') as chareg_description,
   	-- STATEMENT HEADER
  	bst.dateacct,
  	bst.bs_currencyrate AS bs_currencyrate,
  	bst.bs_currencyrate_prev AS bs_currencyrate_prev,
  	bst.ct_name AS conversiontype_bst,
  	bst.ct_name_prev AS conversiontype_bst_prev,
  	-- Period 0 Condition
  	CASE WHEN bst.periodno = 0 THEN bst.endingbalance ELSE bst.beginningbalance END AS beginningbalance,
	CASE WHEN bst.periodno = 0 THEN bst.endingbalance_src ELSE bst.beginningbalance_src END as beginningbalance_src,
	bst.endingbalance as endingbalance,
	bst.endingbalance_prev as endingbalance_prev,
	bst.endingbalance_src as endingbalance_src,   
    -- STATEMENT LINE
    pay.documentno,
    doc_t.docbasetype as docbasetype,
	pay.description as descripcion_l, 
	CASE WHEN pay.c_currency_id <> curr2.c_currency_id THEN CONCAT(curr1.iso_code,'-',curr1.cursymbol,'-',COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,''))  ELSE '' END as descripcion_l_src,	
	pay.dateacct as fecha_l, 
	pay.datetrx as fecha_t, 
   	CASE WHEN doc_t.docbasetype ='APP' AND  ((pay.payamt) > 0) THEN 
 		-1*(pay.payamt + pay.discountamt)
	WHEN doc_t.docbasetype ='ARR' AND  ((pay.payamt) > 0) THEN 
		 (pay.payamt + pay.discountamt)
 	ELSE 0 	END as monto_l_src,
   	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt, pay.dateacct) as monto_l_unsigned,
   	CASE WHEN doc_t.docbasetype ='APP' AND  ((pay.payamt) > 0) THEN 
   	 		-1* currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)
		 WHEN doc_t.docbasetype ='ARR' AND  ((pay.payamt) > 0) THEN 
			currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)
   	 	 ELSE 0 END as monto_l,
   	-- Currency Rates
   	CASE WHEN pay.isoverridecurrencyrate='Y' THEN pay.currencyrate ELSE
			currencyrate(pay.c_currency_id, $P{C_Currency_ID},pay.DateAcct, pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) 
	END as currencyrate_p,
	CASE WHEN abs(pay.payamt + pay.discountamt ) != 0  AND currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt, pay.dateacct) != 0
		THEN  abs(pay.payamt + pay.discountamt ) / currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt,pay.dateacct) 
		ELSE 0 
	END as currencyrate_p_calc,
	CASE WHEN pay.isoverridecurrencyrate='Y' THEN 'Reemplazada' ELSE
		cotype.name
	END as conversiontype_p,
	-- Avg Currency Rate for ARR Payments ONLY 
	CASE WHEN payall.pay_docbasetype='ARR' THEN payall.AvgInv_currencyrate ELSE 0 END AS AvgInv_currencyrate,
	CASE WHEN payall.pay_docbasetype='ARR' THEN payall.Diff_currencyrate ELSE 0 END AS Diff_currencyrate,
	-- HABER, DEBE
	CASE WHEN doc_t.docbasetype ='APP' AND  ((pay.payamt + pay.discountamt) > 0) THEN 
   	 		currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)
   	 	WHEN doc_t.docbasetype ='ARR' AND  ((pay.payamt + pay.discountamt) < 0) THEN 
			-1*currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)
   	 	ELSE 0 	END as haber, 
   	CASE 
   	 WHEN doc_t.docbasetype ='ARR' AND 	((pay.payamt + pay.discountamt) > 0) THEN 
    	 	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)  	 
   	 WHEN doc_t.docbasetype ='APP' AND  ((pay.payamt + pay.discountamt) < 0) THEN 
   	 	-1*currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt + pay.discountamt,pay.dateacct)
   	 ELSE 0
     END as debe
  FROM c_bankaccount cta
  INNER JOIN adempiere.ad_client as cli ON (cta.ad_client_id = cli.ad_client_id)
  INNER JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
  LEFT JOIN (
		SELECT  
		cta.name, bstm.*, cperiod.*  
		FROM c_bankaccount cta
		LEFT JOIN (
			SELECT 
			C_Year_ID, C_period_ID, fiscalyear, 
			CASE WHEN C_Year_ID = $P{C_Year_ID} THEN CAST(periodno as int) ELSE CAST(0 as int) END AS periodno, 
			periodname, description as fy_description,
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
				LEFT JOIN (SELECT ad_client_id, c_period_id , startdate FROM C_Period WHERE ad_client_id = $P{AD_Client_ID} AND enddate = ( SELECT startdate-1 FROM C_Period WHERE C_Period_ID = $P{C_Period_ID} AND C_Year_ID=$P{C_Year_ID} ) ) AS per0 ON 1=1
				LEFT JOIN (SELECT C_Year_ID, startdate FROM C_Period WHERE C_Period_ID = $P{C_Period_ID} AND C_Year_ID=$P{C_Year_ID}) per1 ON per1.C_Year_ID = yea.C_Year_ID
				LEFT JOIN (SELECT C_Year_ID, startdate FROM C_Period WHERE C_Period_ID = $P{C_PeriodEnd_ID} AND C_Year_ID=$P{C_Year_ID} ) per2 ON per.C_Year_ID = yea.C_Year_ID
				WHERE yea.AD_Client_ID = $P{AD_Client_ID}
				AND per.startdate >= per0.startdate AND per.startdate <= per2.startdate 
				ORDER BY per.startdate ASC
			) as periods 
		) AS cperiod ON 1=1
		LEFT JOIN (
				SELECT 
				bs.ad_client_id, bs.ad_org_id,
				bs.c_bankstatement_id, 
				bs.c_bankaccount_id,  
				bs.c_currency_id, 
				bs.C_ConversionType_ID,
				LAG(bs.C_ConversionType_ID,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct) AS C_ConversionType_ID_prev,
				bs.docstatus, 
				-- bs_currencyrate
 				CASE WHEN bs.isoverridecurrencyrate='Y' THEN bs.currencyrate ELSE
					currencyrate(bs.c_currency_id, $P{C_Currency_ID},bs.DateAcct, bs.C_ConversionType_ID,bs.ad_client_id,bs.ad_org_id)
				END AS bs_currencyrate,
				-- bs_currencyrate_prev
				CASE WHEN (LAG(bs.isoverridecurrencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct))='Y' THEN (LAG(bs.currencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct)) ELSE
					currencyrate(bs.c_currency_id, $P{C_Currency_ID},
					LAG(bs.dateacct,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct), 
					LAG(bs.C_ConversionType_ID,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct),
					bs.ad_client_id,bs.ad_org_id)
				END AS bs_currencyrate_prev,
				-- beginningbalance_src, beginningbalance_src_prev, beginningbalance
				bs.beginningbalance AS beginningbalance_src,
				LAG(bs.beginningbalance,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct) AS beginningbalance_src_prev,
				CASE WHEN bs.isoverridecurrencyrate='Y' THEN bs.beginningbalance*bs.currencyrate ELSE
					currencyConvert(bs.beginningbalance, bs.c_currency_id,$P{C_Currency_ID},bs.dateacct,bs.C_ConversionType_ID,bs.ad_client_id,bs.ad_org_id)
				END AS beginningbalance,
				-- endingbalance_src, endingbalance_src_prev, endingbalance, endingbalance_prev
				bs.endingbalance AS endingbalance_src,
				LAG(bs.endingbalance,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct) AS endingbalance_src_prev,
				CASE WHEN bs.isoverridecurrencyrate='Y' THEN bs.endingbalance*bs.currencyrate ELSE
					currencyConvert(bs.endingbalance, bs.c_currency_id,$P{C_Currency_ID},bs.dateacct,bs.C_ConversionType_ID,bs.ad_client_id,bs.ad_org_id)
				END AS endingbalance,
				CASE WHEN (LAG(bs.isoverridecurrencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct))='Y' 
					THEN 
					(LAG(bs.endingbalance,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct))*(LAG(bs.currencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct)) 
					ELSE
					currencyConvert((LAG(bs.endingbalance,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct)),
					bs.c_currency_id,$P{C_Currency_ID},
					LAG(bs.dateacct,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct),
					LAG(bs.C_ConversionType_ID,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct),
					bs.ad_client_id,bs.ad_org_id)
				END AS endingbalance_prev,				
				-- dateacct, dateacct_prev
				bs.dateacct AS dateacct, 
				LAG(bs.dateacct,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct) AS dateacct_prev,
				-- isoverridecurrencyrate, isoverridecurrencyrate_prev
				bs.isoverridecurrencyrate AS isoverridecurrencyrate, 
				LAG(bs.isoverridecurrencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct) AS isoverridecurrencyrate_prev,
				-- ct_value, ct_name, ct_name_prev
				ct.value AS ct_value, 
				CASE WHEN bs.isoverridecurrencyrate='Y' THEN 'Reemplazada' ELSE ct.name
				END as ct_name,
				CASE WHEN (LAG(bs.isoverridecurrencyrate,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct))='Y' THEN 'Reemplazada' ELSE LAG(ct.name,1) OVER ( ORDER BY bs.c_bankaccount_id, bs.dateacct)
				END AS ct_name_prev,
				-- year, month , day
				CAST(EXTRACT(YEAR FROM bs.dateacct)  AS int) AS year_bstm,
				CAST(EXTRACT(MONTH FROM bs.dateacct)  AS int) AS month_bstm,
				CAST(EXTRACT(DAY FROM bs.dateacct)  AS int) AS day_bstm
				FROM C_BankStatement bs 
				LEFT JOIN C_ConversionType ct ON ct.c_conversiontype_id = bs.c_conversiontype_id 
				WHERE bs.c_bankaccount_id = $P{C_BankAccount_ID}
				ORDER BY bs.c_bankaccount_id, bs.dateacct
		) AS bstm  ON bstm.c_bankaccount_id = cta.c_bankaccount_id AND  cperiod.year_end_per =bstm.year_bstm AND cperiod.month_end_per =bstm.month_bstm AND cperiod.day_end_per =bstm.day_bstm
		WHERE cta.c_bankaccount_id = $P{C_BankAccount_ID}
  ) AS bst ON bst.c_bankaccount_id = cta.c_bankaccount_id
  LEFT JOIN (
  	SELECT 
  	ad_client_id, ad_org_id, 
  	c_payment_id, c_bpartner_id,
  	c_bankaccount_id, c_doctype_id,
  	payamt, discountamt, c_charge_id,
  	dateacct, documentno, docstatus ,
  	description, c_currency_id, datetrx,
  	isoverridecurrencyrate, currencyrate, 
  	c_conversiontype_id,
  	CAST(EXTRACT(MONTH FROM(dateacct)) AS int) as month_pay,
	CAST(EXTRACT(YEAR FROM(dateacct)) AS int) as year_pay
  	FROM adempiere.c_payment
  ) as pay ON pay.c_bankaccount_id = cta.c_bankaccount_id AND pay.month_pay = bst.month_end_per AND pay.year_pay=bst.year_end_per
  LEFT JOIN C_ConversionType cotype ON cotype.C_ConversionType_ID = pay.C_ConversionType_ID 
  LEFT JOIN adempiere.c_doctype doc_t ON pay.c_doctype_id = doc_t.c_doctype_id
  LEFT JOIN adempiere.c_bpartner cbp ON cbp.c_bpartner_id = pay.c_bpartner_id
  LEFT JOIN adempiere.c_charge cha ON cha.c_charge_id = pay.c_charge_id
  LEFT JOIN adempiere.ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
  INNER JOIN adempiere.ad_org as org ON (pay.ad_org_id = org.ad_org_id)
  INNER JOIN adempiere.ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
  LEFT JOIN adempiere.ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
  LEFT JOIN c_currency curr1 on pay.c_currency_id = curr1.c_currency_id
  LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID}) 
  LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
  LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
  -- Default Local Currency
  LEFT JOIN (
			  	SELECT sch1.C_AcctSchema_ID, sch1.C_Currency_ID, sch1.AD_Client_ID 
			  	FROM C_AcctSchema sch1  
			  	LEFT JOIN AD_ClientInfo clic ON clic.AD_Client_ID = sch1.AD_Client_ID 
			  	WHERE sch1.C_AcctSchema_ID = clic.C_AcctSchema1_ID 
  ) loccur ON loccur.AD_Client_ID = cta.ad_client_id 
  -- Default Local Currency
  LEFT JOIN c_currency curr3 on curr3.c_currency_id = loccur.c_currency_id
  LEFT JOIN c_currency_trl currt3 on curr3.c_currency_id = currt3.c_currency_id and currt3.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
  LEFT JOIN (
	SELECT 
	c_payment_id,  pay_docbasetype, c_bankaccount_id, --documentno, dateacct, pay_docbasetype, pay_currencyrate, 
	CASE WHEN pay_docbasetype IS NOT NULL AND pay_docbasetype ='ARR' AND line_amt <> 0 AND  line_amt2 <> 0 THEN 
	line_amt2/line_amt  ELSE 0 END AS AvgInv_currencyrate,
	CASE WHEN pay_docbasetype IS NOT NULL AND pay_docbasetype ='ARR' AND line_amt <> 0 AND  line_amt2 <> 0 THEN 
	line_amt2/line_amt - pay_currencyrate ELSE 0 END AS Diff_currencyrate
	FROM (
		SELECT 
		paysumm.c_payment_id, c_bankaccount_id, paysumm.documentno, paysumm.dateacct, paysumm.pay_docbasetype, paysumm.c_currency_id, paysumm.pay_currencyrate,
		SUM(paysumm.line_amt) AS line_amt, SUM(paysumm.line_amt2) AS line_amt2
		FROM (
			SELECT 
			payo.All_payment_id AS c_payment_id, 
			payo.All_documentno AS documentno,
			payo.Pay_dateacct AS dateacct,
			payo.All_currency_id AS c_currency_id,
			payo.Pay_bankaccount_id AS c_bankaccount_id,
			CASE WHEN payo.Pay_isoverridecurrencyrate='Y' THEN payo.Pay_currencyrate ELSE
				adempiere.currencyrate(payo.Pay_currency_id, $P{C_Currency_ID},payo.Pay_DateAcct, payo.Pay_ConversionType_ID,payo.ad_client_id,payo.Pay_org_id)
			END AS pay_currencyrate,
			payo.pay_docbasetype,
			payo.all_invoice_id as c_invoice_id,
			coalesce(payo.all_amount,0) as line_amt,
			coalesce(payo.all_discountamt,0) as line_discountamt,
			coalesce(payo.all_writeoffamt,0) as line_writeoffamt,
			CASE WHEN conv_inv.MultiplyRate IS NOT NULL
				THEN coalesce(payo.all_amount*conv_inv.MultiplyRate,0)
				ELSE coalesce(payo.all_amount,0)
				END AS line_amt2,
			CASE WHEN conv_inv.MultiplyRate IS NOT NULL
				THEN coalesce(payo.all_discountamt*conv_inv.MultiplyRate,0)
				ELSE coalesce(payo.all_discountamt,0)
				END AS line_discountamt2,
			CASE WHEN conv_inv.MultiplyRate IS NOT NULL
				THEN coalesce(payo.all_writeoffamt*conv_inv.MultiplyRate,0)
				ELSE coalesce(payo.all_writeoffamt,0)
				END AS line_writeoffamt2
			FROM amf_c_payment_allocate_v AS payo 
			LEFT JOIN ( 
				SELECT  pay3.C_Payment_ID, pay3.IsOverrideCurrencyRate, 
				CASE WHEN pay3.IsOverrideCurrencyRate ='Y'  THEN pay3.CurrencyRate 
					ELSE currencyRate (pay3.C_Currency_ID, $P{C_Currency_ID}, pay3.DateAcct, pay3.C_ConversionType_ID, pay3.AD_Client_ID, pay3.AD_org_ID) END as MultiplyRate
				FROM C_Payment pay3
			) as conv ON conv.C_Payment_ID = payo.all_payment_id
			LEFT JOIN adempiere.c_invoice as inv ON inv.c_invoice_id = payo.all_invoice_id
			LEFT JOIN ( 
				SELECT C_invoice_ID, invc1.IsOverrideCurrencyRate, COALESCE(cotyp.name,'Reemplazada') as ConversionType,
				CASE WHEN invc1.IsOverrideCurrencyRate ='Y' THEN invc1.CurrencyRate 
					ELSE currencyRate (invc1.C_Currency_ID, $P{C_Currency_ID}, invc1.DateAcct, invc1.C_ConversionType_ID, invc1.AD_Client_ID, invc1.AD_org_ID) END as MultiplyRate
				FROM C_invoice invc1
				LEFT JOIN C_ConversionType cotyp ON cotyp.C_ConversionType_ID = invc1.C_ConversionType_ID 
			) as conv_inv ON conv_inv.C_Invoice_ID = inv.C_Invoice_ID
			LEFT JOIN (
				  	SELECT sch1.C_AcctSchema_ID, sch1.C_Currency_ID, sch1.AD_Client_ID 
				  	FROM C_AcctSchema sch1  
				  	LEFT JOIN AD_ClientInfo cli1 ON cli1.AD_Client_ID = sch1.AD_Client_ID 
				  	WHERE sch1.C_AcctSchema_ID = cli1.C_AcctSchema1_ID 
			) cur2 ON cur2.AD_Client_ID = payo.ad_client_id 
			WHERE payo.Pay_currency_id <> cur2.C_Currency_ID
		) AS paysumm
		GROUP BY paysumm.c_payment_id, paysumm.c_bankaccount_id, paysumm.documentno, paysumm.dateacct, paysumm.pay_docbasetype, paysumm.c_currency_id, paysumm.pay_currencyrate
	) AS payresu
	WHERE payresu.c_bankaccount_id = $P{C_BankAccount_ID}
  ) AS payall ON payall.c_payment_id = pay.c_payment_id
  WHERE pay.ad_client_id= $P{AD_Client_ID} AND pay.ad_org_id= $P{AD_Org_ID} 
    AND ( pay.docstatus = 'CO' OR pay.docstatus='CL' )
    AND CASE WHEN ($P{C_BankAccount_ID} IS NULL  or cta.c_bankaccount_id = $P{C_BankAccount_ID}) THEN 1=1 ELSE 1=0 END
) as edo_cta  
ORDER BY fiscalyear, periodno, codigo, fecha_l ASC