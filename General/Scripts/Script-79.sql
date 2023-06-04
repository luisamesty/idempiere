

-- 1 BORRA CAMPOS DE FORMATITEM
DELETE FROM ad_printformatitem
WHERE AD_column_ID IN (
	SELECT co2.AD_Column_ID 
--	, co2.name, co2.ad_table_id ,ta2."name" ,* 
	FROM AD_COlumn co2
	LEFT JOIN AD_table ta2 ON ta2.ad_table_id = co2.ad_table_id 
	WHERE columnname IN ('IsOverrideCurrencyRate', 'ConvertedAmt', 'CurrencyRate')
	AND co2.ad_table_id IN (335, 318, 392)
);

-- 2 BORRA CAMPOS DE LAS VENTANAS
DELETE FROM AD_Field
WHERE AD_FIELD_ID IN (
	SELECT af.ad_field_id
--	,af.name, af.description, ta2.tablename AS tablename
	FROM ad_field af 
	LEFT JOIN ad_tab at2 ON at2.ad_tab_id = af.ad_tab_id 
	LEFT JOIN ad_table ta2 ON ta2.ad_table_id = at2.ad_table_id 
	WHERE af.ad_column_id IN (
		SELECT co2.AD_Column_ID
		FROM AD_COlumn co2
		LEFT JOIN AD_table ta2 ON ta2.ad_table_id = co2.ad_table_id 
	WHERE co2.columnname IN ('IsOverrideCurrencyRate', 'ConvertedAmt', 'CurrencyRate')
	AND ta2.ad_table_id IN (335, 318, 392)
	)
);

-- 3 BORRA COLUMNAS DE LAS TABLAS 
DELETE FROM AD_Column
WHERE AD_column_ID IN (
	SELECT co2.AD_Column_ID 
--	, co2.name, co2.ad_table_id ,ta2."name" ,* 
	FROM AD_COlumn co2
	LEFT JOIN AD_table ta2 ON ta2.ad_table_id = co2.ad_table_id 
	WHERE columnname IN ('IsOverrideCurrencyRate', 'ConvertedAmt', 'CurrencyRate')
	AND co2.ad_table_id IN (335, 318, 392)
);

