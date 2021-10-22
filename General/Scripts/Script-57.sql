SELECT
	MultiplyRate
FROM
	C_Conversion_Rate
WHERE
	C_Currency_ID =1000000
	AND C_Currency_ID_To =100
	AND C_ConversionType_ID =114
	AND '2021-04-16 00:00:00.0' BETWEEN ValidFrom AND ValidTo
	AND AD_Client_ID IN (0,1000000)
	AND AD_Org_ID IN (0,1000000)
	AND IsActive = 'Y'
ORDER BY
	AD_Client_ID DESC,
	AD_Org_ID DESC,
	ValidFrom DESC