SELECT co2.AD_Column_ID, co2.name, co2.description, ta2."name" ,* 
FROM AD_COlumn co2
LEFT JOIN AD_table ta2 ON ta2.ad_table_id = co2.ad_table_id 
WHERE columnname = 'IsOverrideCurrencyRate';


SELECT AD_Column_ID, name, description 
FROM AD_COlumn 
ORDER BY AD_Column_ID DESC;

SELECT AD_Column_ID, name, description, * 
FROM AD_COlumn 
WHERE AD_Column_ID=213664;

SELECT 
isoverridecurrencyrate , currencyrate , convertedamt  FROM c_bankstatement cb ;

