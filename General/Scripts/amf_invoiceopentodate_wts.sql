-- Function: amf_invoiceopentodate(numeric, numeric, timestamp with time zone)
-- Verify isSeniatBook: 
--	C Credit Memo
--	D Debit Memo
--	I Invoice
--	N Non Book
--  S Special Doc
--  W Withholding
-- Verify DocSubTypeWH for Withholding documents
--  IVA  Vat Tax
--  ISLR Revenue Tax
--  MUNICIPAL Municipal Tax
-- DROP FUNCTION IF EXISTS amf_invoiceopentodate(numeric, numeric, timestamp with time zone);
CREATE OR REPLACE FUNCTION amf_invoiceopentodate(
	p_c_invoice_id numeric,
	p_c_invoicepayschedule_id numeric,
	p_dateacct timestamp with time zone)
	RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    STABLE 
AS $BODY$
DECLARE
	v_Currency_ID  numeric(10);
	v_Precision         NUMERIC := 0;
	v_Min            	NUMERIC := 0;
	v_TotalOpenAmt   	numeric := 0;
	v_PaidAmt           numeric := 0;
	v_Remaining         numeric := 0;
	v_MultiplierAP      numeric := 0;
	v_MultiplierCM      numeric := 0;
	v_Temp              numeric := 0;
	allocationline	    record;
	invoiceschedule	    record;
	v_DateAcct			timestamp with time zone;
BEGIN
 -- Get Currency
 BEGIN
  SELECT MAX(C_Currency_ID), SUM(GrandTotal), MAX(MultiplierAP), MAX(Multiplier), MAX(DateAcct)
    INTO v_Currency_ID, v_TotalOpenAmt, v_MultiplierAP, v_MultiplierCM, v_DateAcct
  FROM C_Invoice_v  -- corrected for CM / Split Payment
  WHERE C_Invoice_ID = p_C_Invoice_ID
    AND DateAcct <= p_DateAcct;
 EXCEPTION -- Invoice in draft form
  WHEN OTHERS THEN
            --DBMS_OUTPUT.PUT_LINE('InvoiceOpen - ' || SQLERRM);
   RETURN NULL;
 END;
--  DBMS_OUTPUT.PUT_LINE('== C_Invoice_ID=' || p_C_Invoice_ID || ', Total=' || v_TotalOpenAmt || ', AP=' || v_MultiplierAP || ', CM=' || v_MultiplierCM);

	SELECT StdPrecision
	    INTO v_Precision
	    FROM C_Currency
	    WHERE C_Currency_ID = v_Currency_ID;

	SELECT 1/10^v_Precision INTO v_Min;
 -- Calculate Allocated Amount
 FOR allocationline IN  
	SELECT 
	CASE WHEN alloc.DocBaseType IS NOT NULL THEN alloc.DocBaseType  ELSE '' END as DocBaseType, 
	CASE WHEN alloc.isSeniatBook IS NOT NULL THEN alloc.isSeniatBook  ELSE '' END as isSeniatBook,
	CASE WHEN alloc.DocSubTypeWH IS NOT NULL THEN alloc.DocSubTypeWH  ELSE '' END as DocSubTypeWH,
	a.AD_Client_ID, a.AD_Org_ID,
	al.Amount, al.DiscountAmt, al.WriteOffAmt,
	a.C_Currency_ID, a.DateTrx, invo.C_ConversionType_ID, invo.DateAcct, invo.C_Invoice_ID
	FROM C_ALLOCATIONLINE al
	INNER JOIN C_ALLOCATIONHDR a ON (al.C_AllocationHdr_ID=a.C_AllocationHdr_ID)
	INNER JOIN C_INVOICE invo ON (invo.C_Invoice_ID = al.C_Invoice_ID )
	LEFT JOIN (
	  	SELECT 
	  	all_l2.c_allocationhdr_id,  all_l2.c_allocationline_id, doc_t2.c_doctype_id, doc_t2.docbasetype, inv2.documentno, 
	   	inv2.dateacct as dateacctinv, inv2.dateinvoiced, inv2.C_ConversionType_ID, doc_t2.isSeniatBook, doc_t2.DocSubTypeWH
		FROM adempiere.c_allocationline all_l2  
	   	LEFT JOIN adempiere.c_invoice inv2  ON all_l2.c_invoice_id = inv2.c_invoice_id
	   	LEFT JOIN adempiere.c_doctype doc_t2 ON inv2.c_doctype_id = doc_t2.c_doctype_id
	   	WHERE doc_t2.docbasetype IN ('ARC', 'APC', 'ARW', 'APW')
  	) as alloc ON alloc.c_allocationhdr_id  = al.c_allocationhdr_id
	WHERE al.C_Invoice_ID = p_C_Invoice_ID
	AND a.DateAcct <= p_DateAcct
	AND   a.IsActive='Y'
 LOOP
	v_Temp := allocationline.Amount + allocationline.DisCountAmt + allocationline.WriteOffAmt;
	 -- Allocation Verify if NC or WithHolding AND Not Payment or CHARGE
 	IF  (allocationline.DocBaseType IN ('W','C')  OR allocationline.DocSubTypeWH IN ('IVA','ISLR','MUNICIPAL')) THEN
	  	v_PaidAmt := v_PaidAmt         
--	    + CurrencyconvertInvoice(allocationline.C_Invoice_ID, allocationline.C_Currency_ID, v_Temp * v_MultiplierAP, v_DateAcct );
	    + Currencyconvert(v_Temp * v_MultiplierAP,
	    allocationline.C_Currency_ID, v_Currency_ID, allocationline.DateAcct, allocationline.C_ConversionType_ID, allocationline.AD_Client_ID, allocationline.AD_Org_ID);
	ELSE
	  	v_PaidAmt := v_PaidAmt         
--	    + CurrencyconvertInvoice(allocationline.C_Invoice_ID, allocationline.C_Currency_ID, v_Temp * v_MultiplierAP, allocationline.DateAcct );
	    + Currencyconvert(v_Temp * v_MultiplierAP,
	    allocationline.C_Currency_ID, v_Currency_ID, allocationline.DateTrx, allocationline.C_ConversionType_ID, allocationline.AD_Client_ID, allocationline.AD_Org_ID);
	    
	END IF;
      --DBMS_OUTPUT.PUT_LINE('   PaidAmt=' || v_PaidAmt || ', Allocation=' || v_Temp || ' * ' || v_MultiplierAP);
 END LOOP;
    --  Do we have a Payment Schedule ?
    IF (p_C_InvoicePaySchedule_ID > 0) THEN --   if not valid = lists invoice amount
        v_Remaining := v_PaidAmt;
        FOR invoiceschedule IN 
        SELECT  C_InvoicePaySchedule_ID, DueAmt FROM    C_INVOICEPAYSCHEDULE WHERE C_Invoice_ID = p_C_Invoice_ID AND IsValid='Y'
        ORDER BY DueDate
        LOOP
            IF (invoiceschedule.C_InvoicePaySchedule_ID = p_C_InvoicePaySchedule_ID) THEN
                v_TotalOpenAmt := (invoiceschedule.DueAmt*v_MultiplierCM) - v_Remaining;
                IF (invoiceschedule.DueAmt - v_Remaining < 0) THEN
                    v_TotalOpenAmt := 0;
                END IF;
            --  DBMS_OUTPUT.PUT_LINE('Sched Total=' || v_TotalOpenAmt || ', Due=' || s.DueAmt || ',Remaining=' || v_Remaining || ',CM=' || v_MultiplierCM);
            ELSE -- calculate amount, which can be allocated to next schedule
                v_Remaining := v_Remaining - invoiceschedule.DueAmt;
                IF (v_Remaining < 0) THEN
                    v_Remaining := 0;
                END IF;
            --  DBMS_OUTPUT.PUT_LINE('Remaining=' || v_Remaining);
            END IF;
        END LOOP;
    ELSE
        v_TotalOpenAmt := v_TotalOpenAmt - v_PaidAmt;
    END IF;
--  DBMS_OUTPUT.PUT_LINE('== Total=' || v_TotalOpenAmt);
	--	Ignore Rounding
	IF (v_TotalOpenAmt > -v_Min AND v_TotalOpenAmt < v_Min) THEN
		v_TotalOpenAmt := 0;
	END IF;
	--	Round to currency precision
	v_TotalOpenAmt := ROUND(COALESCE(v_TotalOpenAmt,0), v_Precision);
	RETURN v_TotalOpenAmt;
END;
$BODY$ ;
ALTER FUNCTION amf_invoiceopentodate(numeric, numeric, timestamp with time zone)
  OWNER TO adempiere;
