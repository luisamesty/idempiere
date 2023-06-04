  -- UNION 1
  -- ******************************************
  -- PAYMENTS FROM CUSTOMERS ON PERIOD
  -- ******************************************
  SELECT  
	2 as sel,
	'P' as tipo,
	pay.c_payment_id,
	pay.ad_client_id, 
	pay.ad_org_id, 
	pay.isactive, 
	pay.documentno as pay_documentno, 
	pay.description,
	'' as bp_value,
	pay.datetrx, 
	pay.isreceipt, 
	pay.c_doctype_id, 
        pay.trxtype, 
        pay.c_bankaccount_id, 
        pay.c_bpartner_id, 
        pay.c_invoice_id, 
        pay.c_bp_bankaccount_id, 
        pay.tendertype, 
        pay.c_currency_id, 
    -- CURRENCY
	curr1.iso_code as iso_code1,
	currt1.cursymbol as cursymbol1,
	COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
    curr2.iso_code as iso_code2,
	currt2.cursymbol as cursymbol2,
	COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,  
    -- INVOICE DATA
    ' ' as doc_nota,
    dtyp.isseniatbook as doc_isseniatbook,
    inv1.c_doctype_id as doc_c_doctype_id,
    inv1.dateacct as doc_date,
	inv1.documentno as doc_documentno,
	dtyp.isseniatbook as inv_isseniatbook,
	inv1.dateacct as invdate,
	inv1.documentnobp as inv_documentnobp,
	inv1.documentno as inv_documentno,
	inv1.salesrep_id as salesrep_id,
	inv1.dateshipment as invshipdate,
	adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id)::timestamp without time zone AS invduedate, 
	date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id), inv1.dateinvoiced ) ) as invdaysdue, 
	coalesce(invps.duedate, adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id)::timestamp without time zone) AS invduedateps, 	
	CASE WHEN invps.duedate IS NULL THEN 0 ELSE 1 END AS  invduedateps_ok, 
	-- INVOICE AMOUNTS (Replaced pay.C_ConversionType_ID with inv1.C_ConversionType_ID AND pay.dateacct with inv1.dateacct) for Invoice Conversion Type applied
    currencyConvert(invpay.amountpay, pay.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as payamount, 
    currencyConvert( pay.discountamt, pay.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as discountamt, 
    currencyConvert( pay.writeoffamt, pay.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as writeoffamt, 
    currencyConvert( pay.taxamt, pay.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as taxamt, 
    currencyConvert( pay.overunderamt, pay.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as overunderamt, 
    currencyConvert( inv1.grandtotal, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoiceamt, 
    currencyConvert( invt.taxamt, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoicetax, 
    CASE WHEN invwhh.dateacct >$P{DateEnd}  THEN 0
         WHEN invwhh.dateacct  < $P{DateIni} THEN 0
         ELSE 0 END as invoicetaxret,
    currencyConvert( coalesce(invlin2.linenetamt,0), inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as servdist, 
	--
    pay.isapproved, 
    pay.docstatus, 
    pay.docaction, 
    pay.documentno, 
    pay.dateacct,
    pay.datetrx  as datepaytrx,
    pay.datedeposit ,
    pterm.netdays,
    1 AS imprimir_rep
    FROM adempiere.c_payment pay 
    LEFT JOIN (
		select alloclin1.c_invoice_id, sum(alloclin1.amount) as amountpay, alloclin1.c_payment_id FROM adempiere.c_allocationline as alloclin1
		WHERE alloclin1.c_payment_id  > 0
		GROUP BY alloclin1.c_invoice_id, alloclin1.c_payment_id 
	) as invpay ON (invpay.c_payment_id = pay.c_payment_id)
    LEFT JOIN adempiere.ad_clientinfo clinf ON (clinf.ad_client_id = pay.ad_client_id)
    LEFT JOIN adempiere.c_invoice inv1 ON (inv1.c_invoice_id = invpay.c_invoice_id)
    LEFT JOIN C_Doctype dtyp ON (dtyp.C_Doctype_ID = inv1.C_Doctype_ID)
    --LEFT JOIN adempiere.c_invoicetax invt ON (inv1.c_invoice_id = invt.c_invoice_id)
    LEFT JOIN (
    	SELECT 
		c_invoice_id , 
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
				c_invoice_id,
				CASE WHEN taxindicator = 'IVAEXE' then taxbaseamt ELSE 0 END as taxbaseamt_exe,
				CASE WHEN taxindicator = 'IVAGEN' then taxbaseamt ELSE 0 END as taxbaseamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxbaseamt ELSE 0 END as taxbaseamt_red,
				CASE WHEN taxindicator = 'IVAADI' then taxbaseamt ELSE 0 END as taxbaseamt_adi,
				CASE WHEN taxindicator = 'IVAGEN' then taxamt ELSE 0 END as taxamt_gen,
				CASE WHEN taxindicator = 'IVARED' then taxamt ELSE 0 END as taxamt_red,
				CASE WHEN taxindicator = 'IVARED' then taxamt ELSE 0 END as taxamt_adi
			FROM (
				SELECT C_invoice_id, SUM(linetotalamt) as taxbaseamt , SUM(taxamt) as taxamt , rate, taxname, taxindicator
				FROM (
					SELECT
					inv.C_invoice_id, inl.c_tax_id, 
					inl.linetotalamt,  
					inl.taxamt, 
					txx.rate, 
					txx.name as taxname, 
					txx.taxindicator
					FROM C_invoice as inv
					LEFT JOIN c_invoiceline as inl ON inl.c_invoice_id= inv.c_invoice_id
					LEFT JOIN C_tax as txx ON txx.c_tax_id = inl.c_tax_id
				) AS imp
			GROUP BY imp.c_invoice_id, imp.c_tax_id, imp.rate, imp.taxname, imp.taxindicator
			) AS impres
		) as impres2
		GROUP BY impres2.c_invoice_id
    ) as invt ON (inv1.c_invoice_id = invt.c_invoice_id)
    LEFT JOIN adempiere.C_InvoicePaySchedule invps ON (inv1.c_invoice_id = invps.c_invoice_id)
    LEFT JOIN adempiere.C_PaymentTerm pterm ON (inv1.C_PaymentTerm_ID = pterm.C_PaymentTerm_ID)
    LEFT JOIN ( SELECT DISTINCT ON (c_invoice_id) * FROM adempiere.c_invoiceline as invlin  LEFT JOIN adempiere.ad_clientinfo clinf ON (clinf.ad_client_id = invlin.ad_client_id) WHERE invlin.m_product_id = clinf.m_productfreight_id)
	as invlin2 ON (invlin2.c_invoice_id = inv1.c_invoice_id)
	LEFT JOIN (
		SELECT 
		alloclin2.c_invoice_id, alloclin2.amount as amountwhh , inv3.dateacct
		FROM adempiere.c_allocationline as alloclin2
		LEFT JOIN C_AllocationHdr allochdr3 ON(alloclin2.C_AllocationHdr_ID= allochdr3.C_AllocationHdr_ID)
		LEFT JOIN C_AllocationLine alloclin3 ON (alloclin3.C_AllocationHdr_ID = allochdr3.C_AllocationHdr_ID)
		LEFT JOIN C_Invoice inv3 ON (inv3.C_Invoice_ID = alloclin3.C_Invoice_ID)
		LEFT JOIN C_Doctype dty3 ON (dty3.C_Doctype_ID = inv3.C_Doctype_ID)
		WHERE alloclin2.c_payment_id  is null 
		AND dty3.isseniatbook='W' 
	) as invwhh ON (invwhh.c_invoice_id = inv1.c_invoice_id)
	LEFT JOIN c_currency curr1 on pay.c_currency_id = curr1.c_currency_id
    LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
    LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
    LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
    WHERE
    pay.ad_client_id=$P{AD_Client_ID} 
    AND pay.ad_org_id=$P{AD_Org_ID} 
    AND pay.datetrx BETWEEN  $P{DateIni}  AND  $P{DateEnd} 
    AND (pay.docstatus = 'CO' OR pay.docstatus = 'CL' )
    AND pay.C_DocType_ID IN ( SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARR')  AND C_DocType.AD_Client_ID=$P{AD_Client_ID} )
    AND pay.c_bankaccount_id IN ( 
		SELECT C_BankAccount_ID FROM C_BankAccount WHERE AD_Client_ID=$P{AD_Client_ID}
		AND ( CASE WHEN BankAccountType ='B'  AND $P{BankAccountType} = 'B' THEN 1=1 ELSE 1=0 END
		OR CASE WHEN BankAccountType = 'C' AND $P{BankAccountType} = 'C' THEN 1=1 ELSE 1=0 END
		OR CASE WHEN  $P{BankAccountType} = 'A' THEN 1=1 ELSE 1=0 END )
	)
 	AND CASE WHEN  $P{AD_User_ID} IS NULL OR inv1.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END 