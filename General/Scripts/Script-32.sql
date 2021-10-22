select
	paydet.ad_client_id,
	paydet.ad_org_id,
	paydet.workforce,
	paydet.c_period_id,
	paydet.amn_employee_id,
	paydet.value_emp,
	paydet.empleado,
	coalesce(sum(paydet.amountallocated) - sum(paydet.amountdeducted), 0) as payamt,
	coalesce(paydone.paydone, 0) as paydone,
	coalesce(sum(paydet.amountallocated) - sum(paydet.amountdeducted) - paydone.paydone, 0) as paydiff,
	paydet.c_currency_id
from
	(
	select
		pyr.ad_client_id,
		pyr.ad_org_id,
		c_prd.c_period_id,
		emp.amn_employee_id,
		emp.value as value_emp,
		emp.name as empleado,
		coalesce(jtt.workforce, jtt.workforce, 'A') as workforce,
		pyr_d.value as detail_value,
		qtyvalue as cantidad,
		pyr_d.amountallocated,
		pyr_d.amountdeducted,
		pyr_d.amountcalculated,
		pyr.c_currency_id
	from
		amn_payroll as pyr
	left join amn_payroll_detail as pyr_d on
		(pyr_d.amn_payroll_id = pyr.amn_payroll_id)
	left join amn_concept_types_proc as ctp on
		(ctp.amn_concept_types_proc_id = pyr_d.amn_concept_types_proc_id)
	left join amn_concept_types as cty on
		((cty.amn_concept_types_id = ctp.amn_concept_types_id))
	left join amn_process as prc on
		(prc.amn_process_id = ctp.amn_process_id)
	inner join amn_employee as emp on
		(emp.amn_employee_id = pyr.amn_employee_id)
	left join amn_jobtitle as jtt on
		(pyr.amn_jobtitle_id = jtt.amn_jobtitle_id)
	left join amn_jobtitle as jtt2 on
		(emp.amn_jobtitle_id = jtt2.amn_jobtitle_id)
	left join amn_period as prd on
		(prd.amn_period_id = pyr.amn_period_id)
	left join c_period as c_prd on
		(c_prd.c_period_id = prd.c_period_id)
	where
		prc.value = 'NN'
		and cty.optmode <> 'R'
		and cty.prestacion = 'Y'
		and pyr.AD_Client_ID = 1000004
		and pyr.AD_Org_ID = 1000004
		and c_prd.C_Period_ID = 1000170 ) as paydet
left join (
	select
		amn_employee_id,
		coalesce(sum(amountallocated) - sum(amountdeducted), 0) as paydone
	from
		(
		select
			pyr.ad_client_id,
			pyr.ad_org_id ,
			c_prd.c_period_id,
			c_prd.startdate,
			c_prd.enddate,
			emp.amn_employee_id,
			emp.value as value_emp,
			emp.name as empleado,
			jtt.workforce,
			pyr_d.value as detail_value,
			qtyvalue as cantidad,
			pyr_d.amountallocated,
			pyr_d.amountdeducted,
			pyr_d.amountcalculated
		from
			amn_payroll as pyr
		left join amn_payroll_detail as pyr_d on
			(pyr_d.amn_payroll_id = pyr.amn_payroll_id)
		left join amn_concept_types_proc as ctp on
			(ctp.amn_concept_types_proc_id = pyr_d.amn_concept_types_proc_id)
		left join amn_concept_types as cty on
			((cty.amn_concept_types_id = ctp.amn_concept_types_id))
		left join amn_process as prc on
			(prc.amn_process_id = ctp.amn_process_id)
		inner join amn_employee as emp on
			(emp.amn_employee_id = pyr.amn_employee_id)
		left join amn_jobtitle as jtt on
			(pyr.amn_jobtitle_id = jtt.amn_jobtitle_id)
		left join amn_period as prd on
			(prd.amn_period_id = pyr.amn_period_id)
		left join c_period as c_prd on
			(c_prd.c_period_id = prd.c_period_id)
		where
			prc.value = 'NP'
			and cty.optmode != 'R'
			and pyr.AD_Client_ID = 1000004
			and pyr.AD_Org_ID = 1000004
			and c_prd.C_Period_ID = 1000170 ) as paydet
	group by
		amn_employee_id ) as paydone on
	(paydone.amn_employee_id = paydet.amn_employee_id )
group by
	ad_client_id,
	ad_org_id,
	workforce,
	c_period_id,
	paydet.amn_employee_id,
	value_emp,
	empleado,
	paydone.paydone,
	paydet.c_currency_id
order by
	paydet.workforce,
	paydet.value_emp
