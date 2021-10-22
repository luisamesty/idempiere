select cb.c_bpartner_id --, cb.value, cb.name, cb.isactive, cbca.C_Prepayment_Acct 
from c_bpartner cb 
left join c_bp_customer_acct cbca on cb.c_bpartner_id = cbca.c_bpartner_id 
where cbca.ad_client_id = $P{AD_Client_ID}
and cbca.C_Prepayment_Acct  = (
select cba.b_unidentified_acct from c_bankaccount_acct cba 
where c_bankaccount_id= $P{C_BankAccount_ID}
and cba.C_AcctSchema_ID = $P{C_AcctSchema_ID})