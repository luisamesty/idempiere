	-- ****************************************************
	-- ALLOCATED AND  UNALLOCATED PAYMENTS ( ord: 11 - 12 )
	-- ALLOCATIONS all_ord :
	-- 		13: PAYMENT ALLOCATION TO INVOICES 
	--		14: PAYMENT ALLOCATION WITH CHARGES
	-- ****************************************************
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
	payo.all_ord, payo.All_Currency_ID, payo.All_dateacct, payo.All_datetrx, payo.All_DocumentNo, payo.All_printname,
	payo.Inv_dateacct, payo.Inv_dateinvoiced, payo.Inv_Currency_ID, payo.All_description,
	payo.Inv_ConversionType_ID, payo.isSeniatBook  as Inv_isSeniatBook, payo.DocSubTypeWH as Inv_DocSubTypeWH,
	payo.All_amount, payo.All_discountamt, payo.All_writeoffamt,
	payo.All_invoice_id, payo.All_payment_id, payo.All_charge_id,	
	payo.Inv_docbasetype, payo.Inv_DocumentNo, payo.Inv_grandtotal,															 
	payo.Pay_documentno, payo.Pay_dateacct, payo.Pay_datetrx, payo.Pay_Currency_ID,
	payo.Pay_ConversionType_ID, payo.Pay_PayAmt, payo.Pay_datedeposit,
	payo.Cha_name
	FROM adempiere.amf_c_payment_v4_v pay
	LEFT JOIN c_payment pay2 ON (pay.c_payment_id = pay2.c_payment_id )
	LEFT JOIN c_doctype doc_t ON pay.c_doctype_id = doc_t.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tt ON doc_t.c_doctype_id = doc_tt.c_doctype_id AND doc_tt.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=pay.AD_Client_ID)
	LEFT JOIN c_currency cur ON pay.c_currency_id = cur.c_currency_id
	LEFT JOIN c_bankaccount baa ON baa.c_bankaccount_id = pay.c_bankaccount_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='APP' ) AS  doc_tapp ON doc_tapp.ad_client_id= pay.ad_client_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='ARR' ) AS  doc_tarr ON doc_tarr.ad_client_id= pay.ad_client_id
	LEFT JOIN (
		SELECT
			all_l1.c_bpartner_id,
			CASE WHEN all_l1.c_invoice_id IS NOT NULL AND pay1.c_charge_id IS NULL THEN 13
			WHEN all_l1.c_invoice_id IS NULL AND pay1.c_charge_id IS NOT NULL THEN 14
			END as all_ord,
			all_h1.c_currency_id as All_Currency_ID, all_h1.dateacct as All_dateacct, all_h1.datetrx as All_datetrx,
			all_l1.c_allocationhdr_id, all_h1.documentno as All_DocumentNo, all_h1.description as All_description,
			COALESCE(doc_tta.shortname,doc_tta.printname, doc_ta.docbasetype) as All_printname,
			all_l1.amount as All_amount, all_l1.discountamt as All_discountamt, all_l1.writeoffamt as All_writeoffamt,
			all_l1.c_invoice_id as All_invoice_id, all_l1.c_payment_id as All_payment_id, all_l1.c_charge_id as All_charge_id,
			doc_t1.c_doctype_id, inv1.documentno as Inv_DocumentNo, 
			inv1.dateacct as Inv_dateacct, inv1.dateinvoiced as Inv_dateinvoiced, inv1.c_currency_id as Inv_Currency_ID,
			inv1.C_ConversionType_ID as Inv_ConversionType_ID, inv1.grandtotal as Inv_grandtotal,
			doc_t1.docbasetype as Inv_docbasetype, doc_t1.isSeniatBook, doc_t1.DocSubTypeWH,
			pay1.documentno as Pay_documentno, pay1.dateacct as Pay_dateacct, pay1.datetrx as Pay_datetrx, pay1.c_currency_id as Pay_Currency_ID,
			pay1.C_ConversionType_ID as Pay_ConversionType_ID, pay1.PayAmt as Pay_PayAmt, pay1.DateDeposit as Pay_datedeposit,
			cha1.c_charge_id, cha1.name as Cha_name
		FROM 
		adempiere.c_allocationline all_l1
		LEFT JOIN adempiere.c_payment pay1  ON all_l1.c_payment_id = pay1.c_payment_id
		LEFT JOIN adempiere.c_invoice inv1  ON all_l1.c_invoice_id = inv1.c_invoice_id
		LEFT JOIN adempiere.c_charge  cha1  ON all_l1.c_charge_id = cha1.c_charge_id
		LEFT JOIN adempiere.c_doctype doc_t1 ON pay1.c_doctype_id = doc_t1.c_doctype_id
		LEFT JOIN adempiere.c_allocationhdr all_h1 ON all_h1.c_allocationhdr_id = all_l1.c_allocationhdr_id
		LEFT JOIN c_doctype doc_ta ON all_h1.c_doctype_id = doc_ta.c_doctype_id
		LEFT JOIN c_doctype_trl doc_tta ON doc_ta.c_doctype_id = doc_tta.c_doctype_id AND doc_tta.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=all_h1.AD_Client_ID)
		WHERE pay1.C_Payment_ID IS NOT NULL 
		AND (all_l1.c_invoice_id IS NOT NULL OR pay1.c_charge_id IS NOT NULL)
	) as payo ON payo.All_payment_id = pay.c_payment_id
	WHERE  pay.Processed='Y' 
-- END
-- For Test Only
AND pay.c_bpartner_id = 1008011		
AND pay.isAllocated='N'																					   
--AND payo.all_ord=13
order by CONCAT(to_char(pay.dateacct,'YYYY-MM-DD'),'_',pay.documentno)