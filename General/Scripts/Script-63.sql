	-- **************************************************************
	-- ALLOCATED AND  UNALLOCATED PAYMENTS ( ord: 11 - 12 )
	-- ALLOCATIONS all_ord :
	-- 		13: PAYMENT ALLOCATION TO INVOICES 
	--		14: PAYMENT ALLOCATION WITH CHARGES
	--			Two type of charges 1- Direct on Pay 
	--								2- On an payment Allocation
	-- **************************************************************
	SELECT
	row_number() over(PARTITION BY pay.c_payment_id) as rn,
 	CASE 	WHEN pay.IsAllocated='N' THEN 11
		WHEN pay.IsAllocated='Y' THEN 12
	END as ord, 
	pay.c_bpartner_id, 
	pay.ad_client_id,
	pay.ad_org_id,
	pay.c_payment_id as document_id,
	NULL AS c_invoice_id,
	pay.c_payment_id AS c_payment_id,
	-- EXCEPCION CASO PAGOS POR TRANSFERENCIAS CAJA - BANCOS EN COBRANZA
	--pay.isreceipt AS issotrx, 
	CASE WHEN pay.isreceipt='N' AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN 'Y'
		ELSE pay.isreceipt END  AS issotrx, 
	CONCAT(TRIM(baa.name),' ',TRIM(pay.description)) AS document, 
	CASE WHEN pay2.datedeposit IS NOT NULL THEN concat('FecDep:',to_char(pay2.datedeposit,'DD/MM/YYYY')) ELSE '' END as reference,
	pay.datetrx AS date_act, 
	pay.docstatus, 
	pay.documentno as documentno, 
	pay.documentno as documentnoa,
	CONCAT(to_char(pay.dateacct,'YYYY-MM-DD'),'_',pay.documentno)  as documentno_p, 
	pay.dateacct AS datedoc_p, 
	pay.datetrx AS datedoc, 
	pay.dateacct AS dateacct,
	CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN doc_tapp.c_doctype_id 
		WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_t.docbasetype='ARR' THEN doc_tapp.c_doctype_id 
		ELSE doc_t.c_doctype_id END as doctype_id,
	CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN doc_tapp.docbasetype 
		WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_t.docbasetype='ARR' THEN doc_tapp.docbasetype 
		ELSE doc_t.docbasetype END as docbasetype,
	CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN 'CaTR-CR' 
		WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_t.docbasetype='ARR' THEN 'BaTR-DB'
		ELSE COALESCE(doc_tt.shortname,doc_t.docbasetype) END as shortname,
	CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN 'CaTR-CR' 
		WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_t.docbasetype='ARR' THEN 'BaTR-DB'
		ELSE doc_tt.name END as document_trl,
	doc_t.isSeniatBook,
	doc_t.DocSubTypeWH,
	CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_t.docbasetype='APP' AND baa.isPettyCash='N' THEN 'CAJA-TR-CR' 
		WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_t.docbasetype='ARR' THEN 'BANCO-TR-DB'
		ELSE COALESCE(doc_tt.shortname,doc_t.docbasetype) END as shortnamep,
	cur.c_currency_id as c_currency_id,
	cur.ISO_Code as ISO_Code,
	pay.C_ConversionType_ID as C_ConversionType_ID,
	NULL AS c_paymentterm_id, 
	0 AS paydays,
	pay.dateacct AS duedate, 
	0 as Daysdue, 
	NULL as c_invoicepayschedule_id, 
	NULL AS o_duedate, 
	0 as totallines, 
	(pay.payamt+pay.writeoffamt+pay.discountamt) as grandtotal, 
	0 as withholdingamt, 
	CASE 	WHEN pay.IsAllocated='N' THEN 'N'
		WHEN pay.IsAllocated='Y' THEN 'Y'
	END as ispaid,
	pay.IsAllocated as IsAllocated,
	payo.all_ord, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.C_Currency_ID ELSE payo.All_Currency_ID END as All_Currency_ID, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.DateAcct ELSE payo.All_dateacct END as All_dateacct, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.DateTrx ELSE payo.All_datetrx END as All_datetrx,
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.documentno ELSE payo.All_DocumentNo END as All_DocumentNo, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN COALESCE(doc_tt.shortname,doc_tt.printname, doc_t.docbasetype,'') ELSE payo.All_printname END as All_printname,
	payo.Inv_dateacct, payo.Inv_dateinvoiced, payo.Inv_Currency_ID, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN cha2.name 	ELSE payo.All_description END as All_description,
	payo.Inv_ConversionType_ID, payo.isSeniatBook  as Inv_isSeniatBook, payo.DocSubTypeWH as Inv_DocSubTypeWH,
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.payamt ELSE payo.All_amount END as All_amount, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.discountamt ELSE payo.All_discountamt END as All_discountamt, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.writeoffamt ELSE payo.All_writeoffamt END as All_writeoffamt, 
	payo.All_invoice_id, payo.All_payment_id, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.c_charge_id ELSE payo.All_charge_id END as All_charge_id,	
	payo.Inv_printname, payo.Inv_docbasetype, payo.Inv_DocumentNo, payo.Inv_grandtotal,
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN COALESCE(doc_tt.shortname,doc_tt.printname, doc_t.docbasetype,'') ELSE payo.Pay_printname END as Pay_printname, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.documentno ELSE payo.Pay_documentno END as Pay_documentno, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.DateAcct ELSE payo.Pay_dateacct END as Pay_dateacct, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.DateTrx ELSE payo.Pay_datetrx END as Pay_datetrx, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.C_Currency_ID ELSE payo.Pay_Currency_ID END as Pay_Currency_ID,
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.C_ConversionType_ID ELSE payo.Pay_ConversionType_ID END as Pay_ConversionType_ID, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.PayAmt ELSE payo.Pay_PayAmt END as Pay_PayAmt, 
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN pay2.DateDeposit ELSE payo.Pay_datedeposit END as Pay_datedeposit,
	CASE WHEN pay2.c_charge_id  IS NOT NULL THEN cha2.name 
		WHEN payo.c_charge_id  IS NOT NULL THEN payo.Cha_name
		ELSE '' END as Cha_name
	FROM adempiere.amf_c_payment_v4_v pay
	LEFT JOIN c_payment pay2 ON (pay.c_payment_id = pay2.c_payment_id )
	LEFT JOIN adempiere.c_charge  cha2  ON pay2.c_charge_id = cha2.c_charge_id
	LEFT JOIN c_doctype doc_t ON pay.c_doctype_id = doc_t.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tt ON doc_t.c_doctype_id = doc_tt.c_doctype_id AND doc_tt.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=pay.AD_Client_ID)
	LEFT JOIN c_currency cur ON pay.c_currency_id = cur.c_currency_id
	LEFT JOIN c_bankaccount baa ON baa.c_bankaccount_id = pay.c_bankaccount_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='APP' ) AS  doc_tapp ON doc_tapp.ad_client_id= pay.ad_client_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='ARR' ) AS  doc_tarr ON doc_tarr.ad_client_id= pay.ad_client_id
	LEFT JOIN (
		SELECT
			all_l1.c_bpartner_id,
			CASE WHEN all_l1.c_invoice_id IS NOT NULL AND allocp.c_charge_id IS NULL THEN 13
				WHEN all_l1.c_invoice_id IS NULL AND (cha1.c_charge_id IS NOT NULL OR allocp.c_charge_id IS NOT NULL) THEN 14
				END as all_ord,
			all_h1.c_currency_id as All_Currency_ID, 
			all_h1.dateacct as All_dateacct, all_h1.datetrx as All_datetrx,
			all_l1.c_allocationhdr_id, all_h1.documentno as All_DocumentNo, 
			all_h1.description as All_description,
			COALESCE(doc_tta.shortname,doc_tta.printname, doc_ta.docbasetype) as All_printname,
			all_l1.amount as All_amount, all_l1.discountamt as All_discountamt, all_l1.writeoffamt as All_writeoffamt,
			allocp.c_invoice_id as All_invoice_id, 
			allocp.c_payment_id as All_payment_id, 
			allocp.c_charge_id as All_charge_id,
			doc_t1.c_doctype_id, inv1.documentno as Inv_DocumentNo, 
			COALESCE(doc_ttv1.shortname,doc_ttv1.printname, doc_tv1.docbasetype,'') as Inv_printname,
			inv1.dateacct as Inv_dateacct, inv1.dateinvoiced as Inv_dateinvoiced, inv1.c_currency_id as Inv_Currency_ID,
			inv1.C_ConversionType_ID as Inv_ConversionType_ID, inv1.grandtotal as Inv_grandtotal,
			doc_t1.docbasetype as Inv_docbasetype, doc_t1.isSeniatBook, doc_t1.DocSubTypeWH,
			COALESCE(doc_tt1.shortname,doc_tt1.printname, doc_t1.docbasetype,'') as Pay_printname,
			pay1.documentno as Pay_documentno, pay1.dateacct as Pay_dateacct, pay1.datetrx as Pay_datetrx, pay1.c_currency_id as Pay_Currency_ID,
			pay1.C_ConversionType_ID as Pay_ConversionType_ID, pay1.PayAmt as Pay_PayAmt, pay1.DateDeposit as Pay_datedeposit,
			COALESCE(cha1.c_charge_id, allocp.c_charge_id, 0) as c_charge_id, COALESCE(cha1.name, allocp.Cha_name,'') as Cha_name
		FROM 
		adempiere.c_allocationline all_l1
		LEFT JOIN adempiere.c_payment pay1  ON all_l1.c_payment_id = pay1.c_payment_id
		LEFT JOIN adempiere.c_invoice inv1  ON all_l1.c_invoice_id = inv1.c_invoice_id
		LEFT JOIN adempiere.c_doctype doc_t1 ON pay1.c_doctype_id = doc_t1.c_doctype_id
		LEFT JOIN c_doctype_trl doc_tt1 ON doc_t1.c_doctype_id = doc_tt1.c_doctype_id AND doc_tt1.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=pay1.AD_Client_ID)
		LEFT JOIN adempiere.c_doctype doc_tv1 ON inv1.c_doctype_id = doc_tv1.c_doctype_id
		LEFT JOIN c_doctype_trl doc_ttv1 ON doc_tv1.c_doctype_id = doc_ttv1.c_doctype_id AND doc_ttv1.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=inv1.AD_Client_ID)
		LEFT JOIN adempiere.c_allocationhdr all_h1 ON all_h1.c_allocationhdr_id = all_l1.c_allocationhdr_id
		LEFT JOIN adempiere.c_charge  cha1  ON pay1.c_charge_id = cha1.c_charge_id
		LEFT JOIN c_doctype doc_ta ON all_h1.c_doctype_id = doc_ta.c_doctype_id
		LEFT JOIN c_doctype_trl doc_tta ON doc_ta.c_doctype_id = doc_tta.c_doctype_id AND doc_tta.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=all_h1.AD_Client_ID)
		LEFT JOIN (
			SELECT
			all_l11.c_allocationhdr_id,  all_l11.c_allocationline_id , 
			all_l12.c_payment_id, all_l13.c_invoice_id,
			all_l11.c_charge_id, cha0.name as Cha_name, cha0.description as Cha_description
			FROM adempiere.c_allocationline all_l11 
			LEFT JOIN adempiere.c_charge  cha0  ON all_l11.c_charge_id = cha0.c_charge_id
			LEFT JOIN (
					SELECT all_l21.c_allocationhdr_id,  all_l21.c_allocationline_id , all_l21.c_payment_id
					FROM adempiere.c_allocationline all_l21 
					LEFT JOIN adempiere.c_payment  pay21  ON all_l21.c_payment_id = pay21.c_payment_id
					WHERE all_l21.c_payment_id IS NOT NULL AND all_l21.c_invoice_id IS NULL
			) AS all_l12 ON all_l12.c_allocationhdr_id= all_l11.c_allocationhdr_id
			LEFT JOIN (
					SELECT all_l31.c_allocationhdr_id,  all_l31.c_allocationline_id , all_l31.c_invoice_id
					FROM adempiere.c_allocationline all_l31 
					LEFT JOIN adempiere.c_invoice  inv31  ON all_l31.c_invoice_id = inv31.c_invoice_id
					WHERE all_l31.c_invoice_id IS NOT NULL AND all_l31.c_payment_id IS NULL
			) AS all_l13 ON all_l13.c_allocationhdr_id= all_l11.c_allocationhdr_id
			WHERE all_l11.c_charge_id IS NOT NULL
		) as allocp ON allocp.c_allocationline_id  = all_l1.c_allocationline_id
		WHERE (all_l1.C_Payment_ID IS NOT NULL OR allocp.c_allocationline_id IS NOT NULL )
		AND (all_l1.c_invoice_id IS NOT NULL OR allocp.c_charge_id IS NOT NULL OR cha1.c_charge_id IS NOT NULL)
	) as payo ON payo.All_payment_id = pay.c_payment_id
	WHERE  pay.Processed='Y' AND pay.isAllocated = 'N'
	-- FOR TEST ONLY
	AND	pay.c_bpartner_id =1010663 --1008011 --1010663