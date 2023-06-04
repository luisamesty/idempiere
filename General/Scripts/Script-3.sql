SELECT 
*
FROM (
   SELECT DISTINCT
   		-- ORGANIZACIÓN
	    bps.ad_client_id, bps.ad_org_id,
	    -- CURRENCY
		curr1.iso_code as iso_code1,
		COALESCE(currt1.cursymbol,curr1.cursymbol,curr1.iso_code,'') as cursymbol1,
		COALESCE(currt1.description,curr1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
	    curr2.iso_code as iso_code2,
		COALESCE(currt2.cursymbol,curr2.cursymbol,curr2.iso_code,'') as cursymbol2,
		COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,    
		-- BPARTNER
		bps.c_bpartner_id, bps.vpartner, 
		bps.ord, bps.document_id,
		bps.bpartner, 
		bps.issotrx, 
		--bps.bprep, 
		--bps.bpgroup, 
		--bps.bpchannel,
		coalesce(bpa.amerp_rifseniat,bpa.taxid,'') as taxid_bp,
		bps.ad_user_id,
		bps.bprep as bprep,
		bps.c_bp_group_id,
		bps.bpgroup as bpgroup, 
		bps.c_bp_channel_id,
		bps.bpchannel as bpchannel,  
		bps.salesrep_id,
		bps.date_act, bps.datedoc_p, bps.dateacct, 
		CASE WHEN (bps.ord= 1) THEN COALESCE(bps.o_duedate,bps.duedate) 
		          ELSE bps.date_act
		END as duedate,
		bps.username, bps.userphone, bps.userphone2, bps.phone, bps.phone2,
		bps.docbasetype, bps.shortname, bps.shortnamep, 
		bps.documentno, bps.documentnoa, bps.documentno_p, bps.document, bps.reference,
  	    bps.ispaid, bps.isallocated,
  	    bps.grandtotal,
  	    CASE WHEN bps.issotrx = 'N' THEN -1*bps.source_grandtotal 
  	    	WHEN bps.issotrx = 'Y' THEN bps.source_grandtotal
  	    	ELSE bps.source_grandtotal END AS source_grandtotal,
  	    -- Converted Grand Total
  	    CASE WHEN bps.issotrx = 'N' THEN -1*currencyConvert(bps.source_grandtotal,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID) 
  	    	WHEN bps.issotrx = 'Y' THEN currencyConvert(bps.source_grandtotal,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID) 
  	    	ELSE currencyConvert(bps.source_grandtotal,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)  
  	    	END AS converted_grandtotal,
		bps.signdbcr,
		-- DR (DEB -DB)
		CASE WHEN bps.signdbcr ='DB' THEN	
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, '2020-09-30')) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 3 OR bps.ord= 4 OR bps.ord= 5 ) THEN 0
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, '2020-09-30')),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 13  ) THEN 0
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS dr,
		-- CR (CRE - CR)
		CASE WHEN bps.signdbcr ='CR' THEN
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, '2020-09-30')) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 3 OR bps.ord= 4 OR bps.ord= 5 ) THEN 0
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN 
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, '2020-09-30')),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 13  ) THEN 0
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS cr,
  	    -- NEW COLUMNS
		--CAST(0 as numeric) as converted_openamt,
		CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
			currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, '2020-09-30')) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 3 AND bps.ispaid='N') THEN 
	  		currencyConvert(abs(bps.grandtotal) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 4 AND bps.ispaid='N') THEN 
	  		currencyConvert(abs(bps.grandtotal) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 5 AND bps.ispaid='N') THEN 
	  		currencyConvert(abs(bps.grandtotal) ,bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN 
	  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, '2020-09-30')),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 13  ) THEN 
	  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, '2020-09-30')),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		WHEN ( bps.ord= 21  ) THEN 
	  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
	  		ELSE 0 END AS converted_openamt,
		CASE 	WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
				currencyConvert(abs(invoiceDiscount(bps.document_id, '2020-09-30' , bps.C_InvoicePaySchedule_ID)),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
				WHEN ( bps.ord= 3 OR bps.ord= 4 OR bps.ord= 5 ) THEN 0
				WHEN ( bps.ord= 11 OR bps.ord= 12 OR  bps.ord= 13 ) THEN 0
				ELSE 0 END as max_discount,
		CASE 	WHEN (ord = 1 OR ord = 2) THEN 
				currencyConvert(abs(Coalesce(amf_invoicevatamt(bps.document_ID),0)),bps.c_currency_id,100,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
				ELSE 0 END as amaux_taxamt	
	 FROM adempiere.amf_bpstatement_v4 as bps
	 LEFT JOIN c_bpartner bpa ON bpa.c_bpartner_id = bps.c_bpartner_id
	 LEFT JOIN c_currency curr1 on bps.c_currency_id = curr1.c_currency_id
	 LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=1000000)
	 LEFT JOIN c_currency curr2 on curr2.c_currency_id = 100
	 LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=1000000)
	WHERE bps.C_BPartner_ID =1008011  --1001213
) as bpst
WHERE 1=1
AND  bpst.ispaid ='Y'
--and bpst.c_bpartner_id=1008011
--AND bpst.ord=2