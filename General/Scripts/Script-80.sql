CREATE OR REPLACE FUNCTION adempiere.currencyconvertpayment(p_c_payment_id numeric, p_currency_to_id numeric, p_amt numeric DEFAULT NULL::numeric, p_conversiondate timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$		
DECLARE
	v_PayAmt NUMERIC;
	v_ReturnAmt NUMERIC;
	v_ConversionType_ID NUMERIC;
	v_Client_ID NUMERIC;
	v_Org_ID NUMERIC;
	v_Currency_ID NUMERIC;
	v_Currency_ID_to NUMERIC;
	v_CurrencyRate NUMERIC;
	v_CurrencyRate_to NUMERIC := 1;
	v_ConvertedAmt NUMERIC;
	v_DateAcct timestamp with time zone;
	v_BaseCurrency_ID NUMERIC;
	v_IsOverrideCurrencyRate character(1);
BEGIN
	-- AcctSchema Default currency
	SELECT sc.C_Currency_ID
	INTO v_BaseCurrency_ID
	FROM AD_ClientInfo ci
	JOIN C_AcctSchema sc ON ci.C_AcctSchema1_ID=sc.C_AcctSchema_ID
	WHERE ci.AD_Client_ID=v_Client_ID;
	-- Payment Values	
	SELECT pv.AD_Client_ID, pv.AD_Org_ID, pv.DateAcct, pv.C_Currency_ID, 
		CASE WHEN pay.C_Currency_ID_to IS NULL THEN v_BaseCurrency_ID  ELSE pay.C_Currency_ID_to END AS C_Currency_ID_to,
		pv.C_ConversionType_ID, pv.CurrencyRate, pv.ConvertedAmt, pv.PayAmt, pv.IsOverrideCurrencyRate
	INTO v_Client_ID, v_Org_ID, v_DateAcct, v_Currency_ID, v_Currency_ID_to, 
		v_ConversionType_ID, v_CurrencyRate, v_ConvertedAmt, v_PayAmt, v_IsOverrideCurrencyRate
	FROM C_Payment_V pv 
	LEFT JOIN C_Payment pay ON pay.C_Payment_ID = pv.C_Payment_ID
	WHERE pv.C_Payment_ID=p_C_Payment_ID;
	-- 
	IF p_Amt IS NULL THEN
		RETURN v_ConvertedAmt;
	END IF;
	-- SAME AcctSchema Default Currency
	IF v_BaseCurrency_ID=p_Currency_To_id AND Coalesce(v_CurrencyRate,0) > 0 AND Coalesce(v_ConvertedAmt,0) != 0 AND v_Currency_ID != p_Currency_To_id AND v_IsOverrideCurrencyRate='Y' THEN
		--RETURN currencyRound(p_Amt*v_CurrencyRate, p_Currency_To_id, null);
		RETURN p_Currency_To_id;
	END IF;
	-- DIFF AcctSchema Default Currency
	IF v_BaseCurrency_ID <> p_Currency_To_id AND Coalesce(v_CurrencyRate,0) > 0 AND Coalesce(v_ConvertedAmt,0) != 0 AND v_Currency_ID != p_Currency_To_id AND v_IsOverrideCurrencyRate='Y' THEN
		v_CurrencyRate_to := currencyConvert(1 , p_Currency_To_id, v_Currency_ID_to, Coalesce(p_conversionDate,v_DateAcct), v_ConversionType_ID, v_Client_ID, v_Org_ID);
		v_ReturnAmt := currencyRound(p_Amt*v_CurrencyRate * v_CurrencyRate_to, p_Currency_To_id, null);
		RETURN p_Currency_To_id;
	END IF;
	-- DEFAULT currencyconvert 
	RETURN currencyConvert(Coalesce(p_Amt,v_PayAmt), v_Currency_ID, p_Currency_To_id, Coalesce(p_conversionDate,v_DateAcct), v_ConversionType_ID, v_Client_ID, v_Org_ID);
END;
$function$
;
