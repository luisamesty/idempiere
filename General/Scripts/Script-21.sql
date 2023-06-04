WITH  SALESBOOK AS (
	SELECT DISTINCT ON (inv.c_invoice_id, rownum)
	allocwh.documentno as allocwh_documentno,
		-- TAX 
		CASE WHEN dti.isSeniatBook IN ('I','D','C') THEN coalesce(tax.taxindicator,'NOD')
			 WHEN dti.isSeniatBook IN ('W') THEN 'RET'  
			 ELSE coalesce(tax.taxindicator,'NOD') END as taxindicator,
		coalesce(cou.countrycode,'') as countrycode,
		-- VENTAS EXENTAS
		case  when tax.taxindicator = 'IVAEXE' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxbaseamt,0.00)) 	else 0  end as amaux_exe_b,
		case  when tax.taxindicator = 'IVAEXE' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_exe_i,
		case  when tax.taxindicator = 'IVAGEN' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxbaseamt,0.00)) 	else 0  end as amaux_genint_b,
		case  when tax.taxindicator = 'IVAGEN' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_genint_i,
		case  when tax.taxindicator = 'IVAADI' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxbaseamt,0.00))	else 0  end as amaux_adiint_b,
		case  when tax.taxindicator = 'IVAADI' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_adiint_i,
		case  when tax.taxindicator = 'IVARED' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxbaseamt,0.00))	else 0  end as amaux_redint_b,
		case  when tax.taxindicator = 'IVARED' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_redint_i,
		-- VENTAS IMPORTACION
		case  when tax.taxindicator = 'IVAEXE' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxbaseamt,0.00)) else 0  end as amaux_exeimp_b,
		case  when tax.taxindicator = 'IVAEXE' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_exeimp_i,
		case  when tax.taxindicator = 'IVAGEN' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxbaseamt,0.00)) else 0  end as amaux_genimp_b,
		case  when tax.taxindicator = 'IVAGEN' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_genimp_i,
		case  when tax.taxindicator = 'IVAADI' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxbaseamt,0.00))	else 0  end as amaux_adiimp_b,
		case  when tax.taxindicator = 'IVAADI' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_adiimp_i,
		case  when tax.taxindicator = 'IVARED' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxbaseamt,0.00))	else 0  end as amaux_redimp_b,
		case  when tax.taxindicator = 'IVARED' AND dti.isSeniatBook IN ('I','D','C') AND cou.countrycode!='VE' then (coalesce(cinvt.taxamt,0.00) ) 	else 0  end as amaux_redimp_i,
		inv.ad_org_id AS amaux_ad_org_id,
		inv.ad_client_id AS amaux_ad_client_id,
		inv.c_invoice_id as amaux_c_invoice_id,
		inv.c_invoice_id as amaux_c3_invoice_id,		
		to_char(inv.dateinvoiced,'DD-MM-YYYY') AS amaux_dateinvoice,
		to_char(inv.dateacct,'DD-MM-YYYY') AS amaux_dateacct,
		inv.dateacct AS  dateacct,
		inv.dateshipment AS dateshipment,
		invrev.dateacct AS  dateacct_rev,
		to_char(inv.dateacct,'YYYY-MM-DD') AS amaux_datereporder,
		COALESCE(invrev.dateinvoiced,inv.dateinvoiced) AS amaux_dateinvoice_rev,		
		inv.C_ConversionType_ID,
		-- ORGANIZATION
		org.value as org_value,
		coalesce(org.name,org.value,'') as org_name,
		coalesce(org.description,org.name,org.value,'') as org_description,
		coalesce(orginfo.taxid,'') as org_taxid,
		img.binarydata as org_logo,
		cur.C_Currency_ID as Org_Currency_ID,
		-- BUSINESS PARTNER
		bpa.name as amaux_namebp,
		bpa.taxid as amaux_taxid_bp,
		bpa.amerp_nameseniat as amaux_nameseniat,
		COALESCE(bpa.amerp_rifseniat,'') as amaux_rifseniat,
		coalesce(bpa.amerp_nameseniat,bpa.name,'') as amaux_name,
		coalesce(bpa.amerp_rifseniat,bpa.taxid,'') as amaux_rif,
		bpa.amerp_ivataxpayer as amaux_vattaxpayer,
	    -- CURRENCY
		curr1.iso_code as iso_code1,
		currt1.cursymbol as cursymbol1,
		COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
	    curr2.iso_code as iso_code2,
		currt2.cursymbol as cursymbol2,
		COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2, 
		-- DOCUMENT
		inv.C_Currency_ID as Doc_Currency_ID,
		dti.docbasetype as amaux_doctype,
		dti.isSeniatBook as amaux_booktype,
		case when dti.docbasetype = 'ARI' then 1 
			when dti.docbasetype = 'ARD' then 1 
			when dti.docbasetype = 'ARC' then -1 
			when dti.docbasetype = 'ARW' then -1 
			else 1 end as docsign,
		case when to_char(inv.dateinvoiced,'YYYYMM') = to_char(inv.dateacct,'YYYYMM') then '01' else '04' end as amaux_typetrans,
		case  when dti.isseniatbook = 'I' then coalesce(inv.documentno,'') else ''  end as amaux_documentno,
		coalesce(inv.amerp_controlnumber,'') as amaux_controlnumber,
		case  when dti.isseniatbook = 'D' then coalesce(inv.documentno,'') else ''  end as amaux_debitnote,
		case  when dti.isseniatbook = 'C' then coalesce(inv.documentno,'') else ''  end as amaux_creditnote,
		coalesce(inv2.documentno,inv.amerp_documentaffected,'') as amaux_documentidaffected,
		coalesce(inv2.documentno,inv.amerp_documentaffected,'') as amaux_documentnoaffected,
		coalesce(inv.amerp_importexportdoc,'') as amaux_importexeportdoc,
		CASE WHEN dti.isSeniatBook IN ('I','D','C') THEN
			coalesce(invtot.taxbaseamt_exe + invtot.taxbaseamt_gen+taxbaseamt_red + invtot.taxbaseamt_adi + invtot.taxamt_gen + invtot.taxamt_red + invtot.taxamt_adi ,0.00)
			ELSE 0 END	AS amaux_totaldoc,
		CASE WHEN dti.isSeniatBook IN ('I','D','C') THEN
			coalesce(invtot.taxbaseamt_exe + invtot.taxbaseamt_gen+taxbaseamt_red + invtot.taxbaseamt_adi ,0.00)
			ELSE 0 END AS amaux_totallines,
		-- DOCUMENTS REVERSED LOGIC
		inv.docstatus as amaux_docstatus,
		case 	when ( (dti.docbasetype = 'ARI' OR dti.docbasetype = 'ARD' ) AND inv.grandtotal >= 0 ) then 'N' 
			when ( (dti.docbasetype = 'ARI' OR dti.docbasetype = 'ARD' ) AND inv.grandtotal < 0 ) then 'Y' 
			when ( (dti.docbasetype = 'ARC' OR dti.docbasetype = 'ARW' ) AND inv.grandtotal >= 0 ) then 'N'  
			when ( (dti.docbasetype = 'ARC' OR dti.docbasetype = 'ARW' ) AND inv.grandtotal < 0 ) then 'Y'  
			ELSE 'N' end as amaux_isvoid,
		case WHEN invrev.c_invoice_id IS null THEN 'N' ELSE 'Y' END as amaux_isreversed,
		-- INVOICE VAT TAX LINE
		case when dti.isSeniatBook IN ('I','D','C') AND tax.rate = 0 THEN 
			coalesce(invtot.taxbaseamt_exe,0.00)
			ELSE 0 end AS amaux_totalsi,
		case when dti.isSeniatBook IN ('I','D','C') AND tax.rate > 0 THEN 
			coalesce(invtot.taxbaseamt_gen+taxbaseamt_red + invtot.taxbaseamt_adi ,0.00) 
			ELSE 0 end AS amaux_totalbase,
		coalesce(cinvt.taxamt,0.00) AS  amaux_taxamt,
		coalesce(cinvt.taxbaseamt,0.00) AS  amaux_linetotalamt,
		tax.rate AS amaux_taxrate,
		-- WITHHOLDING
		CASE WHEN allocwh.documentno IS NOT NULL AND allocwh.documentno <> inv.documentnobp AND invrev.c_invoice_id IS null 
			THEN	coalesce(allocwh.amount ,0.00) 
	     WHEN allocwh.documentno IS NOT NULL AND allocwh.documentno = inv.documentnobp AND invrev.c_invoice_id IS null 
			THEN coalesce(-1*allocwh.amount ,0.00)
	     WHEN allocwh.documentno IS NULL AND invrev.c_invoice_id IS null 
			THEN coalesce(allocwh.amount ,0.00)
	     WHEN allocwh.documentno IS NULL AND invrev.c_invoice_id IS NOT null 
			THEN coalesce(-1*allocwh.amount ,0.00)
		ELSE allocwh.amount END as amaux_withholdingamt,
		CASE when dti.isSeniatBook IN ('W') then  coalesce(to_char(inv.dateinvoiced,'DD-MM-YYYY'),'')  else '' end as amaux_withholdingdate,
		CASE when dti.isSeniatBook IN ('W') then  coalesce(inv.documentnobp,'')  else '' end as amaux_withholdingdocumentno,
		CASE when dti.isSeniatBook IN ('W') then  coalesce(inv.description,'') else '' end as amaux_withholdingvoucher,		
		row_number() over (partition by inv.c_invoice_id ORDER BY inv.c_invoice_id, tax.rate) as rownum
	FROM adempiere.c_invoice as inv
	LEFT JOIN adempiere.c_invoice as invrev on invrev.reversal_id = inv.c_invoice_id
	LEFT JOIN adempiere.c_invoice as inv2 on inv.amerp_documentaffected_id = inv2.c_invoice_id
	LEFT JOIN (
		SELECT C_invoice_id, c_tax_id, SUM(linenetamt) as taxbaseamt , ROUND(SUM(linenetamt)* rate / 100 ,2)  as taxamt, SUM(taxamtrnd) as taxamtrnd , rate, taxname, taxindicator
		FROM (
			SELECT
			in1.C_invoice_id, inl1.c_tax_id, 
			case when acgl.AMERP_Currency_Gain_Loss='Y' and cdt.isSeniatBook IN ('C','W') THEN
				currencyConvert(inl1.linenetamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateshipment,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)  
				when acgl.AMERP_Currency_Gain_Loss='N' THEN
				currencyConvert(inl1.linenetamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateacct,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)
				else
				currencyConvert(inl1.linenetamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateacct,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)
				end as linenetamt, 
			case when acgl.AMERP_Currency_Gain_Loss='Y' and cdt.isSeniatBook IN ('C','W') then
				currencyConvert(inl1.taxamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateshipment,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)
			 	when acgl.AMERP_Currency_Gain_Loss='N' then
				currencyConvert(inl1.taxamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateacct,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)
				else
				currencyConvert(inl1.taxamt, in1.C_Currency_ID,$P{C_Currency_ID},in1.dateacct,in1.C_ConversionType_ID,in1.ad_client_id,in1.ad_org_id)
				end as taxamtrnd, 
			txx.rate, 
			txx.name as taxname, 
			txx.taxindicator
			FROM C_invoice as in1
			LEFT JOIN c_invoiceline as inl1 ON inl1.c_invoice_id= in1.c_invoice_id
			LEFT JOIN C_tax as txx ON txx.c_tax_id = inl1.c_tax_id
			LEFT JOIN (select c_doctype_id, isseniatbook from C_Doctype) as cdt ON cdt.C_DocType_ID = in1.C_DocType_ID
			left join (select case when exists (select true from AD_Sysconfig where "name"='AMERP_Currency_Gain_Loss' and AD_client_ID = $P{AD_Client_ID})
    			then 'Y' else 'N' end as AMERP_Currency_Gain_Loss  ) as acgl on 1= 1
			WHERE in1.dateacct >= $P{DateIni} AND in1.dateacct <= $P{DateEnd}
		) AS imp
		GROUP BY imp.c_invoice_id, imp.c_tax_id, imp.rate, imp.taxname, imp.taxindicator
	) as cinvt ON ( cinvt.c_invoice_id = inv.c_invoice_id )
	LEFT JOIN (
		SELECT 
		c_invoice_id , 
		sum(taxbaseamt_exe) as taxbaseamt_exe, 
		sum(taxbaseamt_gen) as taxbaseamt_gen, 
		sum(taxbaseamt_red) as taxbaseamt_red, 
		sum(taxbaseamt_adi) as taxbaseamt_adi,
		sum(taxamt_gen) as taxamt_gen, 
		sum(taxamt_red) as taxamt_red, 
		sum(taxamt_adi) as taxamt_adi,
		max(taxrate_exe) as taxrate_exe,
		max(taxrate_gen) as taxrate_gen,
		max(taxrate_red) as taxrate_red,
		max(taxrate_adi) as taxrate_adi,
		COALESCE(max(taxname_exe),'') as taxname_exe,
		COALESCE(max(taxname_gen),'') as taxname_gen,
		COALESCE(max(taxname_red),'') as taxname_red,
		COALESCE(max(taxname_adi),'') as taxname_adi
		FROM (
			SELECT 
				c_invoice_id,
				CASE WHEN taxindicator = 'IVAEXE' then taxbaseamt ELSE 0 END as taxbaseamt_exe,
				CASE WHEN taxindicator = 'IVAGEN' then taxbaseamt ELSE 0 END as taxbaseamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxbaseamt ELSE 0 END as taxbaseamt_red,
				CASE WHEN taxindicator = 'IVAADI' then taxbaseamt ELSE 0 END as taxbaseamt_adi,
				CASE WHEN taxindicator = 'IVAGEN' then taxamt ELSE 0 END as taxamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxamt ELSE 0 END as taxamt_red,
				CASE WHEN taxindicator = 'IVAADI' then taxamt ELSE 0 END as taxamt_adi,
				CASE WHEN taxindicator = 'IVAEXE' then rate ELSE 0 END as taxrate_exe,
				CASE WHEN taxindicator = 'IVAGEN' then rate ELSE 0 END as taxrate_gen,
				CASE WHEN taxindicator = 'IVARED' then rate ELSE 0 END as taxrate_red,
				CASE WHEN taxindicator = 'IVAADI' then rate ELSE 0 END as taxrate_adi,
				CASE WHEN taxindicator = 'IVAEXE' then taxname ELSE '' END as taxname_exe,
				CASE WHEN taxindicator = 'IVAGEN' then taxname ELSE '' END as taxname_gen,
				CASE WHEN taxindicator = 'IVARED' then taxname ELSE '' END as taxname_red,
				CASE WHEN taxindicator = 'IVAADI' then taxname ELSE '' END as taxname_adi
			FROM (
				SELECT C_invoice_id, SUM(linenetamt) as taxbaseamt , ROUND(SUM(linenetamt)* rate / 100 ,2)  as taxamt, SUM(taxamtrnd) as taxamtrnd , rate, taxname, taxindicator
				FROM (
					SELECT
					inv0.C_invoice_id, inl0.c_tax_id, 
					case when acgl.AMERP_Currency_Gain_Loss='Y' and cdt.isSeniatBook IN ('C','W') THEN
						currencyConvert(inl0.linenetamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateshipment ,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)  
						when acgl.AMERP_Currency_Gain_Loss='N' THEN
						currencyConvert(inl0.linenetamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateacct,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)
						else
						currencyConvert(inl0.linenetamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateacct,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)
						end as linenetamt, 
					case when acgl.AMERP_Currency_Gain_Loss='Y' and cdt.isSeniatBook IN ('C','W') then
						currencyConvert(inl0.taxamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateshipment,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)
					 	when acgl.AMERP_Currency_Gain_Loss='N' then
						currencyConvert(inl0.taxamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateacct,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)
						else
						currencyConvert(inl0.taxamt, inv0.C_Currency_ID,$P{C_Currency_ID},inv0.dateacct,inv0.C_ConversionType_ID,inv0.ad_client_id,inv0.ad_org_id)
						end as taxamtrnd, 					
					txx0.rate, 
					txx0.name as taxname, 
					txx0.taxindicator
					FROM C_invoice as inv0
					LEFT JOIN c_invoiceline as inl0 ON inl0.c_invoice_id= inv0.c_invoice_id
					LEFT JOIN C_tax as txx0 ON txx0.c_tax_id = inl0.c_tax_id
					LEFT JOIN (select c_doctype_id, isseniatbook from C_Doctype) as cdt ON cdt.C_DocType_ID= inv0.C_DocType_ID
					left join (select case when exists (select true from AD_Sysconfig where "name"='AMERP_Currency_Gain_Loss' and AD_client_ID = $P{AD_Client_ID})
    					then 'Y' else 'N' end as AMERP_Currency_Gain_Loss  ) as acgl on 1= 1
					WHERE inv0.dateacct >= $P{DateIni} AND inv0.dateacct <= $P{DateEnd}
				) AS imp
			GROUP BY imp.c_invoice_id, imp.c_tax_id, imp.rate, imp.taxname, imp.taxindicator
			) AS impres
		) as impres2
		GROUP BY impres2.c_invoice_id
	) as invtot ON (invtot.c_invoice_id = inv.c_invoice_id )
	LEFT JOIN (
		SELECT
		inv3.c_invoice_id, inv4.documentno as documentno, COALESCE(alloc2.amount,0) as amount
		FROM adempiere.c_invoice as inv3 
		LEFT JOIN adempiere.c_allocationline as alloc ON (inv3.c_invoice_id = alloc.c_invoice_id)
		LEFT JOIN adempiere.c_allocationhdr as allhd ON (allhd.c_allocationhdr_id = alloc.c_allocationhdr_id) 
		LEFT JOIN adempiere.c_allocationline as alloc2 ON (alloc2.c_allocationhdr_id = allhd.c_allocationhdr_id AND alloc2.c_allocationline_id <> alloc.c_allocationline_id)
		LEFT JOIN adempiere.c_doctype as dti3 on inv3.c_doctype_id = dti3.c_doctype_id
		LEFT JOIN adempiere.c_invoice as inv4 ON (inv4.c_invoice_id = alloc2.c_invoice_id )
		WHERE dti3.isSeniatBook IN ('W') AND dti3.issotrx = 'Y'	
		AND inv3.dateacct >= $P{DateIni} AND inv3.dateacct <= $P{DateEnd}
		UNION  -- UN ALLOCATED WH
		SELECT
		inv3.c_invoice_id, 'UNALLOCATED' as documentno, 
		-1*invoiceopen(inv3.c_invoice_id, null) as amount
		FROM adempiere.c_invoice as inv3 
		LEFT JOIN adempiere.c_doctype as dti3 on inv3.c_doctype_id = dti3.c_doctype_id
		WHERE dti3.isSeniatBook IN ('W') AND dti3.issotrx = 'Y'	
		AND inv3.dateacct >= $P{DateIni} AND inv3.dateacct <= $P{DateEnd}
	) allocwh ON allocwh.c_invoice_id = inv.c_invoice_id
	LEFT JOIN adempiere.c_tax as tax on cinvt.c_tax_id = tax.c_tax_id
	LEFT JOIN adempiere.ad_org as org on inv.ad_org_id = org.ad_org_id
	LEFT JOIN adempiere.ad_orginfo as orginfo ON org.ad_org_id = orginfo.ad_org_id
	LEFT JOIN adempiere.ad_image as img ON orginfo.logo_id = img.ad_image_id
	LEFT JOIN adempiere.c_bpartner as bpa ON inv.c_bpartner_id = bpa.c_bpartner_id
	--LEFT JOIN adempiere.c_bpartner_location as bpl ON bpa.c_bpartner_id = bpl.c_bpartner_id
	LEFT JOIN adempiere.c_bpartner_location as bpl ON inv.C_BPartner_Location_ID = bpl.C_BPartner_Location_ID
	LEFT JOIN adempiere.c_location as clo on clo.c_location_id = bpl.c_location_id
	LEFT JOIN adempiere.c_country as cou on cou.c_country_id = clo.c_country_id
	LEFT JOIN adempiere.c_doctype as dti on inv.c_doctype_id = dti.c_doctype_id
	LEFT JOIN adempiere.lco_invoicewhdoclines as whdl on whdl.c_invoice_id = inv.c_invoice_id
	LEFT JOIN adempiere.lco_invoicewhdoc as whdh on whdh.lco_invoicewhdoc_id = whdl.lco_invoicewhdoc_id
	--LEFT JOIN (SELECT DISTINCT ON (AD_Client_ID) C_Currency_ID, AD_Client_ID FROM C_AcctSchema ) cur ON cur.AD_Client_ID = inv.AD_Client_ID
	LEFT JOIN (
	  	SELECT sch1.C_Currency_ID, sch1.AD_Client_ID 
	  	FROM C_AcctSchema sch1  
	  	LEFT JOIN AD_ClientInfo cli1 ON cli1.AD_Client_ID = sch1.AD_Client_ID 
	  	WHERE sch1.C_AcctSchema_ID = cli1.C_AcctSchema1_ID 
	) cur ON cur.AD_Client_ID = $P{AD_Client_ID}
	LEFT JOIN c_currency curr1 on inv.c_currency_id = curr1.c_currency_id
    LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID = $P{AD_Client_ID} )
    LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
    LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID = $P{AD_Client_ID} )
	WHERE
		tax.taxindicator IN ('IVAEXE','IVAGEN','IVAADI','IVARED')
		AND dti.isSeniatBook IN ('I','D','C', 'W') 
		AND dti.issotrx = 'Y' 
		AND inv.dateacct >= $P{DateIni} 
		AND inv.dateacct <= $P{DateEnd} 
		AND inv.ad_org_id =  $P{AD_Org_ID} AND ( inv.docstatus ='CO' OR  inv.docstatus ='CL' OR  inv.docstatus ='RE' )
		AND CASE WHEN dti.isSeniatBook IN ('I','D','C') or  (dti.isSeniatBook IN ('W') and allocwh.documentno <> 'UNALLOCATED') OR ( allocwh.documentno ='UNALLOCATED' AND allocwh.amount <> 0)  THEN 1=1 ELSE 1=0 END
)
SELECT --DISTINCT --ON ( amaux_datereporder, amaux_documentno, amaux_documentnoaffected)
--	c_invoice_id,
	-- TAX 
	taxindicator,countrycode,
	-- ORGANIZATION
	amaux_ad_org_id,amaux_ad_client_id,
	org_value,org_name,org_description,org_taxid,org_logo,
	-- BUSINESS PARTNER
	countrycode,
	amaux_name,amaux_namebp,amaux_rif,amaux_taxid_bp,amaux_nameseniat,amaux_rifseniat,amaux_vattaxpayer,
	-- CURRENCY
	iso_code1,
	cursymbol1,
	currname1,
	iso_code2,
	cursymbol2,
	currname2, 
	-- DOCUMENT
	org_currency_id,
	doc_currency_id,
	amaux_doctype,
	docsign,
	amaux_isvoid, amaux_isreversed,
	amaux_c_invoice_id, amaux_c3_invoice_id,
	amaux_dateinvoice,
	amaux_dateacct, 
	amaux_dateinvoice_rev,
	amaux_datereporder,
	amaux_doctype,
	amaux_booktype,
	CASE WHEN amaux_isreversed ='N' THEN amaux_typetrans ELSE '03' END  as amaux_typetrans, --amaux_typetrans,
	amaux_documentno,
	CASE WHEN taxindicator='RET' THEN amaux_withholdingdocumentno ELSE amaux_documentno END as amaux_documentnoorder,
	amaux_controlnumber,
	amaux_debitnote,amaux_creditnote,
	amaux_documentidaffected,
	amaux_documentnoaffected,
	docsign*amaux_totaldoc as amaux_totaldoc,
	-- INVOICE LINE
	docsign*amaux_totalsi as amaux_totalsi,
	docsign*amaux_totalbase as amaux_totalbase,
	docsign*amaux_taxamt as amaux_taxamt,
	docsign*amaux_linetotalamt as amaux_linetotalamt,
	amaux_taxrate, 
	amaux_importexeportdoc,
	-- VENTAS EXENTAS
	amaux_exe_b	AS amaux_exe_b,
	amaux_exe_i	AS amaux_exe_i,
	amaux_genint_b AS amaux_genint_b,
	amaux_genint_i AS amaux_genint_i,
	amaux_adiint_b AS amaux_adiint_b,
	amaux_adiint_i AS amaux_adiint_i,
	amaux_redint_b AS amaux_redint_b,
	amaux_redint_i AS amaux_redint_i,
	-- VENTAS EXPRORATCION
	amaux_exeimp_b AS amaux_exeimp_b,
	amaux_exeimp_i AS amaux_exeimp_i,
	amaux_genimp_b AS amaux_genimp_b,
	amaux_genimp_i AS amaux_genimp_i,
	amaux_adiimp_b AS amaux_adiimp_b,
	amaux_adiimp_i AS amaux_adiimp_i,
	amaux_redimp_b AS amaux_redimp_b,
	amaux_redimp_i AS amaux_redimp_i,
	-- WITHHOLDING
	CASE WHEN amaux_isreversed ='N' THEN docsign*amaux_withholdingamt
		WHEN amaux_isreversed ='Y' THEN docsign*amaux_withholdingamt
		ELSE 0 END as amaux_withholdingamt,
	amaux_withholdingdate,
	amaux_withholdingdocumentno,
	amaux_withholdingvoucher,
	rownum
FROM SALESBOOK 
ORDER BY amaux_datereporder ASC, amaux_documentno ASC, amaux_documentnoorder ASC, amaux_documentnoaffected ASC, rownum ASC