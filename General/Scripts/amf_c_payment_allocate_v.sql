CREATE OR REPLACE VIEW adempiere.amf_c_payment_allocate_v
AS SELECT
	all_l1.c_bpartner_id,
	all_h1.c_currency_id as All_Currency_ID, 
	all_h1.dateacct as All_dateacct, 
	all_h1.datetrx as All_datetrx,
	all_l1.c_allocationhdr_id, 
	all_h1.documentno as All_DocumentNo, 
	all_h1.description as All_description,
	doc_ta.c_doctype_id AS All_doctype_id,
	doc_tta.shortname AS All_shortname,
	doc_tta.printname AS All_printname,
	doc_ta.docbasetype AS All_docbasetype,
	all_l1.amount as All_amount, 
	all_l1.discountamt as All_discountamt, 
	all_l1.writeoffamt as All_writeoffamt,
	CASE WHEN all_l1.c_invoice_id IS NOT NULL THEN all_l1.c_invoice_id ELSE 0 END as All_invoice_id,
	all_l1.c_payment_id as All_payment_id, 
	allocp.c_charge_id as All_charge_id,
	allocp.Cha_name AS All_Cha_name,
	allocp.Cha_description AS ALL_Cha_description,
	inv1.documentno as Inv_DocumentNo, 
	inv1.description as Inv_Description,
	doc_tv1.c_doctype_id AS Inv_doctype_id, 
	doc_ttv1.shortname AS Inv_shortname,
	doc_ttv1.printname AS Inv_printname, 
	inv1.dateacct as Inv_dateacct, 
	inv1.dateinvoiced as Inv_dateinvoiced, 
	inv1.c_currency_id as Inv_Currency_ID,
	inv1.C_ConversionType_ID as Inv_ConversionType_ID, 
	inv1.grandtotal as Inv_grandtotal,
	doc_t1.docbasetype as Inv_docbasetype, 
	doc_t1.isSeniatBook, doc_t1.DocSubTypeWH,
	doc_tt1.shortname as Pay_shortname,
	doc_tt1.printname as Pay_printname, 
	doc_t1.docbasetype as Pay_docbasetype,
	pay1.documentno as Pay_documentno, 
	pay1.dateacct as Pay_dateacct, 
	pay1.datetrx as Pay_datetrx, 
	pay1.c_currency_id as Pay_Currency_ID,
	pay1.C_ConversionType_ID as Pay_ConversionType_ID, 
	pay1.PayAmt as Pay_PayAmt, 
	pay1.DateDeposit as Pay_datedeposit,
	cha1.c_charge_id AS Pay_charge_id,
	cha1.name AS Pay_Cha_name,
	cha1.description AS Pay_Cha_description
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
	all_l11.c_allocationhdr_id,  all_l11.c_allocationline_id , all_l11.c_charge_id,
	cha0.name as Cha_name, cha0.description as Cha_description
	FROM adempiere.c_allocationline all_l11 
	LEFT JOIN adempiere.c_charge  cha0  ON all_l11.c_charge_id = cha0.c_charge_id
	WHERE all_l11.c_charge_id IS NOT NULL
) as allocp ON allocp.c_allocationline_id  = all_l1.c_allocationline_id
WHERE all_l1.C_Payment_ID IS NOT NULL 
AND (all_l1.c_invoice_id IS NOT NULL OR allocp.c_charge_id IS NOT NULL OR cha1.c_charge_id IS NOT NULL) ;

