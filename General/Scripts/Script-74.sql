SELECT * FROM	( 
SELECT c_elementvalue_id, ele.value, ele.name, 
fas.c_activity_id ,
SUM(CASE WHEN ( fas.postingtype = 'A' AND fas.DateAcct <= '2021-09-30' ) THEN (fas.amtacctdr - fas.amtacctcr) ELSE 0 END) AS closebalance 
FROM fact_acct fas 
LEFT JOIN c_elementvalue ele ON (ele.c_elementvalue_id = fas.account_id AND ele.ad_client_id = fas.ad_client_id ) 
LEFT JOIN c_activity act ON (fas.c_activity_id =act.c_activity_id)
WHERE ele.issummary = 'N' AND fas.ad_client_id = 1000000  AND fas.ad_org_id =1000000 AND fas.c_acctschema_id =1000001 
GROUP BY c_elementvalue_id , fas.c_activity_id
ORDER BY ele.value ) AS saldos 
WHERE saldos.closebalance <> 0 
