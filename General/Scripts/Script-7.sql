SELECT distinct ci.AD_Client_ID, sc.C_Currency_ID, ci.C_AcctSchema1_ID as C_AcctSchema_ID 
FROM  AD_ClientInfo ci
left join C_ACCTSchema sc on sc.c_acctschema_id  = ci.c_acctschema1_id 
WHERE ci.AD_Client_ID=1000000