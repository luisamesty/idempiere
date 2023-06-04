SELECT 
	-- Client Info
	client.ad_client_id,
	client.client_name,
	client.client_logo,
	-- Currency 
    currency.bss_currency_id,
    currency.iso_code,
	currency.moneda,
	curr_req.iso_code_req,
	curr_req.moneda_req,
	-- Cuenta Bancaria y Banco
	ban.c_bank_id as c_bank_id,
	bax."name" as bank_name,
	bax.routingno,
	-- 20
	bax.description,
	ban.c_bankaccount_id as c_bankaccount_id,
	ban.isactive,
	CASE WHEN ban.bankaccounttype='B' THEN CONCAT (ban.bankaccounttype,'-','Caja')
		WHEN ban.bankaccounttype='C' THEN CONCAT (ban.bankaccounttype,'-','Ccorriente')
		WHEN ban.bankaccounttype='D' THEN CONCAT (ban.bankaccounttype,'-','Tarjeta')
		WHEN ban.bankaccounttype='S' THEN CONCAT (ban.bankaccounttype,'-','Ahorros')
		ELSE ban.bankaccounttype END
	AS bankaccounttype,
	ban.accountno,
	ban.currentbalance,
	ban.creditlimit,
	ban.value,
	ban.description,
	concil.ad_client_id,
	concil.ad_org_id,
	concil.c_currency_id,
	concil.C_ConversionType_ID,
	concil.tr_currency_id,
	concil.tr_C_ConversionType_ID,
	concil.tr_isocode,
	concil.currency_code,
	concil.C_Payment_ID,
	concil.docbasetype,
	concil.mayor_codigo,
	concil.mayor_name,
	concil.dnc,
	concil.dnc_source,
	concil.dnc_description,
	concil.aparca,
	concil.aparca_description,
	concil.Tender_Type,
	concil.Trx_Type,
	concil.Trx_Name,
	concil.documentno,
	concil.dateacct,
	concil.name,
	concil.name_src,
	concil.C_BankStatement_ID,
	concil.line,
	concil.amtsource,
	concil.amtacct,
	concil.currencyRate,
	concil.docstatus,
	bstm.beginningbalance as journal_balance_src,
	bstm.endingbalance as book_balance_src,
	CASE WHEN prevbstm.isoverridecurrencyrate='Y' THEN bstm.beginningbalance*prevbstm.bs1_currencyrate ELSE
	COALESCE(currencyConvert(bstm.beginningbalance, bstm.c_currency_id, $P{C_Currency_ID},prevbstm.DateAcct, prevbstm.C_ConversionType_ID,bstm.ad_client_id,bstm.ad_org_id),0) 
	END as journal_balance,
	CASE WHEN bstm.isoverridecurrencyrate='Y' THEN bstm.endingbalance*bstm.bs_currencyrate ELSE
	COALESCE(currencyConvert(bstm.endingbalance, bstm.c_currency_id,$P{C_Currency_ID},bstm.DateAcct,bstm.C_ConversionType_ID,bstm.ad_client_id,bstm.ad_org_id),0) 
	END as book_balance,
	bstm.dateacct AS bst_date,
	bstm.ct_value,
	bstm.ct_name,
	bstm.isoverridecurrencyrate,
	bstm.bs_currencyrate as journal_balance_rate,
	prevbstm.dateacct AS bst_date_prev,
	prevbstm.ct1_value AS ct_value_prev,
	prevbstm.ct1_name AS ct_name_prev,
	prevbstm.isoverridecurrencyrate AS isoverridecurrencyrate_prev,
	prevbstm.bs1_currencyrate as journal_balance_rate_prev
FROM (
	SELECT c_bank_id, c_bankaccount_id, bankaccounttype, accountno, currentbalance, creditlimit, value, description, isactive
	FROM C_BankAccount WHERE C_BankAccount_ID = $P{C_BankAccount_ID} 
) as ban
LEFT JOIN (
	SELECT * FROM (
		SELECT row_number() over (order by bs1.DateAcct DESC) as rn,
		bs1.Name,bs1.DateAcct, bs1.C_ConversionType_ID, bs1.beginningbalance, bs1.endingbalance,
		bs1.convertedamt, bs1.isoverridecurrencyrate, ct1.value AS ct1_value, ct1.name AS ct1_name,
		CASE WHEN bs1.isoverridecurrencyrate='Y' THEN bs1.currencyrate ELSE
		adempiere.currencyrate(bs1.c_currency_id, $P{C_Currency_ID},bs1.DateAcct, bs1.C_ConversionType_ID,bs1.ad_client_id,bs1.ad_org_id)
		END AS bs1_currencyrate
		FROM C_BankStatement bs1 
		LEFT JOIN C_ConversionType ct1 ON ct1.c_conversiontype_id = bs1.c_conversiontype_id 
		WHERE bs1.C_BankAccount_ID = $P{C_BankAccount_ID} 
		AND bs1.DateAcct < (SELECT DateAcct FROM C_BankStatement WHERE C_BankStatement_ID = $P{C_BankStatement_ID} )
	) as prev 
	WHERE prev.rn=1
) as prevbstm ON 1 = 1
LEFT JOIN (
		SELECT 
		bs.c_bankstatement_id, bs.c_bankaccount_id, bs.ad_client_id, bs.ad_org_id, bs.c_currency_id, bs.C_ConversionType_ID,
		bs.docstatus, bs.beginningbalance, bs.endingbalance, bs.convertedamt,
		bs.dateacct , bs.isoverridecurrencyrate, ct.value AS ct_value, ct.name AS ct_name,
		CASE WHEN bs.isoverridecurrencyrate='Y' THEN bs.currencyrate ELSE
		adempiere.currencyrate(bs.c_currency_id, $P{C_Currency_ID},bs.DateAcct, bs.C_ConversionType_ID,bs.ad_client_id,bs.ad_org_id)
		END AS bs_currencyrate
		FROM C_BankStatement bs 
		LEFT JOIN C_ConversionType ct ON ct.c_conversiontype_id = bs.c_conversiontype_id 
		WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID} 
) AS bstm  ON bstm.c_bankaccount_id = ban.c_bankaccount_id
LEFT JOIN C_Bank bax ON (bax.c_bank_id= ban.c_bank_id)	
LEFT JOIN
(
	--1
	-- Documentos NO Conciliados Según Libros
	-- dnc:DRESL
	-- aparca: AAAAA
	-- 
	SELECT
	bss.ad_client_id,
	bss.ad_org_id,
	bss.c_currency_id,
	bss.C_ConversionType_ID,
	bss.c_currency_id as tr_currency_id,
	bss.C_ConversionType_ID as tr_C_ConversionType_ID,
	currtr.iso_code as tr_isocode,
	currtr.iso_code as currency_code, 
	0 AS C_Payment_ID,
	'AAA' as docbasetype,
	cev.value as mayor_codigo,
	cev.name as mayor_name,
	--  10 
	'DRESL' as dnc,
	'P' as dnc_source,
	'Documentos No Conciliados Según Libros' as dnc_description,
	'AAAAA' as aparca,
	'Depósitos de Caja /Retiros Pendientes' as aparca_description,
	'' as Tender_Type, 
	'' as Trx_Type, 
	''  as Trx_Name, 
	'' as documentno, 
	bss.DateAcct as dateacct, 
	-- 20
	'' as name, 	
	'' as name_src,	
	bss.c_bankstatement_id as C_BankStatement_ID, 
	0 as line,  
	0 as amtsource, 
	0 as amtacct,
	0 as currencyRate,
	'CO' as docstatus,
	COALESCE(bss.beginningbalance,0) as journal_balance,
	COALESCE(bss.endingbalance,0) as  book_balance,
	bss.DateAcct as bst_date
	FROM (
		SELECT 
		bs.c_bankstatement_id, bs.c_bankaccount_id, bs.ad_client_id, bs.ad_org_id, bs.c_currency_id, bs.C_ConversionType_ID,
		bs.docstatus, bs.beginningbalance, bs.endingbalance, 
		bs.dateacct , bs.isoverridecurrencyrate, ct.value, ct.name 
		FROM C_BankStatement bs 
		LEFT JOIN C_ConversionType ct ON ct.c_conversiontype_id = bs.c_conversiontype_id 
		WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID} 
	) bss
	LEFT JOIN (
		SELECT vc.Account_ID, cev.value, cev.name 
		FROM C_ValidCombination vc
		LEFT JOIN C_BankAccount_Acct bac ON vc.C_ValidCombination_ID=bac.B_InTransit_Acct
		LEFT JOIN C_ElementValue cev ON cev.C_ElementValue_ID = vc.Account_ID
		WHERE bac.C_BankAccount_ID = $P{C_BankAccount_ID} AND bac.c_acctschema_id = $P{C_AcctSchema_ID}
	) cev ON 1=1
	LEFT JOIN c_currency currtr on currtr.c_currency_id = bss.c_currency_id
	LEFT JOIN (
		SELECT	c_currency_id as req_currency_id, iso_code as req_iso_code FROM c_currency WHERE c_currency_id= $P{C_Currency_ID}
	) currtr2 ON 1=1
	UNION

--  2
--	RECONCILED 
-- 	Documentos Conciliados Según Libros
--  dnc: DRESL
--  aparca: AROUT / APOUT
--
	SELECT  
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
	cev.value as mayor_codigo,
	cev.name as mayor_name,
	-- 10
	'DRESL' as dnc,
    'P' as dnc_source,
	'Documentos Conciliados Según Libros' as dnc_description,
	CASE WHEN pay.isreceipt = 'Y' THEN 'AROUT'
		WHEN pay.isreceipt = 'N' THEN 'APOUT' 
	END as aparca,
	CASE WHEN pay.isreceipt = 'Y' THEN 'Depósitos y NC Conciliados'
	     WHEN pay.isreceipt = 'N' THEN 'Cheques y ND Conciliados' 
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
	bp."name" as name, 	
	CASE WHEN bss.c_currency_id <> currtr.c_currency_id THEN CONCAT(currtr.iso_code,'-',currtr.cursymbol,'-',currtr.description)  ELSE '' END as name_src,	
	bss.C_BankStatement_ID, 
	bsl.line as line, 
	pay.payamt as amtsource, 
	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt,pay.dateacct) as amtacct,
	CASE WHEN pay.isoverridecurrencyrate ='Y' THEN pay.currencyrate ELSE
	adempiere.currencyrate(pay.c_currency_id, $P{C_Currency_ID},pay.DateAcct, pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id)
	END as currencyRate,
	bss.docstatus,
	COALESCE(bss.beginningbalance,0) as journal_balance,
	COALESCE(bss.endingbalance,0) as  book_balance,
	bss.dateacct as bst_date
	FROM (
		SELECT 
		c_bankstatement_id, c_bankaccount_id, ad_client_id, ad_org_id, c_currency_id, C_ConversionType_ID,
		docstatus, beginningbalance, endingbalance, dateacct 
		FROM C_BankStatement bs WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID} 
	) bss
	LEFT JOIN C_BankStatementLine bsl ON (bsl.C_BankStatement_ID = bss.C_BankStatement_ID )
	LEFT JOIN C_Payment pay ON (pay.C_Payment_ID = bsl.C_Payment_ID)
    LEFT JOIN c_doctype as dct ON (dct.c_doctype_id = pay.c_doctype_id)
	LEFT JOIN (
		SELECT vc.Account_ID, cev.value, cev.name 
		FROM C_ValidCombination vc
		LEFT JOIN C_BankAccount_Acct bac ON vc.C_ValidCombination_ID=bac.B_Asset_Acct
		LEFT JOIN C_ElementValue cev ON cev.C_ElementValue_ID = vc.Account_ID
		WHERE bac.C_BankAccount_ID = $P{C_BankAccount_ID} AND bac.c_acctschema_id = $P{C_AcctSchema_ID}
	) cev ON 1=1
	LEFT JOIN c_currency currtr on currtr.c_currency_id = pay.c_currency_id
	LEFT JOIN C_BPartner bp ON (bp.C_BPartner_ID = pay.C_BPartner_ID)
	LEFT JOIN (SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
			FROM adempiere.ad_ref_list, adempiere.ad_reference
			WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
				AND ad_reference."name" = 'C_Payment Tender Type') rltt ON rltt.code = pay.tendertype
	LEFT JOIN (SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
			FROM adempiere.ad_ref_list, adempiere.ad_reference
			WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
				AND ad_reference."name" = 'C_Payment Trx Type') rltrxt ON (rltrxt.code = pay.trxtype)
	WHERE
	pay.C_BankAccount_ID = $P{C_BankAccount_ID}
	AND pay.trxtype != 'X'
	AND pay.docstatus in ('CO', 'CL')
	AND bss.docstatus in ('CO', 'CL')	
--	
		UNION
--
-- 3
-- UNRECONCILEDD PAYMENT 111104 (FIRST BLANK LINE ONLY FOR HEADER PURPOSE)
-- Documentos No Conciliados Segun Libros
-- dnc: DNCSL
-- aparca: APOUT
--
	SELECT  
	bss.ad_client_id,
	bss.ad_org_id,
	bss.c_currency_id,
	bss.C_ConversionType_ID,
	bss.c_currency_id as tr_currency_id,
	bss.C_ConversionType_ID as tr_C_ConversionType_ID,
	currtr.iso_code as tr_isocode,
	currtr.iso_code as currency_code, 
	0 AS C_Payment_ID,
	'AAA' as docbasetype,
	cev.value as mayor_codigo,
	cev.name as mayor_name,
	-- 10
	'DNCSL' as dnc,
    'P' as dnc_source,
	'Documentos No Conciliados Segun Libros' as dnc_description,
	'APOUT' as aparca,
	'' as aparca_description,
	'' as Tender_Type, 
	'' as Trx_Type, 
	''  as Trx_Name, 
	'' as documentno, 
	bss.DateAcct as dateacct, 
	--20
	'' as name, 	
	'' as name_src,	
	0 as C_BankStatement_ID, 
	0 as line,  
	0 as amtsource, 
	0 as amtacct,
	0 as currencyRate,
	'CO' as docstatus,
	COALESCE(bss.beginningbalance,0) as journal_balance,
	COALESCE(bss.endingbalance,0) as  book_balance,
	bss.dateacct as bst_date
	FROM (
		SELECT 
		c_bankstatement_id, c_bankaccount_id, ad_client_id, ad_org_id, c_currency_id, C_ConversionType_ID,
		docstatus, beginningbalance, endingbalance, dateacct 
		FROM C_BankStatement bs WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID} 
	) bss
	LEFT JOIN (
		SELECT vc.Account_ID, cev.value, cev.name 
		FROM C_ValidCombination vc
		LEFT JOIN C_BankAccount_Acct bac ON vc.C_ValidCombination_ID=bac.B_InTransit_Acct
		LEFT JOIN C_ElementValue cev ON cev.C_ElementValue_ID = vc.Account_ID
		WHERE bac.C_BankAccount_ID = $P{C_BankAccount_ID} AND bac.c_acctschema_id = $P{C_AcctSchema_ID}
	) cev ON 1=1
	LEFT JOIN c_currency currtr on currtr.c_currency_id = bss.c_currency_id
--	
		UNION
--
-- 4
-- UNRECONCILEDD PAYMENT 111104 (LINES)
-- Documentos NO Conciliados Segun Libros
-- dnc: DNCSL
-- aparca: AROUT/APOUT
--
	SELECT  
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
	cev.value as mayor_codigo,
	cev.name as mayor_name,
	--  10  
	'DNCSL' as dnc,
    'P' as dnc_source,
	'Documentos No Conciliados Segun Libros' as dnc_description,
	CASE WHEN pay.isreceipt = 'Y' THEN 'AROUT'
		WHEN pay.isreceipt = 'N' THEN 'APOUT' 
	END as aparca,
	CASE WHEN pay.isreceipt = 'Y' THEN 'Depósitos y NC en Tránsito'
	     WHEN pay.isreceipt = 'N' THEN 'Cheques y ND en Tránsito' 
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
	bp."name" as name, 	
	CASE WHEN bss.c_currency_id <> currtr.c_currency_id THEN CONCAT(currtr.iso_code,'-',currtr.cursymbol,'-',currtr.description)  ELSE '' END as name_src,	
	bss.C_BankStatement_ID, 
	bsl.line as line,  
	pay.payamt as amtsource, 
	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt,pay.dateacct) as amtacct,
	CASE WHEN pay.isoverridecurrencyrate ='Y' THEN pay.currencyrate ELSE
	adempiere.currencyrate(pay.c_currency_id, $P{C_Currency_ID},pay.DateAcct, pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id)
	END as currencyRate,
	bss.docstatus,
	COALESCE(bss.beginningbalance,0) as journal_balance,
	COALESCE(bss.endingbalance,0) as  book_balance,
	bss.dateacct as bst_date
	FROM (
		SELECT * FROM C_Payment_v WHERE C_BankAccount_ID = $P{C_BankAccount_ID}
	) pay
	INNER JOIN c_doctype as dct ON (dct.c_doctype_id = pay.c_doctype_id)
	LEFT JOIN (
		SELECT 
		c_bankstatement_id, c_bankaccount_id, ad_client_id, ad_org_id, c_currency_id, C_ConversionType_ID,
		docstatus, beginningbalance, endingbalance, dateacct 
		FROM C_BankStatement bs WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID} 
	) bss ON (bss.C_BankAccount_ID = pay.C_BankAccount_ID)
	LEFT JOIN C_BankStatementLine bsl ON (pay.C_Payment_ID = bsl.C_Payment_ID)
	LEFT JOIN (
		SELECT vc.Account_ID, cev.value, cev.name 
		FROM C_ValidCombination vc
		LEFT JOIN C_BankAccount_Acct bac ON vc.C_ValidCombination_ID=bac.B_InTransit_Acct
		LEFT JOIN C_ElementValue cev ON cev.C_ElementValue_ID = vc.Account_ID
		WHERE bac.C_BankAccount_ID = $P{C_BankAccount_ID} AND bac.c_acctschema_id = $P{C_AcctSchema_ID}
	) cev ON 1=1
	LEFT OUTER JOIN C_BPartner bp ON (pay.C_BPartner_ID=bp.C_BPartner_ID) 
	LEFT JOIN c_currency currtr on currtr.c_currency_id = pay.c_currency_id
	LEFT JOIN (
		SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
		FROM adempiere.ad_ref_list, adempiere.ad_reference
		WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
		AND ad_reference."name" = 'C_Payment Tender Type'
	) rltt ON rltt.code = pay.tendertype
 	LEFT JOIN (
 		SELECT ad_ref_list."name" as list_value, ad_ref_list."value" as code
		FROM adempiere.ad_ref_list, adempiere.ad_reference
		WHERE ad_ref_list.ad_reference_id = ad_reference.ad_reference_id
		AND ad_reference."name" = 'C_Payment Trx Type'
	) rltrxt ON (rltrxt.code = pay.trxtype)
	WHERE pay.C_BankAccount_ID=$P{C_BankAccount_ID} AND pay.Processed='Y' AND pay.IsReconciled='N'
	AND pay.DocStatus IN ('CO','CL','RE','VO') AND pay.PayAmt<>0
	AND pay.C_BankAccount_ID = $P{C_BankAccount_ID}
	AND NOT EXISTS (SELECT * FROM C_BankStatementLine l WHERE pay.C_Payment_ID=l.C_Payment_ID AND l.StmtAmt <> 0)
	AND pay.DateTrx <= bss.DateAcct	
--		
	UNION
--
-- 5
-- UNALLOCATED PAYMENT 113438 (B_UNIDENTIFIED_ACCT)
-- Documentos No Conciliados Según Bancos
-- DNCSB
-- aparca: UROUT / UPOUT
--
	SELECT  DISTINCT ON (pay.C_payment_ID)
	pay.ad_client_id,
	pay.ad_org_id,
	pay.c_currency_id,
	pay.C_ConversionType_ID,
	pay.c_currency_id as tr_currency_id,
	pay.C_ConversionType_ID as tr_C_ConversionType_ID,
	currtr.iso_code as tr_isocode,
	currtr.iso_code as currency_code, 
	pay.C_Payment_ID AS C_Payment_ID,
	dct.docbasetype as docbasetype,
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
	CASE WHEN pay.c_currency_id <> currtr.c_currency_id THEN CONCAT(currtr.iso_code,'-',currtr.cursymbol,'-',currtr.description)  ELSE '' END as name_src,	
	pay.C_BankStatement_ID, 
	0 as line, 
	pay.payamt as amtsource, 
	currencyConvertpayment(pay.c_payment_id, $P{C_Currency_ID}, pay.payamt,pay.dateacct) as amtacct,
	CASE WHEN pay.isoverridecurrencyrate ='Y' THEN pay.currencyrate ELSE
	adempiere.currencyrate(pay.c_currency_id, $P{C_Currency_ID},pay.DateAcct, pay.C_ConversionType_ID,pay.ad_client_id,pay.ad_org_id)
	END as currencyRate,
	pay.docstatus,
	COALESCE(pay.beginningbalance,0) as journal_balance,
	COALESCE(pay.endingbalance,0) as  book_balance,
	pay.bss_dateacct as bst_date
	from (
		select *
		from  (
				select cb.c_bpartner_id 
				from c_bpartner cb 
				left join c_bp_customer_acct cbca on cb.c_bpartner_id = cbca.c_bpartner_id 
				where cbca.ad_client_id = $P{AD_Client_ID}
				and cbca.C_Prepayment_Acct  = (
				select cba.b_unidentified_acct from c_bankaccount_acct cba 
				where c_bankaccount_id= $P{C_BankAccount_ID}
				and cba.C_AcctSchema_ID = $P{C_AcctSchema_ID})
		) bpa1 
		left join (
			select 
			ad_client_id, ad_org_id, c_payment_id, c_bpartner_id as pay_bpartner_id, c_bankaccount_id, 
			payamt , dateacct, c_currency_id, isallocated,
			C_ConversionType_ID, isreceipt, documentno, description, c_doctype_id, C_Charge_ID, tendertype,
			trxtype, docstatus, isoverridecurrencyrate , currencyrate 
			from c_payment where c_bankaccount_id = $P{C_BankAccount_ID}
		) as pay1 on pay1.pay_bpartner_id = bpa1.c_bpartner_id
		LEFT JOIN (
			SELECT 
			c_bankstatement_id, c_bankaccount_id as bss_bankaccount_id,
			c_currency_id as bss_currency_id, 
			C_ConversionType_ID as bss_conversiontype_id,
			docstatus as bss_docstatus, beginningbalance, endingbalance, dateacct as bss_dateacct
			FROM C_BankStatement bs1 WHERE bs1.C_BankStatement_ID = $P{C_BankStatement_ID}
		) bss1 ON (bss1.bss_bankaccount_id = pay1.C_BankAccount_ID)
	) as pay 
	LEFT JOIN C_BankAccount ban ON (pay.C_BankAccount_ID = ban.C_BankAccount_ID)
	LEFT JOIN C_Bank bax ON (bax.c_bank_id= ban.c_bank_id)	
    LEFT JOIN c_doctype as dct ON (dct.c_doctype_id = pay.c_doctype_id)
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
	where amf_paymentavailabletodate(pay.c_payment_id, pay.bss_dateacct) <> 0
	and pay.C_BankAccount_ID = $P{C_BankAccount_ID}
	AND pay.trxtype != 'X'
	AND pay.docstatus in ('CO', 'CL')
	AND pay.bss_docstatus in ('CO', 'CL')	
	AND pay.DateAcct <= pay.bss_dateacct 
	AND ia.C_AcctSchema_ID = $P{C_AcctSchema_ID}
) as concil ON  1=1
LEFT JOIN (
	SELECT DISTINCT
	cli.ad_client_id,
	COALESCE(cli.name,cli.value) as client_name,
	img1.binarydata as client_logo
	FROM adempiere.ad_client cli
	LEFT JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
	LEFT JOIN adempiere.ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
	WHERE cli.ad_client_id = $P{AD_Client_ID}
) as client ON client.ad_client_id = concil.ad_client_id
LEFT JOIN (
	SELECT DISTINCT
    curr1.c_currency_id as bss_currency_id,
    curr1.iso_code,
	CONCAT(curr1.iso_code,'-',currt1.cursymbol,'-',COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'')) as moneda
	FROM c_currency curr1 
	LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE curr1.isActive='Y'
) currency ON currency.bss_currency_id= concil.c_currency_id
LEFT JOIN (
	SELECT 
	curr2.iso_code as iso_code_req,
	CONCAT(curr2.iso_code,'-',currt2.cursymbol,'-',COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'')) as moneda_req
	FROM c_currency curr2 
	LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE curr2.c_currency_id= $P{C_Currency_ID}
) as curr_req ON 1=1
ORDER BY ban.c_bankaccount_id, concil.dnc DESC, concil.aparca, concil.dateacct