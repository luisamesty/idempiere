--select distinct cba.b_unidentified_acct
--from c_bankaccount_acct cba 
--left join c_bankaccount cb on cb.c_bankaccount_id = cba.c_bankaccount_id 
--where cba.ad_client_id =1000000

select cba.b_unidentified_acct from c_bankaccount_acct cba 
where c_bankaccount_id= $P{C_BankAccount_ID}
and cba.C_AcctSchema_ID = $P{C_AcctSchema_ID}