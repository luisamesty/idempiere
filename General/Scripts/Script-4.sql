	-- **************************************************************************************
	-- INVOICES 
	-- PAID AND UNPAID INVOICES (ord  1 - 2 )   
	-- ALLOCATIONS all_ord : 4 - 5 - 6
	--    3: Documents/Allocations From PAYMENTS (Invoices, Credit Memo and WH Docs) 
	--    4: Documents/Allocations From Charges (Invoices, Credit Memo and WH Docs)
	--    5: Documents/Allocations From Other Documents (Invoices, Credit Memo and WH Docs)
	-- **************************************************************************************
	SELECT 
	row_number() over(PARTITION BY inv.c_invoice_id) as rn,
	CASE 	WHEN inv.isPaid ='N' THEN 1
		WHEN inv.isPaid ='Y' THEN 2
	END as ord,
	inv.c_bpartner_id,
	inv.ad_client_id,
	inv.ad_org_id,
	inv.c_invoice_id as document_id, 
	inv.c_invoice_id AS c_invoice_id,
	NULL AS c_payment_id,
	inv.issotrx, 
	inv.description AS document, 
	CASE WHEN inv.documentno IS NOT NULL THEN concat('Ord:',inv.documentno,'_',to_char(inv.dateordered,'DD/MM/YYYY')) 
		ELSE CONCAT('Asignacion Pago',inv.documentno) END as reference,
	inv.dateacct AS date_act, 
	inv.docstatus, 
	inv.documentno as documentno, 
	inv.documentno as documentnoa,
	CONCAT(to_char(inv.dateacct,'YYYY-MM-DD'),'_',inv.documentno)  as documentno_p, 
	inv.dateinvoiced AS datedoc_p, 
    inv.dateinvoiced AS datedoc,
	CASE WHEN doc_t.DocBaseType IN ('W','C')  OR doc_t.DocSubTypeWH IN ('IVA','ISLR','MUNICIPAL') THEN invo2.Inv_dateacct ELSE inv.dateacct END AS dateacct, 
	doc_t.c_doctype_id as doctype_id,
	doc_t.docbasetype as docbasetype,
	COALESCE(doc_tt.shortname,doc_t.docbasetype) as shortname, 
	doc_tt.name AS document_trl,
	doc_t.isSeniatBook,
	doc_t.DocSubTypeWH,
	COALESCE(doc_tt.shortname,doc_t.docbasetype) as shortnamep, 
	inv.c_currency_id as c_currency_id,
	cur.ISO_Code as ISO_Code,
	inv.C_ConversionType_ID as C_ConversionType_ID,
	inv.c_paymentterm_id, 
	pay_t.netdays AS paydays, 
	CASE WHEN ips.c_invoicepayschedule_id IS NULL THEN CASE WHEN inv.DateShipment <> inv.DateAcct THEN inv.DateShipment + pay_t.Netdays*INTERVAL'1 day'
		ELSE inv.DateAcct+pay_t.Netdays*INTERVAL'1 day' END
	      ELSE amf_invoicepaymenttermduedate(pay_t.c_paymentterm_id, inv.c_invoice_id) END AS duedate,
	CASE WHEN ips.c_invoicepayschedule_id IS NULL THEN 
		CASE WHEN inv.DateShipment <> inv.DateAcct 
			THEN date_part('day',age(inv.DateShipment + pay_t.Netdays*INTERVAL'1 day', inv.DateAcct ) )
			ELSE date_part('day',age(inv.DateAcct+pay_t.Netdays*INTERVAL'1 day', inv.DateAcct ) ) END
	      ELSE date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv.c_paymentterm_id, inv.c_invoice_id), inv.dateinvoiced ) ) END AS daysdue,
	CASE WHEN ips.isvalid='Y' THEN ips.c_invoicepayschedule_id ELSE 0 END AS c_invoicepayschedule_id , 
	ips.duedate AS o_duedate,   
	inv.totallines, 
	inv.grandtotal, 
	inv.withholdingamt, 
	inv.ispaid as ispaid,
	CASE WHEN inv.isPaid ='N' THEN 'N'
		WHEN inv.isPaid ='Y' THEN 'Y'
	END as IsAllocated,
	invo2.all_ord, invo2.All_Currency_ID, invo2.All_dateacct, invo2.All_datetrx, invo2.All_DocumentNo, invo2.All_printname,
	invo2.Inv_dateacct, invo2.Inv_dateinvoiced, invo2.Inv_Currency_ID, invo2.All_description,
	invo2.Inv_ConversionType_ID, invo2.isSeniatBook as Inv_isSeniatBook, invo2.DocSubTypeWH as Inv_DocSubTypeWH,
	invo2.All_amount, invo2.All_discountamt, invo2.All_writeoffamt,
	invo2.All_invoice_id, invo2.All_payment_id, invo2.All_charge_id,
	invo2.Inv_docbasetype, invo2.Inv_DocumentNo, invo2.Inv_grandtotal,	
	invo2.Pay_documentno, invo2.Pay_dateacct, invo2.Pay_datetrx, invo2.Pay_Currency_ID,
	invo2.Pay_ConversionType_ID, invo2.Pay_PayAmt, invo2.Pay_datedeposit,
	invo2.Cha_name														   
	FROM amf_c_invoice_v4_v inv
	LEFT JOIN c_doctype doc_t ON inv.c_doctype_id = doc_t.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tt ON doc_t.c_doctype_id = doc_tt.c_doctype_id AND doc_tt.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=inv.AD_Client_ID)
	LEFT JOIN c_invoicepayschedule ips ON inv.c_invoice_id = ips.c_invoice_id
	LEFT JOIN c_paymentterm pay_t ON inv.c_paymentterm_id = pay_t.c_paymentterm_id
	LEFT JOIN c_currency cur ON inv.c_currency_id = cur.c_currency_id
	LEFT JOIN (
		SELECT DISTINCT ON (all_l2.c_allocationline_id) 
		all_l2.c_bpartner_id,
		CASE WHEN all_l2.c_payment_id IS NOT NULL THEN 3
			WHEN all_l2.c_payment_id IS  NULL THEN 5
			ELSE 0 END as all_ord,
		all_h2.c_currency_id as All_Currency_ID, all_h2.dateacct as All_dateacct, all_h2.datetrx as All_datetrx,
		all_l2.c_allocationhdr_id, all_h2.documentno as All_DocumentNo, all_h2.description as All_description,
		COALESCE(doc_tta2.shortname,doc_tta2.printname, doc_ta2.docbasetype,'Alloc') as All_printname,
		all_l2.amount as All_amount, all_l2.discountamt as All_discountamt, all_l2.writeoffamt as All_writeoffamt,
		all_l2.c_invoice_id as All_invoice_id, all_l2.c_payment_id as All_payment_id, all_l2.c_charge_id as All_charge_id,
		doc_t2.c_doctype_id, inv2.documentno as Inv_DocumentNo, 
		inv2.dateacct as Inv_dateacct , inv2.dateinvoiced as Inv_dateinvoiced, inv2.c_currency_id as Inv_Currency_ID,
		inv2.C_ConversionType_ID as Inv_ConversionType_ID, inv2.grandtotal as Inv_grandtotal,
		doc_t2.docbasetype as Inv_docbasetype, doc_t2.isSeniatBook, doc_t2.DocSubTypeWH,
		pay2.documentno as Pay_documentno, pay2.dateacct as Pay_dateacct, pay2.datetrx as Pay_datetrx, pay2.c_currency_id as Pay_Currency_ID,
		pay2.C_ConversionType_ID as Pay_ConversionType_ID, pay2.PayAmt as Pay_PayAmt, pay2.DateDeposit as Pay_datedeposit,
		cha2.c_charge_id, cha2.name as Cha_name
		FROM adempiere.c_allocationline all_l2  
		LEFT JOIN adempiere.c_allocationhdr all_h2 ON all_h2.c_allocationhdr_id = all_l2.c_allocationhdr_id
		LEFT JOIN adempiere.c_invoice inv2  ON all_l2.c_invoice_id = inv2.c_invoice_id
		LEFT JOIN adempiere.c_payment pay2  ON all_l2.c_payment_id = pay2.c_payment_id
		LEFT JOIN adempiere.c_doctype doc_t2 ON inv2.c_doctype_id = doc_t2.c_doctype_id
		LEFT JOIN adempiere.c_doctype doc_ta2 ON all_h2.c_doctype_id = doc_ta2.c_doctype_id
		LEFT JOIN adempiere.c_doctype_trl doc_tta2 ON doc_ta2.c_doctype_id = doc_tta2.c_doctype_id AND doc_tta2.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=all_h2.AD_Client_ID)
		LEFT JOIN adempiere.c_charge  cha2  ON cha2.c_charge_id = all_l2.c_charge_id
	--	UNION
	--		
	) as invo2 ON invo2.All_invoice_id = inv.C_Invoice_ID		
 	WHERE inv.Processed='Y'
-- END
-- For test Only 
AND inv.c_bpartner_id = 1008011		
--AND inv.C_Invoice_ID=1054551
AND isPaid='N'
order by inv.grandtotal --CONCAT(to_char(inv.dateacct,'YYYY-MM-DD'),'_',inv.documentno)						