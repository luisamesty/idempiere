SELECT
	all_h1.c_currency_id AS All_Currency_ID,
	all_h1.dateacct AS All_Dateacct,
	all_h1.documentno AS All_DocumentNo,
	all_l1.amount AS All_Amount,
	all_l1.discountamt AS All_discountamt,
	all_l1.writeoffamt AS All_writeoffamt,
	COALESCE(all_l1.c_invoice_id, 0) AS All_invoice_id,
	allocp.c_charge_id AS All_charge_id,
	doc_t1.c_doctype_id,
	inv1.documentno AS Inv_DocumentNo,
	inv1.description AS Inv_Description,
	COALESCE(doc_ttv1.shortname, doc_ttv1.printname, doc_tv1.docbasetype, '') AS Inv_printname,
	inv1.dateacct AS Inv_dateacct,
	inv1.c_currency_id AS Inv_Currency_ID,
	inv1.C_ConversionType_ID AS Inv_ConversionType_ID,
	inv1.grandtotal AS Inv_grandtotal,
	pay1.c_currency_id AS Pay_Currency_ID,
	pay1.C_ConversionType_ID AS Pay_ConversionType_ID,
	pay1.PayAmt AS Pay_PayAmt,
	COALESCE(cha.c_charge_id, allocp.c_charge_id, 0) AS c_charge_id,
	COALESCE(cha.name, allocp.Cha_name, '') AS Cha_name,
	COALESCE(cha.description, allocp.Cha_description, '') AS Cha_description,
	CASE
		WHEN conv_inv.MultiplyRate IS NOT NULL THEN COALESCE(all_l1.amount*conv_inv.MultiplyRate, 0)
		ELSE COALESCE(all_l1.amount, 0)
	END AS line_amt2,
	CASE
		WHEN conv_inv.MultiplyRate IS NOT NULL THEN COALESCE(all_l1.discountamt*conv_inv.MultiplyRate, 0)
		ELSE COALESCE(all_l1.discountamt, 0)
	END AS line_discountamt2,
	CASE
		WHEN conv_inv.MultiplyRate IS NOT NULL THEN COALESCE(all_l1.writeoffamt*conv_inv.MultiplyRate, 0)
		ELSE COALESCE(all_l1.writeoffamt, 0)
	END AS line_writeoffamt2,
	COALESCE(conv_inv.MultiplyRate, 1) AS Inv_ConversionRate,
	COALESCE(conv.MultiplyRate, 1) AS Pay_ConversionRate
FROM adempiere.c_allocationline all_l1
LEFT JOIN adempiere.c_payment pay1 ON all_l1.c_payment_id = pay1.c_payment_id
LEFT JOIN adempiere.c_invoice inv1 ON all_l1.c_invoice_id = inv1.c_invoice_id
LEFT JOIN adempiere.c_doctype doc_t1 ON pay1.c_doctype_id = doc_t1.c_doctype_id
LEFT JOIN c_doctype_trl doc_tt1 ON doc_t1.c_doctype_id = doc_tt1.c_doctype_id
	AND doc_tt1.ad_language::TEXT = ( SELECT AD_Language FROM AD_Client WHERE AD_Client_ID = pay1.AD_Client_ID)
LEFT JOIN adempiere.c_doctype doc_tv1 ON inv1.c_doctype_id = doc_tv1.c_doctype_id
LEFT JOIN c_doctype_trl doc_ttv1 ON doc_tv1.c_doctype_id = doc_ttv1.c_doctype_id
	AND doc_ttv1.ad_language::TEXT = ( SELECT AD_Language FROM AD_Client WHERE AD_Client_ID = inv1.AD_Client_ID)
LEFT JOIN adempiere.c_allocationhdr all_h1 ON all_h1.c_allocationhdr_id = all_l1.c_allocationhdr_id
LEFT JOIN adempiere.c_charge cha ON pay1.c_charge_id = cha.c_charge_id
LEFT JOIN c_doctype doc_ta ON all_h1.c_doctype_id = doc_ta.c_doctype_id
LEFT JOIN c_doctype_trl doc_tta ON doc_ta.c_doctype_id = doc_tta.c_doctype_id
	AND doc_tta.ad_language::TEXT = (  SELECT AD_Language FROM AD_Client WHERE AD_Client_ID = inv1.AD_Client_ID)
LEFT JOIN (
	SELECT
		all_l11.c_allocationhdr_id,
		all_l11.c_allocationline_id ,
		all_l11.c_charge_id,
		cha1.name AS Cha_name,
		cha1.description AS Cha_description
	FROM adempiere.c_allocationline all_l11
	LEFT JOIN adempiere.c_charge cha1 ON all_l11.c_charge_id = cha1.c_charge_id
	WHERE all_l11.c_charge_id IS NOT NULL 
) AS allocp ON 	allocp.c_allocationhdr_id = all_h1.c_allocationhdr_id
LEFT JOIN (
	SELECT
		pay.C_Payment_ID,
		pay.IsOverrideCurrencyRate,
		CASE
			WHEN pay.IsOverrideCurrencyRate = 'Y' THEN pay.CurrencyRate
			ELSE currencyRate (pay.C_Currency_ID,
			1000000,
			pay.DateAcct,
			pay.C_ConversionType_ID,
			pay.AD_Client_ID,
			pay.AD_org_ID)
		END AS MultiplyRate
	FROM C_Payment pay
	WHERE C_payment_ID = 1099984 
) AS conv ON conv.C_Payment_ID = pay1.c_payment_id
LEFT JOIN (
	SELECT
		C_invoice_ID,
		invc1.IsOverrideCurrencyRate,
		COALESCE(cotyp.name, 'Reemplazada') AS ConversionType,
		CASE
			WHEN invc1.IsOverrideCurrencyRate = 'Y' THEN invc1.CurrencyRate
			ELSE currencyRate (invc1.C_Currency_ID,
			1000000,
			invc1.DateAcct,
			invc1.C_ConversionType_ID,
			invc1.AD_Client_ID,
			invc1.AD_org_ID)
		END AS MultiplyRate
	FROM
		C_invoice invc1
	LEFT JOIN C_ConversionType cotyp ON
		cotyp.C_ConversionType_ID = invc1.C_ConversionType_ID 
) AS conv_inv ON conv_inv.C_Invoice_ID = inv1.C_Invoice_ID
WHERE
	all_l1.C_Payment_ID IS NOT NULL
	AND (all_l1.c_invoice_id IS NOT NULL
	OR allocp.c_charge_id IS NOT NULL
	OR cha.c_charge_id IS NOT NULL)
	AND all_l1.c_payment_id = 1099984
