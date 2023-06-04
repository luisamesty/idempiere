    -- UNION 3
    -- **************************************************************************************************
  	-- WITHHOLDINGS FROM CUSTOMERS ALLOCATED TO PREVIOUS PERIODS WITH NO PAYMENTS ALLOCATED
  	-- Withholding Invoices related to Invoices an Then Invoices related to Allocation to previous Periods
    -- ************************************************************************************************
    SELECT   DISTINCT  ON ( inv1.c_invoice_id , inv1.documentno, inv8.c_invoice_id)
	-- 0
	1 as sel,
	'W' as tipo,
	inv8.c_payment_id as c_payment_id,
	inv1.ad_client_id, 
	inv1.ad_org_id, 
	inv1.isactive, 
	inv1.documentno as pay_documentno, 
	inv1.description,
	'' as bp_value,
	inv1.dateinvoiced as datetrx, 
	'N' as isreceipt, 
    -- 10
	inv1.c_doctype_id, 
        inv1.issotrx as trxtype, 
        0 as c_bankaccount_id, 
        inv1.c_bpartner_id, 
        inv1.c_invoice_id, 
        0 as c_bp_bankaccount_id, 
        null as tendertype, 
        inv1.c_currency_id, 
    -- CURRENCY
	curr1.iso_code as iso_code1,
	currt1.cursymbol as cursymbol1,
	COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
    curr2.iso_code as iso_code2,
	currt2.cursymbol as cursymbol2,
	COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,  
	-- INVOICE DATA
        inv8.doc_nota as doc_nota,
     --20 
     dtyp.isseniatbook as doc_isseniatbook,
    inv1.c_doctype_id as doc_c_doctype_id,
     inv1.dateacct as doc_date,
	inv1.documentno as doc_documentno,
	cdty8.isseniatbook as inv_isseniatbook,
	inv8.dateacct as invdate,
	inv8.documentnobp as inv_documentnobp,
	inv8.documentno as inv_documentno,
	inv8.salesrep_id as salesrep_id,
	inv8.dateshipment as invshipdate,
    adempiere.amf_invoicepaymenttermduedate(inv8.c_paymentterm_id, inv8.c_invoice_id)::timestamp without time zone AS invduedate, 
    -- 30
	date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv8.c_paymentterm_id, inv8.c_invoice_id), inv8.dateinvoiced ) ) as invdaysdue, 
    --	adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv8.c_invoice_id)::timestamp without time zone AS invduedateps, 
	coalesce(invps.duedate, adempiere.amf_invoicepaymenttermduedate(inv8.c_paymentterm_id, inv8.c_invoice_id)::timestamp without time zone) AS invduedateps, 	
	CASE WHEN invps.duedate IS NULL THEN 0 ELSE 1 END AS  invduedateps_ok,
	-- INVOICE AMOUNTS
	inv8.amount, inv1.c_currency_id, inv8.c_currency_id,
    currencyConvert( inv8.amount, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv8.ad_client_id,inv8.ad_org_id) as payamount, 
    0 as discountamt, 
    0 as writeoffamt, 
    0 as taxamt,
     -- 40
    0 as overunderamt, 
    currencyConvert( inv1.grandtotal, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoiceamt, 
    currencyConvert( invt.taxamt, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoicetax,   
    0 as invoicetaxret,
    0 as servdist,
    'N' as isapproved, 
    inv8.docstatus, 
    inv8.docaction, 
    inv8.documentno, 
    inv8.dateacct,
     -- 50
    inv8.dateacct as datepaytrx,
   -- inv8.datedeposit as datedeposit,
    inv1.dateshipment as datedeposit,
    pterm.netdays,
    1 AS imprimir_rep
    FROM adempiere.c_invoice inv1  
    LEFT JOIN C_Doctype dtyp ON (dtyp.C_Doctype_ID = inv1.C_Doctype_ID) 
    --LEFT JOIN adempiere.c_invoicetax invt ON (inv1.c_invoice_id = invt.c_invoice_id)
    LEFT JOIN (
    	SELECT 
		c_invoice_id , dateacct,
		sum(taxbaseamt_exe) as taxbaseamt_exe, 
		sum(taxbaseamt_gen) as taxbaseamt_gen, 
		sum(taxbaseamt_red) as taxbaseamt_red, 
		sum(taxbaseamt_adi) as taxbaseamt_adi,
		sum(taxamt_gen) + sum(taxamt_red) + sum(taxamt_adi) as taxamt, 
		sum(taxamt_gen) as taxamt_gen, 
		sum(taxamt_red) as taxamt_red, 
		sum(taxamt_adi) as taxamt_adi
		FROM (
			SELECT 
				c_invoice_id, dateacct,
				CASE WHEN taxindicator = 'IVAEXE' then taxbaseamt ELSE 0 END as taxbaseamt_exe,
				CASE WHEN taxindicator = 'IVAGEN' then taxbaseamt ELSE 0 END as taxbaseamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxbaseamt ELSE 0 END as taxbaseamt_red,
				CASE WHEN taxindicator = 'IVAADI' then taxbaseamt ELSE 0 END as taxbaseamt_adi,
				CASE WHEN taxindicator = 'IVAGEN' then taxamt ELSE 0 END as taxamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxamt ELSE 0 END as taxamt_red,
				CASE WHEN taxindicator = 'IVARED' then taxamt ELSE 0 END as taxamt_adi
			FROM (
				SELECT C_invoice_id, DateAcct,  SUM(linetotalamt) as taxbaseamt , SUM(taxamt) as taxamt , rate, taxname, taxindicator
				FROM (
					SELECT
					inv.C_invoice_id, inv.dateacct, inl.c_tax_id, 
					inl.linetotalamt,  
					inl.taxamt, 
					txx.rate, 
					txx.name as taxname, 
					txx.taxindicator
					FROM C_invoice as inv
					LEFT JOIN c_invoiceline as inl ON inl.c_invoice_id= inv.c_invoice_id
					LEFT JOIN C_tax as txx ON txx.c_tax_id = inl.c_tax_id
				) AS imp
			GROUP BY imp.c_invoice_id, imp.DateAcct, imp.c_tax_id, imp.rate, imp.taxname, imp.taxindicator
			) AS impres
		) as impres2
		where dateacct BETWEEN $P{DateIni}  	AND $P{DateEnd}
		GROUP BY impres2.c_invoice_id, impres2.dateacct
    ) as invt ON (inv1.c_invoice_id = invt.c_invoice_id)    
    LEFT JOIN adempiere.C_InvoicePaySchedule invps ON (inv1.c_invoice_id = invps.c_invoice_id)
    LEFT JOIN adempiere.C_PaymentTerm pterm ON (inv1.C_PaymentTerm_ID = pterm.C_PaymentTerm_ID)
    LEFT JOIN adempiere.c_allocationline call9  ON (call9.c_invoice_id = inv1.c_invoice_id)
    LEFT JOIN adempiere.C_AllocationHdr allochdr9 ON(call9.C_AllocationHdr_ID= allochdr9.C_AllocationHdr_ID)
    LEFT JOIN adempiere.C_AllocationLine alloclin8 ON (alloclin8.C_AllocationHdr_ID = allochdr9.C_AllocationHdr_ID)
    LEFT JOIN (
    	-- Withholding Invoices related to Invoices an Then Invoices related to Payments
	    SELECT inv80.c_invoice_id, inv80.dateacct,  cdty80.isseniatbook, inv80.dateshipment,
	          inv80.docstatus, inv80.docaction, cdty80.C_DocType_ID,
	          inv80.documentnobp, inv80.salesrep_id,inv80.c_paymentterm_id, inv80.dateinvoiced, 
	          inv80.ad_client_id, inv80.ad_org_id, inv80.c_currency_id, inv80.c_conversiontype_id,
	          COALESCE(pay70.datedeposit, inv80.dateacct) as datedeposit,
	          pay70.payamt, alloclin80.amount, pay70.c_payment_id, 
	          COALESCE(pay70.documentno,inv80.documentno,' - ') as documentno,
	          CASE WHEN pay70.C_payment_ID IS NULL THEN 'Factura No Tiene Pagos' 
	                    ELSE '' END as doc_nota
	 	FROM C_invoice inv90
		LEFT JOIN adempiere.C_DocType as cdty90 ON (cdty90.C_DocType_ID = inv90. C_DocType_ID )
		LEFT JOIN adempiere.c_allocationline call90  ON (call90.c_invoice_id = inv90.c_invoice_id)
		LEFT JOIN adempiere.C_AllocationHdr allochdr90 ON(call90.C_AllocationHdr_ID= allochdr90.C_AllocationHdr_ID)
		LEFT JOIN adempiere.C_AllocationLine alloclin80 ON (alloclin80.C_AllocationHdr_ID = allochdr90.C_AllocationHdr_ID)
		LEFT JOIN adempiere.C_Invoice inv80 ON (inv80.C_Invoice_ID = alloclin80.C_Invoice_ID)
		LEFT JOIN adempiere.C_DocType as cdty80 ON (cdty80.C_DocType_ID = inv80. C_DocType_ID )
		LEFT JOIN adempiere.C_AllocationLine alloclin70 ON (alloclin70.C_Invoice_ID = inv80.C_Invoice_ID)
		LEFT JOIN adempiere.C_Payment pay70 ON (pay70.C_payment_ID = alloclin70.C_payment_ID)
		WHERE  inv90.ad_client_id=$P{AD_Client_ID}  
		AND inv90.dateacct >= DATE($P{DateIni}) - interval '180 DAYS'  	AND inv90.dateacct <= DATE($P{DateEnd})
		AND inv90.ad_org_id=$P{AD_Org_ID} 
		AND inv80.C_DocType_ID IN (
			 SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARI')  AND C_DocType.AD_Client_ID=$P{AD_Client_ID} 
		AND C_DocType.isSeniatBook IN ('I')  )
		AND inv90.C_DocType_ID IN (
			 SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARC')  AND C_DocType.AD_Client_ID=$P{AD_Client_ID} 
		AND C_DocType.isSeniatBook IN ('W')  )
		AND cdty80.isseniatbook ='I'
    ) as inv8 ON (inv8.c_invoice_id = alloclin8.c_invoice_id)
    --
    LEFT JOIN adempiere.C_DocType as cdty8 ON (cdty8.C_DocType_ID = inv8. C_DocType_ID)
	LEFT JOIN c_currency curr1 on inv1.c_currency_id = curr1.c_currency_id
    LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
    LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
    LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE
	inv1.ad_client_id=$P{AD_Client_ID} 
	AND inv1.ad_org_id=$P{AD_Org_ID} 
	AND inv1.dateacct BETWEEN $P{DateIni}  	AND $P{DateEnd} 
	AND (inv1.docstatus = 'CO' OR inv1.docstatus = 'CL' )
	AND cdty8.isSeniatBook='I'
	AND inv1.C_DocType_ID IN ( 
			SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARC') AND C_DocType.isSeniatBook IN ('W')  
			AND C_DocType.AD_Client_ID=$P{AD_Client_ID} 
			)
    AND inv8.c_payment_id IS NULL
    AND CASE WHEN  $P{AD_User_ID} IS NULL OR inv1.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END
