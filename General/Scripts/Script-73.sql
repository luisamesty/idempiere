	SELECT 
	all_l11.c_allocationhdr_id,  all_l11.c_allocationline_id , 
	all_l11.c_charge_id, cha0.name as Cha_name, cha0.description as Cha_description,
	all_l12.c_payment_id, all_l13.c_invoice_id
	FROM adempiere.c_allocationline all_l11 
	LEFT JOIN adempiere.c_charge  cha0  ON all_l11.c_charge_id = cha0.c_charge_id
	LEFT JOIN (
			SELECT all_l21.c_allocationhdr_id,  all_l21.c_allocationline_id , all_l21.c_payment_id
			FROM adempiere.c_allocationline all_l21 
			LEFT JOIN adempiere.c_payment  pay21  ON all_l21.c_payment_id = pay21.c_payment_id
			WHERE all_l21.c_payment_id IS NOT NULL AND all_l21.c_invoice_id IS NULL
	) AS all_l12 ON all_l12.c_allocationhdr_id= all_l11.c_allocationhdr_id
	LEFT JOIN (
			SELECT all_l31.c_allocationhdr_id,  all_l31.c_allocationline_id , all_l31.c_invoice_id
			FROM adempiere.c_allocationline all_l31 
			LEFT JOIN adempiere.c_invoice  inv31  ON all_l31.c_invoice_id = inv31.c_invoice_id
			WHERE all_l31.c_invoice_id IS NOT NULL AND all_l31.c_payment_id IS NULL
	) AS all_l13 ON all_l13.c_allocationhdr_id= all_l11.c_allocationhdr_id
	WHERE all_l11.c_charge_id IS NOT NULL 
	-- FOR TEST ONLY
	AND  all_l11.c_bpartner_id = 1010663 --1010663 -- 1008011 --