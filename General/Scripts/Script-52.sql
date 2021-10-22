-- 5
-- UNALLOCATED PAYMENT 113438 (B_UNIDENTIFIED_ACCT)
-- Documentos No Conciliados Según Bancos
-- DNCSB
-- aparca: UROUT / UPOUT
--
	SELECT  DISTINCT ON (pay.C_payment_ID)
	bss.ad_client_id,
	bss.ad_org_id,
	bss.c_currency_id,
	bss.C_ConversionType_ID,
	pay.c_currency_id as tr_currency_id,
	pay.C_ConversionType_ID as tr_C_ConversionType_ID,
	currtr.iso_code as tr_isocode,
	currtr.iso_code as currency_code, 
	pay.C_Payment_ID AS C_Payment_ID,
	dct.docbasetype as docbasetype,
   	0 as Reconc_ID,
	cev.value as mayor_codigo,
	cev.name as mayor_name,
	--10
	'DNCSB' as dnc,
	'U' as dnc_source,
	'Documentos No Conciliados Según Bancos' as dnc_description,
	CASE 	WHEN pay.isreceipt = 'Y' THEN 'UROUT'
		WHEN pay.isreceipt = 'N' THEN 'UPOUT' 
	END as aparca,
	CASE WHEN pay.isreceipt = 'Y' THEN 'Depósitos y NC por Identificar'
	     WHEN pay.isreceipt = 'N' THEN 'Cheques y ND por Identificar' 
	END as aparca_description,
	rltt.list_value as Tender_Type, 
	rltrxt.list_value as Trx_Type, 
	CASE WHEN rltt.code='A' THEN 'Depósito' 
		WHEN rltt.code='C' THEN 'Tarjeta' 
		WHEN rltt.code='K' THEN 'Cheque' 
		WHEN rltt.code='T' THEN 'Cuenta' 
		WHEN rltt.code='X' THEN 'Efectivo' 
		WHEN rltt.code='D' THEN 'Débito' 
		ELSE rltt.list_value END  as Trx_Name, 
	pay.documentno as documentno, 
	pay.dateacct as dateacct, 
	-- 20
	COALESCE(pay.description,bp."name",'') as name, 	
	CASE WHEN bss.c_currency_id <> currtr.c_currency_id THEN CONCAT(currtr.iso_code,'-',currtr.cursymbol,'-',currtr.description)  ELSE '' END as name_src,	
	bss.C_BankStatement_ID, 
	0 as line, 
	pay.payamt as amtsource, 
	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt,pay.dateacct) as amtacct,	
	bss.docstatus,
	COALESCE(bss.beginningbalance,0) as journal_balance,
	COALESCE(bss.endingbalance,0) as  book_balance,
	bss.dateacct as bst_date
		FROM
	C_Payment pay
	LEFT JOIN C_BankAccount ban ON (pay.C_BankAccount_ID = ban.C_BankAccount_ID)
	LEFT JOIN C_Bank bax ON (bax.c_bank_id= ban.c_bank_id)	
    LEFT JOIN c_doctype as dct ON (dct.c_doctype_id = pay.c_doctype_id)
	LEFT JOIN (
		SELECT 
		c_bankstatement_id, c_bankaccount_id, ad_client_id, ad_org_id, c_currency_id, C_ConversionType_ID,
		docstatus, beginningbalance, endingbalance, dateacct 
		FROM C_BankStatement bs WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID}
	) bss ON (bss.C_BankAccount_ID = pay.C_BankAccount_ID)
	LEFT JOIN C_BankAccount_Acct baa ON (baa.C_BankAccount_ID = ban.C_BankAccount_ID)
	LEFT JOIN C_Validcombination ia ON (ia.C_Validcombination_ID = baa.B_Unidentified_Acct) 
	LEFT JOIN C_ElementValue cev ON (cev.C_ElementValue_ID = ia.Account_ID)
	LEFT JOIN C_Charge cha ON (cha.C_Charge_ID = pay.C_Charge_ID )
	LEFT JOIN c_currency currtr on currtr.c_currency_id = pay.c_currency_id
	LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID = pay.C_BPartner_ID)
	LEFT JOIN (
		SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
		FROM adempiere.ad_ref_list, adempiere.ad_reference
		WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
			AND ad_reference."name" = 'C_Payment Tender Type'
	) as rltt ON rltt.code = pay.tendertype
	LEFT JOIN (
		SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
		FROM adempiere.ad_ref_list, adempiere.ad_reference
		WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
			AND ad_reference."name" = 'C_Payment Trx Type'
	) as rltrxt ON (rltrxt.code = pay.trxtype)
	where pay.C_BankAccount_ID = $P{C_BankAccount_ID}
	AND pay.trxtype != 'X'
	AND pay.docstatus in ('CO', 'CL')
	AND bss.docstatus in ('CO', 'CL')	
	AND pay.DateAcct <= bss.DateAcct 
	AND ia.C_AcctSchema_ID = $P{C_AcctSchema_ID}
	AND pay.isallocated='N'
	AND bp.C_BPartner_ID in (
		select cb.c_bpartner_id 
		from c_bpartner cb 
		left join c_bp_customer_acct cbca on cb.c_bpartner_id = cbca.c_bpartner_id 
		where cbca.ad_client_id = $P{AD_Client_ID}
		and cbca.C_Prepayment_Acct  = (
		select cba.b_unidentified_acct from c_bankaccount_acct cba 
		where c_bankaccount_id= $P{C_BankAccount_ID}
		and cba.C_AcctSchema_ID = $P{C_AcctSchema_ID})
	)
	