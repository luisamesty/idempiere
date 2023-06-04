SELECT * FROM (
  SELECT DISTINCT
	-- ORGANIZATION
    org.ad_client_id as org_client, org.ad_org_id as org_org,
	CASE WHEN $P{AD_Org_ID} = 0 THEN concat(COALESCE(cli.name,cli.value),' - Consolidado') ELSE coalesce(org.name,org.value,'') END as org_name,
	CASE WHEN $P{AD_Org_ID} = 0 THEN concat(COALESCE(cli.description,cli.name),' - Consolidado') ELSE COALESCE(org.description,org.name,org.value,'') END as org_description, 
	CASE WHEN $P{AD_Org_ID} = 0 THEN '' ELSE COALESCE(orginfo.taxid,'') END as org_taxid,
	CASE WHEN $P{AD_Org_ID}  = 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
	CASE WHEN  org.ad_client_id = $P{AD_Client_ID}   AND $P{AD_Org_ID}  = 0 THEN 1
	             WHEN  org.ad_client_id = $P{AD_Client_ID}  AND org.ad_org_id= $P{AD_Org_ID}  THEN 1
	             ELSE 0 
	  END as imp_org	
  FROM adempiere.ad_org as org
  INNER JOIN adempiere.ad_client as cli ON (org.ad_client_id = cli.ad_client_id)
  INNER JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
  LEFT JOIN adempiere.ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
  INNER JOIN adempiere.ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
  LEFT JOIN adempiere.ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
 ) as org_inf
 FULL JOIN 
 (
   SELECT DISTINCT
   		-- ORGANIZACIÓN
	    bps.ad_client_id, bps.ad_org_id,
	    -- CURRENCIES
	    -- Document or Payment Currency
		curr1.iso_code as iso_code1,
		COALESCE(currt1.cursymbol,curr1.cursymbol,curr1.iso_code,'') as cursymbol1,
		COALESCE(currt1.description,curr1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
		-- User Entered currency
	    curr2.iso_code as iso_code2,
		COALESCE(currt2.cursymbol,curr2.cursymbol,curr2.iso_code,'') as cursymbol2,
		COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2, 
		-- USD currency
	    curr3.iso_code as iso_code3,
		COALESCE(currt3.cursymbol,curr3.cursymbol,curr3.iso_code,'') as cursymbol3,
		COALESCE(currt3.description,curr3.iso_code,curr3.cursymbol,'') as currname3,	    
	    -- Allocation Currency
	    curr4.iso_code as iso_code4,
		COALESCE(currt4.cursymbol,curr4.cursymbol,curr4.iso_code,'') as cursymbol4,
		COALESCE(currt4.description,curr4.iso_code,curr4.cursymbol,'') as currname4,  
		-- ALLOCATION
		bps.rn, bps.ord, bps.all_ord, bps.document_id,
		bps.All_Currency_ID, bps.All_dateacct, bps.All_documentno, bps.All_printname,
		bps.All_description, bps.Inv_dateinvoiced, bps.All_datetrx,
		bps.Inv_isSeniatBook, bps.Inv_DocSubTypeWH, 
		bps.All_invoice_id, bps.Inv_DocumentNo, bps.Inv_docbasetype, bps.Inv_Currency_ID, bps.Inv_ConversionType_ID,
		bps.Inv_dateacct, bps.Inv_dateinvoiced, bps.Inv_grandtotal,
		bps.All_payment_id, bps.Pay_documentno, bps.Pay_dateacct, bps.Pay_datetrx, bps.Pay_Currency_ID,
		bps.Pay_ConversionType_ID, bps.Pay_PayAmt, bps.Pay_datedeposit,
		bps.All_charge_id,	bps.Cha_name,
		-- BPARTNER
		bps.c_bpartner_id, bps.vpartner, 
		bps.bpartner, 
		bps.issotrx, 
		coalesce(bpa.amerp_rifseniat,bpa.taxid,'') as taxid_bp,
		bps.ad_user_id,
		CASE WHEN ( $P{isShowRep} = 'Y' OR $P{AD_User_ID} IS NOT NULL ) THEN bps.bprep ELSE 'Todos los Representantes' END as bprep,
		bps.c_bp_group_id,
		CASE WHEN ( $P{isShowGroup} = 'Y' OR $P{C_BP_Group_ID} IS NOT NULL ) THEN bps.bpgroup ELSE 'Todos los Grupos' END as bpgroup, 
		bps.c_bp_channel_id,
		CASE WHEN ( $P{isShowChannel} = 'Y' OR $P{C_BP_Channel_ID} IS NOT NULL) THEN bps.bpchannel ELSE 'Todos los Canales' END as bpchannel,  
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
  	    CASE WHEN bps.signdbcr ='DB' AND bps.rn = 1 THEN
	  	    CASE WHEN bps.issotrx = 'N' THEN -1*currencyConvert(bps.source_grandtotal,bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID) 
	  	    	WHEN bps.issotrx = 'Y' THEN currencyConvert(bps.source_grandtotal,bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID) 
	  	    	ELSE currencyConvert(bps.source_grandtotal,bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)  
	  	   		END 
	  		ELSE CAST(0 as numeric) END
	  	   		AS converted_grandtotal,
		bps.signdbcr,
		CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN
				abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, $P{DateEnd})) 
			WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN
				abs(amf_paymentAvailable(bps.document_id, $P{DateEnd}))
			WHEN ( bps.ord= 21  ) THEN
		  		abs(bps.source_grandtotal)
		  	ELSE 0 END as document_open,
		bps.C_ConversionType_ID,
		bps.c_currency_id,
		-- DR (DEB -DB DOCUMENT)
		CASE WHEN bps.signdbcr ='DB' AND bps.rn = 1 THEN	
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, $P{DateEnd})) ,bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, $P{DateEnd})),bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS dr,
		-- CR (CRE - CR)
		CASE WHEN bps.signdbcr ='CR' AND bps.rn = 1 THEN
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, $P{DateEnd})) ,bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN 
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, $P{DateEnd})),bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,$P{C_Currency_ID},bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS cr,
		-- DR_USD (DEB -DB USD)
		CASE WHEN bps.signdbcr ='DB' AND bps.rn = 1 THEN	
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) AND (curr3.c_currency_id != $P{C_Currency_ID}) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, $P{DateEnd})) ,bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, $P{DateEnd})),bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS dr_usd,
		-- CR_USD (CRE - CR USD)
		CASE WHEN bps.signdbcr ='CR' AND bps.rn = 1 THEN
			CASE WHEN ( bps.ord= 1 OR bps.ord= 2  ) AND (curr3.c_currency_id != 100) THEN 
				currencyConvert(abs(amf_invoiceopentodate(bps.document_id,bps.C_InvoicePaySchedule_ID, $P{DateEnd})) ,bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 11 OR bps.ord= 12  ) THEN 
		  		currencyConvert(abs(amf_paymentAvailable(bps.document_id, $P{DateEnd})),bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.ord= 21  ) THEN
		  		currencyConvert(abs(bps.source_grandtotal),bps.c_currency_id,curr3.c_currency_id,bps.dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS cr_usd,    	    
		-- ALL_Amount (AMOUNT ALLOCATION)
		CASE WHEN $P{isSummary} != 'Y'  THEN	
			CASE WHEN (  bps.all_ord= 3 OR bps.all_ord= 4 OR bps.all_ord= 5 OR bps.all_ord= 11 OR bps.all_ord= 12  OR bps.all_ord= 13 ) THEN 
				abs(bps.All_amount+bps.All_discountamt+bps.All_writeoffamt) 
		  		WHEN ( bps.all_ord= 21  ) THEN
		  		abs(bps.All_amount+bps.All_discountamt+bps.All_writeoffamt)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS all_amount,
		CASE WHEN $P{isSummary} != 'Y'  THEN	
			CASE WHEN (  bps.all_ord= 3 OR bps.all_ord= 4 OR bps.all_ord= 5 OR bps.all_ord= 11 OR bps.all_ord= 12  OR bps.all_ord= 13 ) THEN 
				currencyConvert(abs(bps.All_amount+bps.All_discountamt+bps.All_writeoffamt) ,bps.All_Currency_ID,$P{C_Currency_ID},bps.All_dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		WHEN ( bps.all_ord= 21  ) THEN
		  		currencyConvert(abs(bps.All_amount+bps.All_discountamt+bps.All_writeoffamt),bps.All_Currency_ID,$P{C_Currency_ID},bps.All_dateacct, bps.C_ConversionType_ID,bps.AD_Client_ID, bps.AD_Org_ID)
		  		ELSE 0 END
			 ELSE CAST(0 as numeric) END AS all_amount_converted
	 FROM adempiere.amf_bpstatement_v4 as bps
	 LEFT JOIN c_bpartner bpa ON bpa.c_bpartner_id = bps.c_bpartner_id
	 --LEFT JOIN (SELECT DISTINCT ON (AD_Client_ID) C_Currency_ID, AD_Client_ID FROM C_AcctSchema ) as sch ON sch.AD_Client_ID = bps.ad_client_id 
	 -- Document Currency
	 LEFT JOIN c_currency curr1 on bps.c_currency_id = curr1.c_currency_id
	 LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- User entered currency
	 LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
	 LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- US$ Currency
	 LEFT JOIN C_Currency curr3 ON curr3.iso_code = 'USD' 
	 LEFT JOIN c_currency_trl currt3 on curr3.c_currency_id = currt3.c_currency_id and currt3.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- Allocation Currency
	 LEFT JOIN c_currency curr4 on bps.all_currency_id = curr4.c_currency_id
	 LEFT JOIN c_currency_trl currt4 on curr4.c_currency_id = currt4.c_currency_id and currt4.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE CASE WHEN ( $P{AD_User_ID} IS NULL OR bps.ad_user_id = $P{AD_User_ID} )  THEN 1=1 ELSE 1=0 END
  AND CASE WHEN ( $P{C_BPartner_ID} IS NULL OR bps.c_bpartner_id = $P{C_BPartner_ID} ) THEN 1=1 ELSE 1=0  END 
  AND CASE WHEN ( $P{C_BP_Group_ID} IS NULL OR bps.c_bp_group_id = $P{C_BP_Group_ID} )  THEN 1=1 ELSE 1=0 END 
  AND CASE WHEN ( $P{C_BP_Channel_ID} IS NULL OR bps.c_bp_channel_id = $P{C_BP_Channel_ID} ) THEN 1=1 ELSE 1=0  END
  AND CASE WHEN ( $P{BothPurchaseSales} = 'B' ) THEN 1 = 1
		WHEN ( $P{BothPurchaseSales} = 'S' AND bps.issotrx = 'Y' ) THEN 1 = 1
		WHEN ( $P{BothPurchaseSales} = 'P' AND bps.issotrx = 'N' ) THEN 1 = 1
		ELSE 1=0 END 
  AND CASE 	WHEN ( $P{isShowPaid} = 'Y' ) THEN 1=1 
  	    WHEN ( $P{isShowPaid} = 'N' AND bps.isPaid ='N' ) THEN 1=1
  	    ELSE 1=0 end
  AND ( bps.dateacct <= DATE( $P{DateEnd} ))
 ) as details ON (1= 0)
WHERE  (imp_org= 1) 
   OR (	(org_client= $P{AD_Client_ID} AND org_org= $P{AD_Org_ID}  ) 
   OR (ad_client_id= $P{AD_Client_ID} AND ad_org_id= $P{AD_Org_ID}  )    )
ORDER BY  details.bprep,details.bpgroup, details.bpchannel,details.vpartner,  details.issotrx, details.documentno_p, details.rn, details.ord, details.all_ord, details.dateacct, org_inf