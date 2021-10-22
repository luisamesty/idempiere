-- 
WITH INVOICESALL AS (
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
	-- INVOICE AMOUNTS
    currencyConvert(invpay.amountpay, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as payamount, 
    currencyConvert( pay.discountamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as discountamt, 
    currencyConvert( pay.writeoffamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as writeoffamt, 
    currencyConvert( pay.taxamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as taxamt, 
    currencyConvert( pay.overunderamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as overunderamt, 
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
--
UNION
--
    -- *********************************************************
  	-- ALLOCATIONS PAYMENTS FROM CUSTOMERS ON PERIOD
    -- *********************************************************
    SELECT   
	-- 0
	2 as sel,
	'A' as tipo,
	pay.c_payment_id,
	pay.ad_client_id, 
	pay.ad_org_id, 
	pay.isactive, 
	pay.documentno as pay_documentno, 
	pay.description,
	'' as bp_value,
	pay.datetrx, 
	pay.isreceipt, 
    -- 10
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
    -- 20
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
    -- 30
	inv1.dateacct as invdate,
	inv1.documentnobp as inv_documentnobp,
	inv1.documentno as inv_documentno,
	inv1.salesrep_id as salesrep_id,
	inv1.dateshipment as invshipdate,
    adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id)::timestamp without time zone AS invduedate, 
	date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id), inv1.dateinvoiced ) ) as invdaysdue, 
	coalesce(invps.duedate, adempiere.amf_invoicepaymenttermduedate(inv1.c_paymentterm_id, inv1.c_invoice_id)::timestamp without time zone) AS invduedateps, 	
	CASE WHEN invps.duedate IS NULL THEN 0 ELSE 1 END AS  invduedateps_ok,
	-- INVOICE AMOUNTS
    currencyConvert( payall.amount, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as payamount, 
     -- 40 
    currencyConvert( pay.discountamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as discountamt, 
    currencyConvert( pay.writeoffamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as writeoffamt, 
    currencyConvert( pay.taxamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as taxamt, 
    currencyConvert( pay.overunderamt, pay.c_currency_id,$P{C_Currency_ID},pay.dateacct,pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id) as overunderamt, 
    currencyConvert( inv1.grandtotal, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoiceamt, 
    currencyConvert( invt.taxamt, inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as invoicetax,   
    CASE WHEN invwhh.dateacct >$P{DateEnd}  THEN 0
         WHEN invwhh.dateacct  < $P{DateIni} THEN 0
         ELSE currencyConvert( coalesce(invwhh.amountwhh,0), inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) 
         END as invoicetaxret,
    currencyConvert( coalesce(invlin2.linenetamt,0), inv1.c_currency_id,$P{C_Currency_ID},inv1.dateacct,inv1.C_ConversionType_ID,inv1.ad_client_id,inv1.ad_org_id) as servdist, 
    pay.isapproved, 
    pay.docstatus, 
    pay.docaction, 
    pay.documentno, 
    pay.dateacct,
	-- 50
    pay.datetrx as datepaytrx,
    pay.datedeposit ,
    pterm.netdays,
    1 AS imprimir_rep
    FROM adempiere.c_paymentallocate payall 
    LEFT JOIN adempiere.c_payment pay ON (payall.c_payment_id = pay.c_payment_id)
    LEFT JOIN adempiere.c_invoice inv1 ON (inv1.c_invoice_id = payall.c_invoice_id)
    LEFT JOIN C_Doctype dtyp ON (dtyp.C_Doctype_ID = inv1.C_Doctype_ID)
--    LEFT JOIN adempiere.c_invoicetax invt ON (inv1.c_invoice_id = invt.c_invoice_id)
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
    LEFT JOIN ( SELECT DISTINCT ON (c_invoice_id) * FROM adempiere.c_invoiceline as invlin  LEFT JOIN adempiere.ad_clientinfo clinf ON (clinf.ad_client_id = invlin.ad_client_id) WHERE invlin.m_product_id = clinf.m_productfreight_id )
	as invlin2 ON (invlin2.c_invoice_id = inv1.c_invoice_id)
	LEFT JOIN (
		select alloclin1.c_invoice_id, sum(alloclin1.amount) as amountpay FROM adempiere.c_allocationline as alloclin1
		WHERE alloclin1.c_payment_id  > 0
		GROUP BY alloclin1.c_invoice_id
	) as invpay ON (invpay.c_invoice_id = inv1.c_invoice_id)
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
	AND pay.C_DocType_ID IN (
		 SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARR')  AND C_DocType.AD_Client_ID=$P{AD_Client_ID} 
	AND C_DocType.isSeniatBook IN ('I','D')  )
    AND pay.c_bankaccount_id IN ( 
		SELECT C_BankAccount_ID FROM C_BankAccount WHERE AD_Client_ID=$P{AD_Client_ID}
		AND ( CASE WHEN BankAccountType ='B'  AND $P{BankAccountType} = 'B' THEN 1=1 ELSE 1=0 END
		OR CASE WHEN BankAccountType = 'C' AND $P{BankAccountType} = 'C' THEN 1=1 ELSE 1=0 END
		OR CASE WHEN  $P{BankAccountType} = 'A' THEN 1=1 ELSE 1=0 END )
	)
	AND CASE WHEN  $P{AD_User_ID} IS NULL OR inv1.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END
--
UNION 
--
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
    currencyConvert( inv8.amount, inv8.c_currency_id,$P{C_Currency_ID},inv8.dateacct,inv8.C_ConversionType_ID,inv8.ad_client_id,inv8.ad_org_id) as payamount, 
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
--
UNION
--
    -- *********************************************************
    --  ALLOCATIONS PAYMENTS FROM CUSTOMERS ON PERIOD
  	--	BETWEEN TWO Business Partners including 113438 
  	--  Documents to be identified
    -- *********************************************************
    SELECT   
	-- 0
	2 as sel,
	'A' as tipo,
	pay1a.c_payment_id,
	pay1a.ad_client_id, 
	pay1a.ad_org_id, 
	pay1a.isactive, 
	pay1a.documentno as pay_documentno, 
	pay1a.description as description,
	CONCAT('(',cbpp.Value,'_',cbpi.value,') ') as bp_value,
	pay1a.datetrx, 
	pay1a.isreceipt, 
    -- 10
	pay1a.c_doctype_id, 
    pay1a.trxtype, 
    pay1a.c_bankaccount_id, 
    inv1a.c_bpartner_id, 
    pay1a.c_invoice_id, 
    pay1a.c_bp_bankaccount_id, 
    pay1a.tendertype, 
    pay1a.c_currency_id, 
    -- CURRENCY
	curr1.iso_code as iso_code1,
	currt1.cursymbol as cursymbol1,
	-- 20
	COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
    curr2.iso_code as iso_code2,
	currt2.cursymbol as cursymbol2,
	COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,  
	-- INVOICE DATA
	' ' as doc_nota,
    dtypa.isseniatbook as doc_isseniatbook,
    inv1a.c_doctype_id as doc_c_doctype_id,
    inv1a.dateacct as doc_date,
	inv1a.documentno as doc_documentno,
	dtypa.isseniatbook as inv_isseniatbook,
	-- 30
	inv1a.dateacct as invdate,
	inv1a.documentnobp as inv_documentnobp,
	inv1a.documentno as inv_documentno,
	inv1a.salesrep_id as salesrep_id,
	inv1a.dateshipment as invshipdate,
    adempiere.amf_invoicepaymenttermduedate(inv1a.c_paymentterm_id, inv1a.c_invoice_id)::timestamp without time zone AS invduedate, 
	date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv1a.c_paymentterm_id, inv1a.c_invoice_id), inv1a.dateinvoiced ) ) as invdaysdue, 
	coalesce(invpsa.duedate, adempiere.amf_invoicepaymenttermduedate(inv1a.c_paymentterm_id, inv1a.c_invoice_id)::timestamp without time zone) AS invduedateps, 	
	CASE WHEN invpsa.duedate IS NULL THEN 0 ELSE 1 END AS  invduedateps_ok,
	-- INVOICE AMOUNTS
    currencyConvert( alllin.amount, inv1a.c_currency_id,$P{C_Currency_ID},inv1a.dateacct,inv1a.C_ConversionType_ID,inv1a.ad_client_id,inv1a.ad_org_id) as payamount, 
	-- 40
    currencyConvert( alllin.discountamt, pay1a.c_currency_id,$P{C_Currency_ID},pay1a.dateacct,pay1a.C_ConversionType_ID,pay1a.ad_client_id,pay1a.ad_org_id) as discountamt, 
    currencyConvert( alllin.writeoffamt, pay1a.c_currency_id,$P{C_Currency_ID},pay1a.dateacct,pay1a.C_ConversionType_ID,pay1a.ad_client_id,pay1a.ad_org_id) as writeoffamt, 
    currencyConvert( invta.taxamt, pay1a.c_currency_id,$P{C_Currency_ID},pay1a.dateacct,pay1a.C_ConversionType_ID,pay1a.ad_client_id,pay1a.ad_org_id) as taxamt, 
    currencyConvert( alllin.overunderamt, pay1a.c_currency_id,$P{C_Currency_ID},pay1a.dateacct,pay1a.C_ConversionType_ID,pay1a.ad_client_id,pay1a.ad_org_id) as overunderamt, 
    currencyConvert( inv1a.grandtotal, inv1a.c_currency_id,$P{C_Currency_ID},inv1a.dateacct,inv1a.C_ConversionType_ID,inv1a.ad_client_id,inv1a.ad_org_id) as invoiceamt, 
    currencyConvert( invta.taxamt, inv1a.c_currency_id,$P{C_Currency_ID},inv1a.dateacct,inv1a.C_ConversionType_ID,inv1a.ad_client_id,inv1a.ad_org_id) as invoicetax,   
    CASE WHEN invwhha.dateacct > $P{DateEnd}  THEN 0
         WHEN invwhha.dateacct < $P{DateIni} THEN 0
         ELSE currencyConvert( coalesce(invwhha.amountwhh,0), inv1a.c_currency_id,$P{C_Currency_ID},inv1a.dateacct,inv1a.C_ConversionType_ID,inv1a.ad_client_id,inv1a.ad_org_id) 
         END as invoicetaxret,
    currencyConvert( coalesce(invlin2a.linenetamt,0), inv1a.c_currency_id,$P{C_Currency_ID},inv1a.dateacct,inv1a.C_ConversionType_ID,inv1a.ad_client_id,inv1a.ad_org_id) as servdist, 
    pay1a.isapproved, 
    pay1a.docstatus, 
	-- 50
 	pay1a.docaction, 
    pay1a.documentno, 
    pay1a.dateacct,
    pay1a.datetrx as datepaytrx,
    pay1a.datedeposit ,
    pterma.netdays,
    1 AS imprimir_rep
    FROM C_Allocationline alllin
    LEFT JOIN C_AllocationHdr allhdr ON allhdr.C_AllocationHdr_ID= alllin.C_AllocationHdr_ID
    LEFT JOIN adempiere.c_payment pay1a ON (alllin.c_payment_id = pay1a.c_payment_id)
    LEFT JOIN adempiere.c_invoice inv1a ON (inv1a.c_invoice_id = alllin.c_invoice_id)
    LEFT JOIN C_Doctype dtypa ON (dtypa.C_Doctype_ID = inv1a.C_Doctype_ID)
    LEFT JOIN C_BPartner cbpp ON cbpp.C_BPartner_ID= pay1a.C_BPartner_ID
    LEFT JOIN C_BPartner cbpi ON cbpi.C_BPartner_ID= inv1a.C_BPartner_ID    
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
    ) as invta ON (inv1a.c_invoice_id = invta.c_invoice_id)
    LEFT JOIN adempiere.C_InvoicePaySchedule invpsa ON (inv1a.c_invoice_id = invpsa.c_invoice_id)
    LEFT JOIN adempiere.C_PaymentTerm pterma ON (inv1a.C_PaymentTerm_ID = pterma.C_PaymentTerm_ID)
    LEFT JOIN ( 
    	SELECT DISTINCT ON (c_invoice_id) * FROM adempiere.c_invoiceline as invlin  LEFT JOIN adempiere.ad_clientinfo clinf ON (clinf.ad_client_id = invlin.ad_client_id) WHERE invlin.m_product_id = clinf.m_productfreight_id
    ) as invlin2a ON (invlin2a.c_invoice_id = inv1a.c_invoice_id)
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
	) as invwhha ON (invwhha.c_invoice_id = inv1a.c_invoice_id)
	LEFT JOIN c_currency curr1 on pay1a.c_currency_id = curr1.c_currency_id
    LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
    LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
    LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
    WHERE
	alllin.ad_client_id=$P{AD_Client_ID} 
	AND alllin.ad_org_id=$P{AD_Org_ID} 
	AND allhdr.datetrx BETWEEN $P{DateIni}  AND  $P{DateEnd} 
	AND inv1a.C_DocType_ID IN (
		SELECT C_DocType_ID FROM C_DocType WHERE C_DocType.DocBaseType IN ( 'ARI')  AND C_DocType.AD_Client_ID=$P{AD_Client_ID} 
		AND C_DocType.isSeniatBook IN ('I','D')  
	)
	AND CASE WHEN  $P{AD_User_ID} IS NULL OR inv1a.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END
	AND alllin.c_bpartner_id <> inv1a.c_bpartner_id 
	-- BETWEEN TWO Business Partners
)
-- *******************************************************************************
-- QUERY FINAL UNION
-- *******************************************************************************
SELECT 
invall.sel,
invall.tipo,
cbp.c_bpartner_id as c_bpartner_id,
-- ORGANIZATION
coalesce(adempiere.ad_org.name,adempiere.ad_org.description,'') as org_name,
coalesce(adempiere.ad_orginfo.taxid,'') as org_taxid,
adempiere.ad_image.binarydata as org_logo,
-- CURRENCY
invall.iso_code1,
invall.cursymbol1,
invall.currname1,
invall.iso_code2,
invall.cursymbol2,
invall.currname2,
-- BUSINESS PARTNER
cbp.value as cliente,
cbp.name as bp_name,
invall.bp_value as bp_value,
cbp.taxid as bp_taxid,
coalesce(cbp.amerp_nameseniat,cbp.name,'') as amerp_nameseniat,
coalesce(cbp.amerp_rifseniat,cbp.taxid,'') as amerp_rifseniat,
-- Sales Rep
invall.salesrep_id,
salesrep.name as rep_ventas,
-- JUAN PEDRO Rep 11 (1004548) 5% y 6 % -  RESTO 3%
--coalesce(salesrep.percentage,0) as percentage,
-- PERCENTAGE BASE
coalesce(salesrep.percentage,0) as percentage,
-- PERCENTAGE PLUS  
 CASE 	WHEN invall.salesrep_id = 1004548 AND date_part('day',(invall.datedeposit - invall.invduedateps)) >= 0  THEN 0
 		WHEN invall.salesrep_id = 1004548 AND date_part('day',(invall.datedeposit - invall.invduedateps)) < 0  THEN 1
        WHEN invall.salesrep_id != 1004548 THEN 0
          ELSE 0 END as percentageplus,
-- PAYMENT HEADER
invall.pay_documentno,
invall.docstatus,
invall.c_payment_id,
invall.c_bpartner_id,
adempiere.c_doctype_trl.printname as doc_type,
adempiere.c_doctype.docbasetype as doc_basetype,
invall.doc_nota,
invall.doc_isseniatbook,
invall.doc_c_doctype_id,
invall.doc_date,
invall.doc_documentno,
invall.inv_isseniatbook,
invall.invdate,
invall.inv_documentnobp,
invall.inv_documentno,
invall.documentno, 
invall.dateacct,
invall.datepaytrx,
invall.datedeposit,
invall.invduedate,
invall.invshipdate,
invall.invduedateps,
invall.invduedateps_ok,
date(invall.invduedateps) - date(invall.invdate) as invdays,
invall.invdaysdue,
invall.netdays as netdays_doc,
coalesce(ptermbp.netdays,0) as netdays_bp,
--CASE WHEN invall.invdaysdue <= 20 THEN  date(invall.invduedate) +10  ELSE date(invall.invduedate) END as invmaxdate,
--CASE WHEN invall.netdays <= 20 THEN  date(invall.invduedate)   ELSE date(invall.invduedate) END as invmaxdate,
-- STATIC
date(invall.invshipdate + $P{AddDays}) as invmaxdate,
--date_part('day',(invall.datedeposit - invall.invduedate)) +10 as invdaysdiff,
date(invall.datedeposit) - (date(invall.invduedateps) +10) as invdaysdiff,
date_part('day',(invall.datedeposit - invall.invduedateps)) as invdaysdiff2,
date_part('day',(invall.datedeposit - invall.invshipdate)) as invdaysdiff3,
date_part('day',(invall.datedeposit - invall.invduedate)) as invdaysdiff4,
-- INVOICE AMOUNTS
invall.payamount,
invall.discountamt, 
invall.writeoffamt, 
invall.taxamt,
invall.overunderamt, 
invall.invoiceamt,
invall.invoicetax,
invall.invoicetaxret,
invall.servdist,
-- PREMIO -- JUAN PEDRO Rep 11 (1004548)   0% -- Rep 05 JOSE CONTRERAS (1000004) 4% y 5%
-- PREMIO BASE
CASE WHEN invall.doc_isseniatbook = 'N' THEN
	--  NON DOCUMENTS CD (RETURN CHECK)
	CASE WHEN invall.salesrep_id = 1004548  THEN 5   -- REP 11
	     WHEN invall.salesrep_id = 1000004  THEN 3   -- REP 05
	     WHEN invall.salesrep_id = 1000006  THEN 0	 -- REP 06
	     WHEN invall.salesrep_id = 1000008  THEN 0   -- REP 08
	     WHEN invall.salesrep_id = 1000009  THEN 0   -- REP 09
	     ELSE 0 END          
	WHEN invall.doc_isseniatbook != 'N' THEN
	--  ALL DOCUMNENTS SAME
	CASE WHEN invall.salesrep_id = 1004548  THEN 0
	     WHEN invall.salesrep_id = 1000004  THEN 3
	     WHEN invall.salesrep_id != 1000004 
	     	AND invall.salesrep_id != 1004548 
	     	AND date_part('day',(invall.datedeposit - invall.invduedateps)) >=0 THEN 0 
		 ELSE 1 END
	ELSE 0 END as percentagepremio,     
-- PREMIO PLUS
CASE WHEN invall.doc_isseniatbook = 'N' THEN
	--  NON DOCUMENTS CD (RETURN CHECK)
	CASE WHEN invall.salesrep_id = 1004548  THEN 0   -- REP 11
		 WHEN invall.salesrep_id = 1000004  THEN 0   -- REP 05
	     WHEN invall.salesrep_id = 1000005  THEN 0	 -- REP 06
	     WHEN invall.salesrep_id = 1000007  THEN 0   -- REP 08
	     WHEN invall.salesrep_id = 1000008  THEN 0   -- REP 09
			 ELSE 0 END        
	--  ALL DOCUMNENTS SAME
	WHEN invall.doc_isseniatbook != 'N' THEN
		CASE WHEN invall.salesrep_id = 1004548  THEN 0   -- REP 11
		 	WHEN invall.salesrep_id = 1000004 AND date_part('day',(invall.datedeposit - invall.invduedateps)) > 0 THEN 0   -- REP 05 CREDITO
		 	WHEN invall.salesrep_id = 1000004 AND date_part('day',(invall.datedeposit - invall.invduedateps)) <= 0 THEN 1  -- REP 05 CONTADO
		 	WHEN invall.salesrep_id = 1000005  THEN 0	-- REP 06
	     	WHEN invall.salesrep_id = 1000007  THEN 0   -- REP 08
	     	WHEN invall.salesrep_id = 1000008  THEN 0   -- REP 09
			WHEN invall.salesrep_id = 1000004 
				AND date_part('day',(invall.datedeposit - invall.invduedateps)) >= 0 THEN 0
		     	ELSE 1 END 
	ELSE 0 END as percentagepremioplus,         
-- PAYMENT HEADER - BANK ACCOUNT
case  when invall.description is null then '' else '' || invall.description  end  as description_head,
coalesce(baa.value,'') as pay_bank,
coalesce(baa.name,'') as pay_bankname
--
FROM
INVOICESALL as invall
LEFT JOIN adempiere.ad_org ON adempiere.ad_org.ad_org_id = invall.ad_org_id
LEFT JOIN adempiere.ad_orginfo  ON adempiere.ad_org.ad_org_id = adempiere.ad_orginfo.ad_org_id
LEFT JOIN adempiere.ad_image ON adempiere.ad_orginfo.logo_id= adempiere.ad_image.ad_image_id
LEFT JOIN adempiere.c_location ON adempiere.c_location.c_location_id = adempiere.ad_orginfo.c_location_id
LEFT JOIN adempiere.c_bpartner cbp ON cbp.c_bpartner_id = invall.c_bpartner_id
LEFT JOIN ( SELECT DISTINCT ON (c_bpartner_id) * FROM adempiere.c_bpartner_location as cbp_loc WHERE cbp_loc.isbillto='Y'   LIMIT 1 ) 
        as cbp_l ON cbp.c_bpartner_id = cbp_l.c_bpartner_id  
LEFT JOIN ( SELECT DISTINCT ON (c_bpartner_id) * FROM adempiere.ad_user  ) 
        as cbp_usr ON cbp.c_bpartner_id = cbp_usr.c_bpartner_id  
LEFT JOIN adempiere.c_doctype on invall.c_doctype_id = adempiere.c_doctype.c_doctype_id
LEFT JOIN adempiere.c_doctype_trl on invall.c_doctype_id = adempiere.c_doctype_trl.c_doctype_id
LEFT JOIN adempiere.c_bankaccount baa ON invall.c_bankaccount_id=baa.c_bankaccount_id
LEFT JOIN adempiere.ad_user as salesrep on salesrep.ad_user_id = invall.salesrep_id
LEFT JOIN adempiere.C_PaymentTerm ptermbp ON (cbp.C_PaymentTerm_ID = ptermbp.C_PaymentTerm_ID)
WHERE adempiere.c_doctype_trl.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
AND invall.salesrep_id IS NOT NULL
AND ( invall.inv_isseniatbook IN ('I','W','D') OR invall.Doc_C_doctype_id =1000055 )
ORDER BY invall.salesrep_id,  invall.sel DESC , invall.inv_documentno, invall.datedeposit ASC