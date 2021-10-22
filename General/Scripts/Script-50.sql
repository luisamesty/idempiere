select cp.c_payment_id, cp.documentno , cp.c_bankaccount_id , cp.dateacct , cp.c_currency_id, cp.payamt ,
amf_paymentavailabletodate(cp.c_payment_id,'2021-01-31') as pay_balance
from c_payment cp 
where C_BPartner_ID=1009694 and  C_BankAccount_ID=1000014 and isallocated='N'
