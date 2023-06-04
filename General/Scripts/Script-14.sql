-- ASIGNACION
WITH ASIGNACION AS (
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
	-- UNION 
	UNION
	-- UNION 
	-- MATCCH
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
)
select 
	-- ORGANIZATION
	adempiere.ad_org.value as org_value,
	coalesce(adempiere.ad_org.name,adempiere.ad_org.value,'') as org_name,
	coalesce(adempiere.ad_org.description,adempiere.ad_org.name,adempiere.ad_org.value,'') as org_description,
	coalesce(adempiere.ad_orginfo.taxid,'') as org_taxid,
	adempiere.ad_image.binarydata as org_logo,
	case  when c_location.address1 is null then '' else c_location.address1  end
	  ||
	case  when c_location.address2 is null then '' else ', ' || c_location.address2   end
	  ||
	case  when c_location.address3 is null then '' else ', ' || c_location.address3   end
	  ||
	case  when c_location.address4 is null then '' else ', ' || c_location.address4   end as org_address1,
	case  when c_location.city is null then '' else c_location.city   end
	  ||
	case  when c_location.regionname is null then '' else ', ' || c_location.regionname  end
	  ||
	case  when c_location.postal is null then '' else ', CP ' || c_location.postal end as org_address2 ,
	case  when ad_orginfo.phone is null then '' else ad_orginfo.phone   end
	  ||
	case  when ad_orginfo.phone2 is null then '' else ', ' || ad_orginfo.phone2   end as org_phone,
	case  when adempiere.ad_orginfo.fax is null then '' else 'Fax:' || adempiere.ad_orginfo.fax end  as org_fax ,
	case  when adempiere.ad_orginfo.email is null then '' else 'e-mail:' || adempiere.ad_orginfo.email end  as org_email ,
	-- BUSINESS PARTNER
	adempiere.c_bpartner.value as value_bp,
	adempiere.c_bpartner.name as name_bp,
	adempiere.c_bpartner.taxid as taxid_bp,
	COALESCE(adempiere.c_bpartner.amerp_nameseniat,adempiere.c_bpartner.name) as amerp_nameseniat,
	COALESCE(adempiere.c_bpartner.amerp_rifseniat,adempiere.c_bpartner.taxid) as amerp_rifseniat,
	-- BUSINESS PARTNER LOCATION
	cbp_l.name as bplocname,
	coalesce(cbp_l.phone,'') as phone,
	coalesce(cbp_l.phone2,'') as phone2,
	coalesce(cbp_l.fax,'') as fax,
	coalesce(c_bplocation.address1,'') as address1,
	coalesce(c_bplocation.address2,'') as address2,
	coalesce(c_bplocation.address3,'') as address3,
	coalesce(c_bplocation.address4,'') as address4,
	coalesce(c_bplocation.city,'') as city,
	coalesce(c_bplocation.regionname,'') as regionname,
	coalesce(c_bplocation.postal,'') as postal,
	-- INVOICE HEADER
	adempiere.c_allocationhdr.docstatus,
	adempiere.c_allocationhdr.c_allocationhdr_id,
	adempiere.c_allocationhdr.created,
	adempiere.c_allocationhdr.documentno,
	far.doctype_lin as printname,
	adempiere.c_doctype_trl.printname as printnamel,
	adempiere.c_doctype.docbasetype,
	case  when adempiere.c_allocationhdr.description is null then '' else '' || adempiere.c_allocationhdr.description  end  as description_head,
	use.name as usercode,
	use.description as username,
	use."value" as repcode,
	use.name as repname,
	-- ALLOCATION BLOCK
	allocation_block,
	-- Account Schema
	far.c_acctschema_id,
	far.acctschema_name,
	-- FACT_ACCT LINE
	far."value",
	far.name,
	far.description,
	far.dateacct,
	far.account_id,
	far.amtacctdr,
	far.amtacctcr,
	far.documentno_lin,
	far.doctype_lin,
	far.doctype_lin2,
	far.product_name,
	far.product_value,
	far.bp_name,
	far.bp_value,
	far.Charge_name,
	far.Invoice_txt
FROM
	adempiere.c_allocationhdr
	LEFT JOIN ASIGNACION as far on far.c_allocationhdr_id = adempiere.c_allocationhdr.c_allocationhdr_id
	LEFT JOIN adempiere.c_doctype on adempiere.c_doctype.c_doctype_id = adempiere.c_allocationhdr.c_doctype_id
	LEFT JOIN adempiere.c_doctype_trl on adempiere.c_doctype.c_doctype_id = adempiere.c_doctype_trl.c_doctype_id and adempiere.c_doctype_trl.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID}  ))
	LEFT JOIN adempiere.ad_org ON adempiere.ad_org.ad_org_id = adempiere.c_allocationhdr.ad_org_id
	LEFT JOIN adempiere.ad_orginfo  ON adempiere.ad_org.ad_org_id = adempiere.ad_orginfo.ad_org_id
	LEFT JOIN adempiere.ad_image ON adempiere.ad_orginfo.logo_id= adempiere.ad_image.ad_image_id
	LEFT JOIN adempiere.c_location ON adempiere.c_location.c_location_id = adempiere.ad_orginfo.c_location_id
	LEFT JOIN adempiere.c_bpartner ON adempiere.c_bpartner.c_bpartner_id = far.c_bpartner_id
	LEFT JOIN ( SELECT DISTINCT ON (c_bpartner_id) * FROM adempiere.c_bpartner_location as cbp_loc WHERE cbp_loc.isbillto='Y' ) 
    as cbp_l ON adempiere.c_bpartner.c_bpartner_id = cbp_l.c_bpartner_id  
	LEFT JOIN adempiere.c_location as c_bplocation on c_bplocation.c_location_id = cbp_l.c_location_id
	LEFT JOIN adempiere.ad_user as use ON use.ad_user_id = adempiere.c_allocationhdr.createdby
WHERE
	adempiere.c_allocationhdr.c_allocationhdr_id =  $P{RECORD_ID}
	AND far.acctschema_isactive = 'Y'
	AND far.allocation_block = '2-ALL'
ORDER by allocation_block ASC, c_acctschema_id, value ASC