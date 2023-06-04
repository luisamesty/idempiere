	SELECT
	-- ALLOCATION LINE
	'2-ALL' as allocation_block,
	cah.c_allocationhdr_id,
	cah.documentno as documentno_lin,
	-- FACT_ACCT LINE
	cev."value" as value,
	cev."name" as name,
	fact.description,
	to_char(fact.dateacct,'DD-MM-YYYY')  as dateacct,
	ashc2.c_acctschema_id,
	ashc2.name as acctschema_name,
	ashc2.isactive as acctschema_isactive,
	fact.account_id,
	fact.amtacctdr,
	fact.amtacctcr,
	COALESCE(dctt2.name,dct2.name) as doctype_lin,
	COALESCE(dctt2.printname,dct2.printname) as doctype_lin2,
	COALESCE(pro2.name,'') as product_name,
	COALESCE(pro2.value,'') as product_value,
	bpa2.c_bpartner_id ,
	COALESCE(bpa2.name,'') as bp_name,
	COALESCE(bpa2.value,'') as bp_value,
	InvoCha.Charge_name,
	InvoCha.Invoice_txt
	FROM
	adempiere.c_allocationline alloc
	LEFT JOIN adempiere.c_payment pay  on alloc.c_payment_id = pay.c_payment_id
	LEFT JOIN adempiere.c_allocationhdr cah on (alloc.c_allocationhdr_id = cah.c_allocationhdr_id )
	LEFT JOIN adempiere.c_currency  curr on cah.c_currency_id = curr.c_currency_id
	LEFT JOIN adempiere.c_currency_trl currtr on currtr.c_currency_id = curr.c_currency_id and currtr.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_AllocationHdr WHERE C_AllocationHdr_ID=$P{RECORD_ID}  ))
	LEFT JOIN adempiere.fact_acct fact on ( cah.c_allocationhdr_id =fact.record_id )
	LEFT JOIN adempiere.c_elementvalue cev on fact.account_id = cev.c_elementvalue_id
	LEFT JOIN adempiere.c_doctype dct2 on dct2.c_doctype_id = cah.c_doctype_id
	LEFT JOIN adempiere.c_doctype_trl dctt2 on dct2.c_doctype_id = dctt2.c_doctype_id  and dctt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID}  ))
	LEFT JOIN adempiere.c_acctschema ashc2 on ashc2.c_acctschema_id = fact.c_acctschema_id
	LEFT JOIN adempiere.m_product pro2 on pro2.m_product_id = fact.m_product_id
	LEFT JOIN adempiere.c_bpartner bpa2 on bpa2.c_bpartner_id = fact.c_bpartner_id
	LEFT JOIN (
		SELECT C_AllocationHdr_ID, C_AllocationLine_ID, Charge_name, 
			CASE WHEN inv_documentno!='' OR Inv_dateinvoiced IS NOT NULL THEN
				CONCAT(inv_documentno, '_', to_char(Inv_dateinvoiced,'DD-MM-YYYY'),'_', CAST (inv_grandtotal as Text)) 
			ELSE '' END as Invoice_txt
		FROM (
			SELECT allh.C_AllocationHdr_ID, alll.C_AllocationLine_ID, 
				COALESCE(cha.name,'') as Charge_name,
				COALESCE(inv.DocumentNo,'') as inv_documentno,
				COALESCE(inv.DateInvoiced,null) as Inv_dateinvoiced,
				COALESCE(inv.Description,'') as Inv_description,
				COALESCE(inv.GrandTotal,0) as inv_grandtotal
			FROM C_AllocationHdr allh
			LEFT JOIN C_AllocationLine alll ON alll.C_AllocationHdr_ID = allh.C_AllocationHdr_ID
			LEFT JOIN C_Charge cha ON cha.C_Charge_ID = alll.C_Charge_ID
			LEFT JOIN C_Invoice inv ON inv.C_Invoice_ID = alll.C_Invoice_ID
		) AS Invo
	) AS InvoCha ON InvoCha.C_AllocationHdr_ID = fact.record_id AND  InvoCha.C_AllocationLine_ID = fact.line_id
	WHERE
	cah.c_allocationhdr_id= $P{RECORD_ID} 
	and fact.ad_table_id=735