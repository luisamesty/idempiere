SELECT
	i.DateAcct,
	COALESCE(i.duedate, amf_invoicepaymenttermduedate(i.c_paymentterm_id, i.c_invoice_id), i.DateInvoiced ) AS DateDue ,
	COALESCE(doc_tt.shortname, doc_t.docbasetype) AS DocType,
	i.DocumentNo,
	i.C_Invoice_ID,
	c.ISO_Code,
	i.GrandTotal*i.MultiplierAP,
	currencyConvertInvoice(i.C_Invoice_ID,	$P{C_Currency_ID},	i.GrandTotal*i.MultiplierAP,	$P{Date}),
	currencyConvertInvoice(i.C_Invoice_ID,	$P{C_Currency_ID},
	amf_invoiceOpentoDate(i.C_Invoice_ID,	i.C_InvoicePaySchedule_ID, 	$P{Date}))* i.MultiplierAP AS cvtopen,
	currencyConvertInvoice(i.C_Invoice_ID,	$P{C_Currency_ID},	invoiceDiscount(i.C_Invoice_ID,	$P{Date},	i.C_InvoicePaySchedule_ID),	i.DateInvoiced)* i.Multiplier*i.MultiplierAP AS cvtdctn,
	i.MultiplierAP ,
	currencyConvert(amf_invoicevatamt(i.C_Invoice_ID),
	i.C_Currency_ID,	$P{C_Currency_ID},	$P{Date},	i.C_ConversionType_ID,	i.AD_Client_ID,	i.AD_Org_ID) AS amaux_taxamt,
	COALESCE(inv.amerp_controlnumber, '') AS amerp_controlnumber,
	currencyConvert(invoicepaid(inv.C_Invoice_ID,	inv.C_Currency_ID,	NULL ),	i.C_Currency_ID,	$P{C_Currency_ID},	i.DateAcct,	i.C_ConversionType_ID,	i.AD_Client_ID,	i.AD_Org_ID) AS invoicepaid,
	currencyConvert(i.GrandTotal*i.MultiplierAP, i.C_Currency_ID, 	$P{C_Currency_ID}, 	i.DateAcct, i.C_ConversionType_ID, 	i.AD_Client_ID, i.AD_Org_ID) AS invoiceorgcvt,
	currencyConvert(amf_invoicevatamt(i.C_Invoice_ID),	i.C_Currency_ID,	$P{C_Currency_ID},	i.DateAcct,	i.C_ConversionType_ID,	i.AD_Client_ID,	i.AD_Org_ID) AS amaux_taxamt_org,
	inv.C_Invoice_ID
FROM
	AMF_BPStatement_C_Invoice_V i
LEFT JOIN C_invoice inv ON
	(inv.C_invoice_ID = i.C_Invoice_ID)
LEFT JOIN C_Currency c ON
	(i.C_Currency_ID = c.C_Currency_ID)
LEFT JOIN c_doctype doc_t ON
	(i.c_doctype_id = doc_t.c_doctype_id
	AND i.AD_Client_ID = doc_t.AD_Client_ID )
LEFT JOIN c_doctype_trl doc_tt ON
	(doc_t.c_doctype_id = doc_tt.c_doctype_id
	AND doc_tt.ad_language = 'es_VE' )
WHERE
	i.IsPaid = 'N'
	AND i.Processed = 'Y'
	AND inv.isSOTrx = 'Y'
	AND i.C_BPartner_ID =$P{C_BPartner_ID}
	AND i.AD_Org_ID = $P{AD_Org_ID}
ORDER BY
	i.DateInvoiced,
	i.DocumentNo