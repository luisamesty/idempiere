SELECT C_AcctSchema_ID 
FROM C_AcctSchema AS asch 
INNER JOIN C_Currency curr ON curr.c_currency_id = asch.c_currency_id 
WHERE asch.AD_Client_ID = 1000000 AND curr.iso_code='VES' --AND  C_AcctSchema_ID=1000001;


SELECT * FROM C_Period WHERE
c_period_id = 1000076