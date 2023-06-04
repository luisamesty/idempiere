select 
pay.c_payment_id, pay.dateacct,
pay.payamt, pay.C_currency_id,
amf_paymentavailabletodate(pay.c_payment_id, pay.bss_dateacct) as payavailable
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
	left join c_payment pay1 on pay1.c_bpartner_id = bpa1.c_bpartner_id and pay1.c_bankaccount_id = $P{C_BankAccount_ID}
	LEFT JOIN (
		SELECT 
		c_bankstatement_id, c_bankaccount_id,
		c_currency_id as bss_currency_id, 
		C_ConversionType_ID as bss_conversiontype_id,
		docstatus, beginningbalance, endingbalance, dateacct as bss_dateacct
		FROM C_BankStatement bs WHERE bs.C_BankStatement_ID = $P{C_BankStatement_ID}
	) bss1 ON (bss1.C_BankAccount_ID = pay1.C_BankAccount_ID)
) as pay 
where amf_paymentavailabletodate(pay.c_payment_id, pay.bss_dateacct) <> 0