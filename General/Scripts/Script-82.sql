CREATE OR REPLACE FUNCTION adempiere.currencyconvertpayment(p_c_payment_id numeric, p_currency_to_id numeric, p_amt numeric DEFAULT NULL::numeric, p_conversiondate timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$		
DECLARE
	v_PayAmt NUMERIC;
	v_ReturnAmt NUMERIC := 0;
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
	-- Payment Values
	SELECT pv.AD_Client_ID, pv.AD_Org_ID, pv.DateAcct, pv.C_Currency_ID
	INTO v_Client_ID, v_Org_ID, v_DateAcct, v_Currency_ID
	FROM C_Payment_V pv 
	WHERE pv.C_Payment_ID=p_C_Payment_ID;
	-- AcctSchema Default currency
	SELECT sc.C_Currency_ID
	INTO v_BaseCurrency_ID
	FROM AD_ClientInfo ci
	LEFT JOIN C_AcctSchema sc ON ci.C_AcctSchema1_ID=sc.C_AcctSchema_ID
	WHERE ci.AD_Client_ID=v_Client_ID;
	-- Payment Values	
	SELECT CASE WHEN pay.C_Currency_ID_to IS NULL THEN v_BaseCurrency_ID  ELSE pay.C_Currency_ID_to END AS C_Currency_ID_to,
		v_ConversionType_ID, pv.CurrencyRate, pv.ConvertedAmt, pv.PayAmt, pv.IsOverrideCurrencyRate
	INTO v_Currency_ID_to, v_ConversionType_ID, v_CurrencyRate, v_ConvertedAmt, v_PayAmt, v_IsOverrideCurrencyRate
	FROM C_Payment_V pv 
	LEFT JOIN C_Payment pay ON pay.C_Payment_ID = pv.C_Payment_ID
	WHERE pv.C_Payment_ID=p_C_Payment_ID;
	-- 
	IF v_IsOverrideCurrencyRate='Y' AND Coalesce(v_CurrencyRate,0) > 0 AND Coalesce(v_ConvertedAmt,0) != 0 AND v_Currency_ID != p_Currency_To_id THEN
		-- SAME Currency
		IF p_currency_to_id = v_Currency_ID_to THEN
			v_CurrencyRate_to := 1;
		-- DIFF  Currency (Calculates currency convert between them)
		ELSE
			v_CurrencyRate_to := currencyRate (v_Currency_ID_to , p_currency_to_id,  v_DateAcct, v_ConversionType_ID, v_Client_ID, v_Org_ID);		
		END IF;
		-- Final return Amount
		IF p_Amt IS NULL THEN
			v_ReturnAmt := currencyRound(v_PayAmt*v_CurrencyRate * v_CurrencyRate_to, p_Currency_To_id, null);
		ELSE
			v_ReturnAmt := currencyRound(p_Amt*v_CurrencyRate * v_CurrencyRate_to, p_Currency_To_id, null);
		END IF;
		RETURN v_ReturnAmt;
	ELSE
		-- DEFAULT currencyconvert NOT OVERRIDED
		v_ReturnAmt := currencyConvert(Coalesce(p_Amt,v_PayAmt), v_Currency_ID, p_Currency_To_id, Coalesce(p_conversionDate,v_DateAcct), v_ConversionType_ID, v_Client_ID, v_Org_ID);
		RETURN v_ReturnAmt;
	END IF;
END;
$function$
;