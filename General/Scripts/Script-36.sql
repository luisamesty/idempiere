select invo1.documentno, invo1.dateacct, invpay1.c_invoice_id, invpay1.amountpay, invpay1.c_payment_id, invpay1.c_currency_id as alloc_currency_id
from (
		select alloclin1.c_invoice_id, sum(alloclin1.amount) as amountpay, alloclin1.c_payment_id , allochdr1.c_currency_id 
		FROM adempiere.c_allocationline as alloclin1
		left join adempiere.c_allocationhdr as allochdr1 on allochdr1.c_allocationhdr_id = alloclin1.c_allocationhdr_id 
		WHERE alloclin1.c_payment_id  > 0
		and allochdr1.dateacct between $P{DateIni}  AND  $P{DateEnd}
		GROUP BY alloclin1.c_invoice_id, alloclin1.c_payment_id , allochdr1.c_currency_id
	) as invpay1
left join adempiere.c_invoice as invo1 on invo1.c_invoice_id = invpay1.c_invoice_id
where 1=1 AND CASE WHEN  $P{AD_User_ID} IS NULL OR invo1.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END 