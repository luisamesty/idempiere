	-- ALLOCATION
	SELECT
	-- ALLOCATION HEADER
	'1-ALL' as allocation_block,
	ca.c_allocationhdr_id,
	ca.documentno as documentno_lin,
	-- FACT_ACCT LINE
	cev."value",
	cev.name,
	fact.description,
	to_char(fact.dateacct,'DD-MM-YYYY')  as dateacct,
	ashc.c_acctschema_id,
	ashc.name as acctschema_name,
	ashc.isactive as acctschema_isactive,
	fact.account_id,
	fact.amtacctdr,
	fact.amtacctcr,
	COALESCE(dctt.name,dctt.name) as doctype_lin,
	COALESCE(dct.printname,dct.printname) as doctype_lin2,
	COALESCE(pro.name,'') as product_name,
	COALESCE(pro.value,'') as product_value,
	bpa.c_bpartner_id ,
	COALESCE(bpa.name,'') as bp_name,
	COALESCE(bpa.value,'') as bp_value,
	'' as Charge_name,
	'' as Invoice_txt
	from adempiere.c_allocationhdr ca 
	LEFT JOIN adempiere.c_currency curr on curr.c_currency_id = ca.c_currency_id
	LEFT JOIN adempiere.c_currency_trl currtr on currtr.c_currency_id = curr.c_currency_id 
		and currtr.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_AllocationHdr WHERE C_AllocationHdr_ID=$P{RECORD_ID}  ))
	LEFT JOIN (
	  SELECT 
	  ad_client_id, m_product_id, c_bpartner_id, record_id, c_acctschema_id, 
	  description, dateacct, account_id, amtacctdr, amtacctcr 
	  from adempiere.fact_acct where record_id = $P{RECORD_ID}  and ad_table_id=735
	) as fact on fact.record_id = ca.c_allocationhdr_id 
	LEFT JOIN adempiere.c_elementvalue cev on fact.account_id = cev.c_elementvalue_id
	LEFT JOIN adempiere.c_doctype dct on dct.c_doctype_id = ca.c_doctype_id
	LEFT JOIN adempiere.c_doctype_trl dctt on dctt.c_doctype_id = dct.c_doctype_id  and dctt.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_AllocationHdr WHERE C_AllocationHdr_ID=$P{RECORD_ID}  ))
	LEFT JOIN adempiere.c_acctschema ashc on ashc.c_acctschema_id = fact.c_acctschema_id
	LEFT JOIN adempiere.m_product pro on pro.m_product_id = fact.m_product_id
	LEFT JOIN adempiere.c_bpartner bpa on bpa.c_bpartner_id = fact.c_bpartner_id
	where 	ca.c_allocationhdr_id= $P{RECORD_ID}  
