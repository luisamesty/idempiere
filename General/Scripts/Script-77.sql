SELECT pay.c_payment_id, pay.payamt , pay.isoverridecurrencyrate AS IS , pay.currencyrate ,  
pay.c_currency_id_to,
pay.currencyrate * pay.payamt correct,
currencyconvertpayment(pay.c_payment_id,1000000,NULL,pay.dateacct) AS VES,
currencyconvertpayment(pay.c_payment_id,1000001,NULL,pay.dateacct) AS VED
FrOM C_Payment pay
WHERE pay.c_payment_ID = 1101219