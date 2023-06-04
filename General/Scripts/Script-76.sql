SELECT * FROM (
	SELECT bpacct.AD_Client_ID, bpacct.C_AcctSchema_ID,	bpacct.c_elementvalue_id, ceval.value, ceval.name,
		bpacct.c_bpartner_id, bpacct.m_product_id, bpacct.bp_value, bpacct.bp_name, bpacct.pro_value, bpacct.pro_name,
		COALESCE(bpbal2.openbalance, 0) AS openbalance, COALESCE(bpbal.amtacctdr, 0) AS amtacctdr, COALESCE(bpbal.amtacctcr, 0) AS amtacctcr,
		COALESCE(bpbal.amtacctsa, 0) AS amtacctsa,
		COALESCE(bpbal2.openbalance, 0) + COALESCE(bpbal.amtacctdr, 0) - COALESCE(bpbal.amtacctcr, 0) AS closebalance
	FROM (
		SELECT DISTINCT fac1.AD_Client_ID,
			fac1.C_AcctSchema_ID,
			COALESCE(bpa.value, 'NO_BP') AS bp_value,
			COALESCE(bpa.name, 'NON BUSINESS PARTNER') AS bp_name,
			COALESCE(pro.value, 'NO_PRODUCT') AS pro_value,
			COALESCE(pro.name, 'NO PRODUCT') AS pro_name,
			COALESCE(fac1.C_Bpartner_ID, 0 ) AS C_Bpartner_ID,
			COALESCE(fac1.m_product_id, 0) AS m_product_id,
			fac1.account_id AS C_ElementValue_ID
		FROM fact_acct fac1
		LEFT JOIN C_ElementValue cevr ON (cevr.C_ElementValue_ID = fac1.account_id)
		LEFT JOIN C_BPartner bpa ON (bpa.C_BPartner_ID = fac1.C_BPartner_ID)
		LEFT JOIN M_Product pro ON 	(pro.m_product_id = fac1.m_product_id)
		WHERE fac1.AD_Client_ID = 1000000 AND fac1.C_AcctSchema_ID = 1000001 AND fac1.account_id = 1000035 
	) AS bpacct
	LEFT JOIN C_ElementValue ceval ON ( ceval.C_ElementValue_ID = bpacct.C_ElementValue_ID)
	LEFT JOIN (
		SELECT
			ele.AD_Client_ID,
			fac3.c_acctschema_id,
			ele.c_elementvalue_id,
			COALESCE(fac3.c_bpartner_id, 0) AS c_bpartner_id,
			COALESCE(fac3.m_product_id, 0) AS m_product_id,
			COALESCE(bpa.value, 'NO_BP') AS bp_value,
			COALESCE(bpa.name, 'NON BUSINESS PARTNER') AS bp_name,
			COALESCE(pro.value, 'NO_PRODUCT') AS pro_value,
			COALESCE(pro.name, 'NO PRODUCT') AS pro_name,
			SUM(CASE WHEN (fac3.postingtype = 'A' AND fac3.DateAcct < per.StartDAte) THEN (fac3.amtacctdr - fac3.amtacctcr) ELSE 0 END) AS openbalance,
			SUM(CASE WHEN (fac3.postingtype = 'A' AND fac3.DateAcct >= per.StartDAte AND fac3.DateAcct <= per.EndDate) THEN COALESCE(fac3.amtacctdr, 0) ELSE 0 END) AS amtacctdr,
			SUM(CASE WHEN (fac3.postingtype = 'A' AND fac3.DateAcct >= per.StartDAte AND fac3.DateAcct <= per.EndDate) THEN COALESCE(fac3.amtacctcr, 0) ELSE 0 END) AS amtacctcr,
			SUM(COALESCE(fac3.amtacctdr, 0))- SUM(COALESCE(fac3.amtacctcr, 0)) AS amtacctsa
		FROM c_elementvalue ele
		LEFT JOIN fact_acct fac3 ON (ele.c_elementvalue_id = fac3.account_id AND ele.ad_client_id = fac3.ad_client_id )
		LEFT JOIN c_bpartner bpa ON (bpa.c_bpartner_id = fac3.c_bpartner_id)
		LEFT JOIN m_product pro  ON (pro.m_product_id = fac3.m_product_id)
		RIGHT JOIN c_period per  ON (per.c_period_id = fac3.c_period_id)
		WHERE ele.ad_client_id = 1000000
			AND fac3.ad_org_id =1000000
			AND fac3.c_acctschema_id =1000001
			AND per.C_Period_ID = 1000112
			AND ele.c_elementvalue_id =1000035
		GROUP BY
			ele.AD_Client_ID,
			fac3.c_acctschema_id,
			ele.c_elementvalue_id,
			fac3.c_bpartner_id,
			fac3.m_product_id,
			bp_value,
			bp_name,
			pro_value,
			pro_name 
	) AS bpbal ON 	(bpbal.c_elementvalue_id = ceval.C_ElementValue_ID AND bpbal.c_bpartner_id = bpacct.C_Bpartner_ID )
	LEFT JOIN (
		SELECT
			ele.AD_Client_ID,
			fac3.c_acctschema_id,
			ele.c_elementvalue_id,
			COALESCE(fac3.c_bpartner_id, 0) AS c_bpartner_id,
			COALESCE(fac3.m_product_id, 0) AS m_product_id,
			SUM(CASE WHEN (fac3.postingtype = 'A' AND fac3.DateAcct < per.startdate) THEN (fac3.amtacctdr - fac3.amtacctcr) ELSE 0 END) AS openbalance
		FROM c_elementvalue ele
		LEFT JOIN fact_acct fac3 ON (ele.c_elementvalue_id = fac3.account_id AND ele.ad_client_id = fac3.ad_client_id )
		LEFT JOIN c_bpartner bpa ON (bpa.c_bpartner_id = fac3.c_bpartner_id)
		LEFT JOIN m_product pro ON 	(pro.m_product_id = fac3.m_product_id)
		LEFT JOIN (
			SELECT DISTINCT AD_Client_ID, StartDAte, c_period_id
			FROM C_Period
			WHERE c_period_id = 1000112) per ON (per.ad_client_id = ele.ad_client_id)
		WHERE
			ele.ad_client_id = 1000000
			AND fac3.ad_org_id =1000000
			AND fac3.c_acctschema_id =1000001
			AND ele.c_elementvalue_id =1000035
		GROUP BY
			ele.AD_Client_ID,
			fac3.c_acctschema_id,
			ele.c_elementvalue_id,
			fac3.c_bpartner_id,
			fac3.m_product_id ) AS bpbal2 ON (bpbal2.c_elementvalue_id = ceval.C_ElementValue_ID AND bpbal2.c_bpartner_id = bpacct.C_Bpartner_ID ) 
	) AS todos
WHERE ( openbalance <> 0 OR amtacctsa <> 0 OR amtacctdr <> 0 OR amtacctcr <> 0 	OR closebalance <> 0)
ORDER BY value, bp_value