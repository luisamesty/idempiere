	SELECT 
	CASE WHEN alloc.DocBaseType IS NOT NULL THEN alloc.DocBaseType  ELSE '' END as DocBaseType, 
	CASE WHEN alloc.isSeniatBook IS NOT NULL THEN alloc.isSeniatBook  ELSE '' END as isSeniatBook,
	CASE WHEN alloc.DocSubTypeWH IS NOT NULL THEN alloc.DocSubTypeWH  ELSE '' END as DocSubTypeWH,
	a.AD_Client_ID, a.AD_Org_ID,
	al.Amount, al.DiscountAmt, al.WriteOffAmt,
	a.C_Currency_ID, a.DateTrx, invo.C_ConversionType_ID, invo.DateAcct, invo.C_Invoice_ID
	FROM C_ALLOCATIONLINE al
	INNER JOIN C_ALLOCATIONHDR a ON (al.C_AllocationHdr_ID=a.C_AllocationHdr_ID)
	INNER JOIN C_INVOICE invo ON (invo.C_Invoice_ID = al.C_Invoice_ID )
	LEFT JOIN (
	  	SELECT 
	  	all_l2.c_allocationhdr_id,  all_l2.c_allocationline_id, doc_t2.c_doctype_id, doc_t2.docbasetype, inv2.documentno, 
	   	inv2.dateacct as dateacctinv, inv2.dateinvoiced, inv2.C_ConversionType_ID, doc_t2.isSeniatBook, doc_t2.DocSubTypeWH
		FROM adempiere.c_allocationline all_l2  
	   	LEFT JOIN adempiere.c_invoice inv2  ON all_l2.c_invoice_id = inv2.c_invoice_id
	   	LEFT JOIN adempiere.c_doctype doc_t2 ON inv2.c_doctype_id = doc_t2.c_doctype_id
	   	WHERE doc_t2.docbasetype IN ('ARC', 'APC', 'ARW', 'APW')
  	) as alloc ON alloc.c_allocationhdr_id  = al.c_allocationhdr_id
	WHERE 1=1 --al.C_Invoice_ID = 1054597
	AND a.DateAcct <= '2020-10-31'
	AND   a.IsActive='Y'
ORDER by  al.C_Invoice_ID	
