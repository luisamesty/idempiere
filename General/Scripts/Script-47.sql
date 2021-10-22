SELECT 
    -- ORGANIZACIÓN
    coalesce(org.name,org.value,'') as org_name,
    COALESCE(org.description,org.name,org.value,'') as org_description,
    COALESCE(orginfo.taxid,'') as org_taxid,
    pyr.ad_client_id as ad_client_id, pyr.ad_org_id as ad_org_id,
    CASE WHEN $P{AD_Org_ID} = 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
    -- EMPLOYEE
    emp.amn_employee_id, emp.value as value_emp, emp.name as nombre_emp, 
    -- JOB Title
    j.value as cargo, j.name as cargo_name, j.description as cargo_description,
    -- BPARTNER
    --cbp.taxid as nro_id,
    -- BUSINESS PARTNER
	COALESCE(cbp.taxid, cbp.amerp_rifseniat) as rif,
    -- LOCATION
    lct.amn_location_id, lct.value as loc_value, COALESCE(lct.name, lct.description) as localidad,
    -- CONTRACT
    amc.amn_contract_id, amc.netdays as c_netdays,amc.value as c_value, COALESCE(amc.name, amc.description) as c_tipo, 
    -- AMN PERIOD tipe (NN NU)
    tiper.amn_period_id as ti_period_id, tiper.refdateini, tiper.refdateend,
    -- C_PERIOD
    per.c_period_id as c_period_id, per.startdate as startdate, per.enddate as enddate,
	-- CURRENCY
    curr1.iso_code as iso_code1,
    currt1.cursymbol as cursymbol1,
    COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
    curr2.iso_code as iso_code2,
    currt2.cursymbol as cursymbol2,
    COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2, 
    -- AMN_PAYROLL
    pyr.amn_payroll_id, pyr.name as nombre, pyr.invdateini as fecha_inicio, pyr.invdateend as fecha_fin,    
    -- AMN PROCESS
    pro.amn_process_id, pro.value as proceso,
    -- AMN_PAYROLL_DETAIL
    coalesce(pydma.ALL_INCE_AMT,0) as ALL_INCE_AMT,
    coalesce(pydma.DED_INCE_AMT,0) as DED_INCE_AMT,
    coalesce(pydma.NET_INCE_AMT,0) as NET_INCE_AMT,
    coalesce(pydma.PAT_INCE_AMT,0) as PAT_INCE_AMT,
       -- C_YEAR 
    year2.c_year_id,  year2.periodos
    FROM AMN_Period tiper
    LEFT JOIN C_Period per ON (per.c_period_id = tiper.c_period_id AND tiper.amn_process_id IN (Select AMN_process_ID FROM AMN_Process pro WHERE pro.Value = 'NN' OR pro.Value = 'NO' OR pro.Value = 'NU'))
    LEFT JOIN adempiere.amn_payroll as pyr ON (pyr.amn_period_id = tiper.amn_period_id)
    LEFT JOIN C_Year year ON (year.C_Year_ID = per.C_Year_ID )
    LEFT JOIN (
		SELECT DISTINCT ON (per2.C_Year_ID) 
		per2.C_Year_ID,
		CONCAT(MAX(per2.periodtxt01)::text, '  ', MAX(per2.periodtxt02)::text, '  ', MAX(per2.periodtxt03)::text, '  ', MAX(per2.periodtxt04)::text,
		       '  ', MAX(per2.periodtxt05)::text, '  ', MAX(per2.periodtxt06)::text, '  ', MAX(per2.periodtxt07)::text, '  ', MAX(per2.periodtxt08)::text,
		       '  ', MAX(per2.periodtxt09)::text, '  ', MAX(per2.periodtxt10)::text, '  ', MAX(per2.periodtxt11)::text, '  ', MAX(per2.periodtxt12)::text
			) as periodos 
		FROM
		 	(
			SELECT
			cper.C_Year_ID,
			cper.C_Period_ID , 
			--cper.PeriodNo, 
			CASE WHEN cper.PeriodNo=1 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt01,
			CASE WHEN cper.PeriodNo=2 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt02,
			CASE WHEN cper.PeriodNo=3 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt03,
			CASE WHEN cper.PeriodNo=4 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt04,
			CASE WHEN cper.PeriodNo=5 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt05,
			CASE WHEN cper.PeriodNo=6 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt06,
			CASE WHEN cper.PeriodNo=7 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt07,
			CASE WHEN cper.PeriodNo=8 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt08,
			CASE WHEN cper.PeriodNo=9 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt09,
			CASE WHEN cper.PeriodNo=10 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt10,
			CASE WHEN cper.PeriodNo=11 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt11,
			CASE WHEN cper.PeriodNo=12 THEN to_char(cper.startdate,'MM-YYYY') ELSE '' END as periodtxt12
			FROM C_Period cper 
			WHERE cper.c_period_id >=  $P{C_PeriodIni_ID} AND cper.c_period_id <= $P{C_PeriodEnd_ID} AND cper.c_year_id = $P{C_Year_ID}
			) as per2
		GROUP BY per2.C_Year_ID
    ) year2 ON ( year2.c_year_id = year.c_year_id)
    LEFT JOIN (
        SELECT 
        pyda.amn_payroll_id, 
        SUM( pyda.NET_INCE_AMT) as NET_INCE_AMT,  
        SUM( pyda.ALL_INCE_AMT) as ALL_INCE_AMT, 
        SUM( pyda.DED_INCE_AMT) as DED_INCE_AMT,
        SUM( pyda.PAT_INCE_AMT) as PAT_INCE_AMT
        FROM
			(
				SELECT DISTINCT
				prdet.amn_payroll_id, 
				ctys.amn_concept_types_id as amn_concept_types_id, 
				ctys.ince as Ince,
				CASE WHEN ctys.ince ='Y' 
					THEN currencyConvert(prdet.amountallocated,pyr2.c_currency_id, $P{C_Currency_ID}, pyr2.dateacct, pyr2.C_ConversionType_ID, pyr2.AD_Client_ID, pyr2.AD_Org_ID )
					ELSE 0 END as ALL_INCE_AMT,
				CASE WHEN ctys.ince ='Y' 
					THEN currencyConvert(prdet.amountdeducted,pyr2.c_currency_id, $P{C_Currency_ID}, pyr2.dateacct, pyr2.C_ConversionType_ID, pyr2.AD_Client_ID, pyr2.AD_Org_ID )
					ELSE 0 END as DED_INCE_AMT,
				CASE WHEN ctys.ince ='Y' 
					THEN  currencyConvert((prdet.amountallocated-prdet.amountdeducted),pyr2.c_currency_id, $P{C_Currency_ID}, pyr2.dateacct, pyr2.C_ConversionType_ID, pyr2.AD_Client_ID, pyr2.AD_Org_ID )
					ELSE 0 END as NET_INCE_AMT,
				CASE WHEN ctys.ince ='Y' and prdet.amountallocated = 0 and prdet.amountdeducted = 0 and prdet.amountcalculated <> 0
					THEN  currencyConvert((prdet.amountcalculated),pyr2.c_currency_id, $P{C_Currency_ID}, pyr2.dateacct, pyr2.C_ConversionType_ID, pyr2.AD_Client_ID, pyr2.AD_Org_ID )
					ELSE 0 END as PAT_INCE_AMT					
				FROM AMN_Payroll_Detail prdet
				LEFT JOIN AMN_Concept_Types_Proc ctyp ON (ctyp.AMN_Concept_Types_Proc_ID = prdet.AMN_Concept_Types_Proc_ID)
				LEFT JOIN AMN_Concept_Types ctys ON ( ctys.AMN_Concept_Types_ID = ctyp.AMN_Concept_Types_ID) 
				LEFT JOIN AMN_Payroll pyr2 ON (pyr2.AMN_Payroll_ID = prdet.AMN_Payroll_ID)
			) as pyda
		Where pyda.Ince='Y'
		GROUP BY  pyda.amn_payroll_id  
		) as pydma ON ( pydma.amn_payroll_id = pyr.amn_payroll_id)
    LEFT JOIN amn_process as pro ON (pyr.amn_process_id= pro.amn_process_id) 
    LEFT JOIN amn_contract as amc ON (pyr.amn_contract_id = amc.amn_contract_id)
    LEFT JOIN amn_employee as emp ON (pyr.amn_employee_id = emp.amn_employee_id)
    LEFT JOIN AMN_Department d ON (d.AMN_Department_ID=emp.AMN_Department_ID)
	LEFT JOIN AMN_Jobtitle j ON(j.AMN_Jobtitle_ID = emp.AMN_Jobtitle_ID)
	LEFT JOIN AMN_Shift s ON(s.AMN_Shift_ID = emp.AMN_Shift_ID)       
    LEFT JOIN adempiere.c_bpartner as cbp ON (emp.c_bpartner_id = cbp.c_bpartner_id)
    LEFT JOIN adempiere.amn_location as lct ON (emp.amn_location_id= lct.amn_location_id)
    LEFT JOIN adempiere.ad_org as org ON (org.ad_org_id = pyr.ad_org_id)
    INNER JOIN adempiere.ad_client as cli ON (org.ad_client_id = cli.ad_client_id)
    INNER JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
    LEFT JOIN ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
    INNER JOIN adempiere.ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
	LEFT JOIN ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
	LEFT JOIN c_currency curr1 on pyr.c_currency_id = curr1.c_currency_id
    LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID}) 
    LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
    LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE per.c_period_id >=  $P{C_PeriodIni_ID}  AND per.c_period_id <=  $P{C_PeriodEnd_ID} AND per.c_year_id = $P{C_Year_ID}
		AND CASE WHEN ( $P{AMN_Contract_ID}  IS NULL OR amc.amn_contract_id= $P{AMN_Contract_ID} ) THEN 1=1 ELSE 1=0 END
		AND CASE WHEN ( $P{AMN_Employee_ID}  IS NULL OR emp.amn_employee_id= $P{AMN_Employee_ID} ) THEN 1=1 ELSE 1=0 END
GROUP BY org.name, org.value, org.description, orginfo.taxid, 
	pyr.ad_client_id, pyr.ad_org_id, emp.amn_employee_id, 
	lct.amn_location_id, amc.amn_contract_id, tiper.amn_period_id, pyr.amn_payroll_id, per.c_period_id, 
	pro.amn_process_id, pydma.ALL_INCE_AMT, pydma.DED_INCE_AMT , pydma.NET_INCE_AMT, pydma.PAT_INCE_AMT, year2.c_year_id,  year2.periodos,
	j.value, j.name,j.description,cbp.taxid,cbp.amerp_rifseniat,
	img1.binarydata, img2.binarydata,
	curr1.iso_code, curr1.cursymbol, currt1.cursymbol, currt1.description, curr2.iso_code, curr2.cursymbol, currt2.cursymbol , currt2.description
ORDER BY tiper.amn_contract_id, emp.value, tiper.amndateini