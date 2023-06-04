	select invo1.documentno, invpay1.c_invoice_id, invpay1.amountpay, invpay1.c_payment_id, invpay1.c_currency_id as alloc_currency_id,
	invo1.dateacct as invodateacct, invo1.c_currency_id as invo_currency_id, invo1.c_conversiontype_id as invo_conversiontype_id, 
	paym1.dateacct as payodateacct, paym1.c_currency_id as paym_currency_id, paym1.c_conversiontype_id as paym_conversiontype_id,
	currencyConvert(invpay1.amountpay, invo1.c_currency_id,$P{C_Currency_ID},invo1.dateacct,invo1.C_ConversionType_ID,invo1.ad_client_id,invo1.ad_org_id) as invo_amount,
	currencyConvert(invpay1.amountpay, paym1.c_currency_id,$P{C_Currency_ID},invo1.dateacct,invo1.C_ConversionType_ID,paym1.ad_client_id,paym1.ad_org_id) as paym_amount,
	currencyRate (invo1.c_currency_id,$P{C_Currency_ID}, invo1.dateacct,invo1.C_ConversionType_ID,invo1.ad_client_id,invo1.ad_org_id)multiplyrate 
	from (
			select alloclin1.c_invoice_id, sum(alloclin1.amount) as amountpay, alloclin1.c_payment_id, allochdr1.c_currency_id
			FROM adempiere.c_allocationline as alloclin1
			left join adempiere.c_allocationhdr as allochdr1 on allochdr1.c_allocationhdr_id = alloclin1.c_allocationhdr_id 
			WHERE alloclin1.c_payment_id  > 0
			and allochdr1.dateacct between $P{DateIni}  AND  $P{DateEnd}
			GROUP BY alloclin1.c_invoice_id, alloclin1.c_payment_id , allochdr1.c_currency_id
	) as invpay1
	left join adempiere.c_invoice as invo1 on invo1.c_invoice_id = invpay1.c_invoice_id
	left join adempiere.c_payment as paym1 on paym1.c_payment_id = invpay1.c_payment_id

	
	where 1=1 AND CASE WHEN  $P{AD_User_ID} IS NULL OR invo1.salesrep_id = $P{AD_User_ID} THEN 1=1 ELSE 1=0 END 		
	AND paym1.datetrx BETWEEN  $P{DateIni}  AND  $P{DateEnd}		