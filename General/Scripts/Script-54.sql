SELECT
-- ORGANIZATION
adempiere.ad_org.value as org_value,
coalesce(adempiere.ad_org.name,adempiere.ad_org.value,'') as org_name,
coalesce(adempiere.ad_org.description,adempiere.ad_org.name,adempiere.ad_org.value,'') as org_description,
coalesce(adempiere.ad_orginfo.taxid,'') as org_taxid,
adempiere.ad_image.binarydata as org_logo,
case  when c_location.address1 is null then '' else c_location.address1  end
  ||
case  when c_location.address2 is null then '' else ', ' || c_location.address2   end
  ||
case  when c_location.address3 is null then '' else ', ' || c_location.address3   end
  ||
case  when c_location.address4 is null then '' else ', ' || c_location.address4   end as org_address1,
case  when c_location.city is null then '' else c_location.city   end
  ||
case  when c_location.regionname is null then '' else ', ' || c_location.regionname  end
  ||
case  when c_location.postal is null then '' else ', CP ' || c_location.postal end as org_address2 ,
case  when ad_orginfo.phone is null then '' else ad_orginfo.phone   end
  ||
case  when ad_orginfo.phone2 is null then '' else ', ' || ad_orginfo.phone2   end as org_phone,
case  when adempiere.ad_orginfo.fax is null then '' else 'Fax:' || adempiere.ad_orginfo.fax end  as org_fax ,
case  when adempiere.ad_orginfo.email is null then '' else 'e-mail:' || adempiere.ad_orginfo.email end  as org_email ,
case  when c_location.city is null then '' else c_location.city   end as org_city,
-- CURRENCY
curr1.iso_code as iso_code1,
COALESCE(currt1.cursymbol,curr1.cursymbol,curr1.iso_code,'') as cursymbol1,
COALESCE(currt1.description,curr1.iso_code,curr1.cursymbol,'') as currname1,
curr2.iso_code as iso_code2,
COALESCE(currt2.cursymbol,curr2.cursymbol,curr2.iso_code,'') as cursymbol2,
COALESCE(currt2.description,curr2.iso_code,curr2.cursymbol,'') as currname2,
curr3.iso_code as iso_code3,
COALESCE(currt3.cursymbol,curr3.cursymbol,curr3.iso_code,'') as cursymbol3,
COALESCE(currt3.description,curr3.iso_code,curr3.cursymbol,'') as currname3,
conv.MultiplyRate,
-- BUSINESS PARTNER
adempiere.c_bpartner.name as name_bp,
adempiere.c_bpartner.taxid as taxid_bp,
coalesce(adempiere.c_bpartner.amerp_nameseniat,adempiere.c_bpartner.name,'') as amerp_nameseniat,
coalesce(adempiere.c_bpartner.amerp_rifseniat,adempiere.c_bpartner.taxid,'') as amerp_rifseniat,
-- BUSINESS PARTNER LOCATION
cbp_l.bplname as bplocname,
coalesce(cbp_l.bplphone,'') as phone,
coalesce(cbp_l.bplphone2,'') as phone2,
coalesce(cbp_l.bplfax,'') as fax,
coalesce(c_bplocation.address1,'') as address1,
coalesce(c_bplocation.address2,'') as address2,
coalesce(c_bplocation.address3,'') as address3,
coalesce(c_bplocation.address4,'') as address4,
coalesce(c_bplocation.city,'') as city,
coalesce(c_bplocation.regionname,'') as regionname,
coalesce(c_bplocation.postal,'') as postal,
-- PAYMENT HEADER
pay.docstatus,
pay.c_payment_id,
pay.created,
cdt.printname,
cdt.docbasetype,
cdttrl.printname as printnamel,
pay.documentno,
pay.c_bpartner_id,
to_char(pay.created,'YYYY') AS paymentyear,
to_char(pay.created,'MM') AS paymentmonth,
to_char(pay.created,'DD') AS paymentday,
to_char(pay.created,'DD-MM-YYYY') AS paymentfecha,
to_char(pay.created,'YYYY-MM-DD') AS paymentfecha2,
to_char(pay.datetrx,'DD-MM-YYYY') AS paymentdate,
coalesce(to_char(pay.datedeposit,'DD-MM-YYYY'), to_char(pay.dateacct,'DD-MM-YYYY')) AS paymentdeposit,
-- Payment Month Name,
case when to_char(pay.datetrx,'MM') ='01' then 'Enero' when to_char(pay.datetrx,'MM') ='02' then 'Febrero' 
     when to_char(pay.datetrx,'MM') ='03' then 'Marzo' when to_char(pay.datetrx,'MM') ='04' then 'Abril'
     when to_char(pay.datetrx,'MM') ='05' then 'Mayo' when to_char(pay.datetrx,'MM') ='06' then 'Junio' 
     when to_char(pay.datetrx,'MM') ='07' then 'Julio' when to_char(pay.datetrx,'MM') ='08' then 'Agosto'
     when to_char(pay.datetrx,'MM') ='09' then 'Septiembre' when to_char(pay.datetrx,'MM') ='10' then 'Octubre' 
     when to_char(pay.datetrx,'MM') ='11' then 'Noviembre' when to_char(pay.datetrx,'MM') ='12' then 'Diciembre'
     else to_char(pay.datetrx,'MM')  end   as paymentmonthname,
-- PAYMENT HEADER
pay.payamt as pay_amt,
pay.discountamt as pay_discountamt,
pay.taxamt as pay_taxamt,
pay.writeoffamt as pay_writeoffamt,
adempiere.amf_num2letter(pay.payamt ,'U','es') as pay_letter,
CASE WHEN conv.MultiplyRate IS NOT NULL
	THEN coalesce(pay.payamt*conv.MultiplyRate ,0)
	ELSE coalesce(pay.payamt,0)
	END AS pay_amt2,
CASE WHEN conv.MultiplyRate IS NOT NULL
	THEN coalesce(pay.discountamt*conv.MultiplyRate,0)
	ELSE coalesce(pay.discountamt,0)
	END AS pay_discountamt2,
CASE WHEN conv.MultiplyRate IS NOT NULL
	THEN coalesce(pay.taxamt*conv.MultiplyRate,0)
	ELSE coalesce(pay.taxamt,0)
	END AS pay_taxamt2,	
CASE WHEN conv.MultiplyRate IS NOT NULL
	THEN coalesce(pay.writeoffamt*conv.MultiplyRate,0)
	ELSE coalesce(pay.writeoffamt,0)
	END AS pay_writeoffamt2,	
CASE WHEN conv.MultiplyRate IS NOT NULL
	THEN adempiere.amf_num2letter(coalesce(pay.payamt*conv.MultiplyRate ,0) ,'U','es') 
	ELSE adempiere.amf_num2letter(pay.payamt ,'U','es') 
	END AS pay_letter2,	
coalesce(pay.description , '') as description_head,
-- PAYMENT HEADER - BANK ACCOUNT
coalesce(adempiere.c_bankaccount.value,'') as pay_bank,
coalesce(adempiere.c_bankaccount.name,'') as pay_bankname,
-- PAYMENT LINE (ALLOCATE)
CASE WHEN payo.all_invoice_id <> 0  THEN 'I'
	WHEN payo.all_invoice_id =0 AND payo.c_charge_id <>0 THEN 'C'
	ELSE 'X' END as charge_invoice,
payo.all_invoice_id as c_invoice_id,
coalesce(payo.all_amount,0) as line_amt,
coalesce(payo.all_discountamt,0) as line_discountamt,
coalesce(payo.all_writeoffamt,0) as line_writeoffamt,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce(payo.all_amount*conv_inv.MultiplyRate,0)
	ELSE coalesce(payo.all_amount,0)
	END AS line_amt2,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce(payo.all_discountamt*conv_inv.MultiplyRate,0)
	ELSE coalesce(payo.all_discountamt,0)
	END AS line_discountamt2,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce(payo.all_writeoffamt*conv_inv.MultiplyRate,0)
	ELSE coalesce(payo.all_writeoffamt,0)
	END AS line_writeoffamt2,
-- PAYMENT HEADER OR LINE (INVOICES INV1)
coalesce(to_char(payo.inv_dateinvoiced,'DD-MM-YYYY'),'') as inv_date,
coalesce(payo.inv_documentno ,'') as inv_number,
coalesce(payo.inv_description,'') as inv_description,
coalesce(adempiere.c_bpartner.name,'') as inv_bpartner,
coalesce(inv.grandtotal, 0)  as inv_grandtotal,
coalesce(inv.totallines,0)  as inv_totallines,
coalesce(inv.grandtotal-inv.totallines,0) as inv_tax,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce((inv.grandtotal* conv_inv.MultiplyRate ),0)
	ELSE coalesce(inv.grandtotal, 0)
	END AS inv_grandtotal2,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce((inv.totallines* conv_inv.MultiplyRate ),0)
	ELSE coalesce(inv.totallines, 0)
	END AS inv_totallines2,
CASE WHEN conv_inv.MultiplyRate IS NOT NULL
	THEN coalesce((coalesce(inv.grandtotal-inv.totallines,0) * conv_inv.MultiplyRate ),0)
	ELSE coalesce(inv.grandtotal-inv.totallines,0) 
	END AS inv_tax2,
conv_inv.IsOverrideCurrencyRate, 
conv_inv.ConversionType,
COALESCE(conv_inv.MultiplyRate,1) as ConversionRate,
-- PAYMENT HEADER OR LINE (CHARGES)
payo.c_charge_id,
coalesce(payo.cha_name,'') as cha_name,
coalesce(payo.cha_description,'') as cha_description,
CASE WHEN payo.c_charge_id is not null then  payo.all_amount else 0 END as cha_grandtotal,
CASE WHEN payo.c_charge_id is not null then
	CASE WHEN conv.MultiplyRate IS NOT NULL
		THEN coalesce(( payo.all_amount * conv.MultiplyRate ),0)
		ELSE coalesce( payo.all_amount,0)
		END
	else 0 END  AS cha_grandtotal2,
-- USER & SALES REP
coalesce(use.name,'') as usercode,
coalesce(use.description,'') as username,
coalesce(salesrep."value",'') as repcode,
coalesce(salesrep.name,'') as repname
FROM adempiere.c_payment pay
LEFT JOIN (
	SELECT
		all_l1.c_bpartner_id,
		CASE WHEN all_l1.c_invoice_id IS NOT NULL AND allocp.c_charge_id IS NULL THEN 13
			WHEN all_l1.c_invoice_id IS NULL AND (cha1.c_charge_id IS NOT NULL OR allocp.c_charge_id IS NOT NULL) THEN 14
			END as all_ord,
		all_h1.c_currency_id as All_Currency_ID, 
		all_h1.dateacct as All_dateacct, all_h1.datetrx as All_datetrx,
		all_l1.c_allocationhdr_id, all_h1.documentno as All_DocumentNo, 
		all_h1.description as All_description,
		COALESCE(doc_tta.shortname,doc_tta.printname, doc_ta.docbasetype) as All_printname,
		all_l1.amount as All_amount, all_l1.discountamt as All_discountamt, all_l1.writeoffamt as All_writeoffamt,
		COALESCE(all_l1.c_invoice_id,0) as All_invoice_id, all_l1.c_payment_id as All_payment_id, allocp.c_charge_id as All_charge_id,
		doc_t1.c_doctype_id, inv1.documentno as Inv_DocumentNo, inv1.description as Inv_Description,
		COALESCE(doc_ttv1.shortname,doc_ttv1.printname, doc_tv1.docbasetype,'') as Inv_printname,
		inv1.dateacct as Inv_dateacct, inv1.dateinvoiced as Inv_dateinvoiced, inv1.c_currency_id as Inv_Currency_ID,
		inv1.C_ConversionType_ID as Inv_ConversionType_ID, inv1.grandtotal as Inv_grandtotal,
		doc_t1.docbasetype as Inv_docbasetype, doc_t1.isSeniatBook, doc_t1.DocSubTypeWH,
		COALESCE(doc_tt1.shortname,doc_tt1.printname, doc_t1.docbasetype,'') as Pay_printname,
		pay1.documentno as Pay_documentno, pay1.dateacct as Pay_dateacct, pay1.datetrx as Pay_datetrx, pay1.c_currency_id as Pay_Currency_ID,
		pay1.C_ConversionType_ID as Pay_ConversionType_ID, pay1.PayAmt as Pay_PayAmt, pay1.DateDeposit as Pay_datedeposit,
		COALESCE(cha1.c_charge_id, allocp.c_charge_id, 0) as c_charge_id, COALESCE(cha1.name, allocp.Cha_name,'') as Cha_name,
		COALESCE(cha1.description, allocp.Cha_description,'') as Cha_description
	FROM 
	adempiere.c_allocationline all_l1
	LEFT JOIN adempiere.c_payment pay1  ON all_l1.c_payment_id = pay1.c_payment_id
	LEFT JOIN adempiere.c_invoice inv1  ON all_l1.c_invoice_id = inv1.c_invoice_id
	LEFT JOIN adempiere.c_doctype doc_t1 ON pay1.c_doctype_id = doc_t1.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tt1 ON doc_t1.c_doctype_id = doc_tt1.c_doctype_id AND doc_tt1.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=pay1.AD_Client_ID)
	LEFT JOIN adempiere.c_doctype doc_tv1 ON inv1.c_doctype_id = doc_tv1.c_doctype_id
	LEFT JOIN c_doctype_trl doc_ttv1 ON doc_tv1.c_doctype_id = doc_ttv1.c_doctype_id AND doc_ttv1.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=inv1.AD_Client_ID)
	LEFT JOIN adempiere.c_allocationhdr all_h1 ON all_h1.c_allocationhdr_id = all_l1.c_allocationhdr_id
	LEFT JOIN adempiere.c_charge  cha1  ON pay1.c_charge_id = cha1.c_charge_id
	LEFT JOIN c_doctype doc_ta ON all_h1.c_doctype_id = doc_ta.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tta ON doc_ta.c_doctype_id = doc_tta.c_doctype_id AND doc_tta.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=all_h1.AD_Client_ID)
	LEFT JOIN (
		SELECT 
		all_l11.c_allocationhdr_id,  all_l11.c_allocationline_id , all_l11.c_charge_id,
		cha1.name as Cha_name, cha1.description as Cha_description
		FROM adempiere.c_allocationline all_l11 
		LEFT JOIN adempiere.c_charge  cha1  ON all_l11.c_charge_id = cha1.c_charge_id
		WHERE all_l11.c_charge_id IS NOT NULL
	) as allocp ON allocp.c_allocationhdr_id  = all_h1.c_allocationhdr_id
	WHERE all_l1.C_Payment_ID IS NOT NULL 
	AND (all_l1.c_invoice_id IS NOT NULL OR allocp.c_charge_id IS NOT NULL OR cha1.c_charge_id IS NOT NULL)
) as payo ON payo.All_payment_id = pay.c_payment_id
LEFT JOIN adempiere.c_bankaccount on pay.c_bankaccount_id = adempiere.c_bankaccount.c_bankaccount_id
LEFT JOIN adempiere.c_invoice as inv ON inv.c_invoice_id = payo.all_invoice_id
LEFT JOIN adempiere.c_charge as cha1 ON cha1.c_charge_id = pay.c_charge_id
LEFT JOIN adempiere.c_doctype as cdt on cdt.c_doctype_id = pay.c_doctype_id
LEFT JOIN adempiere.c_doctype_trl cdttrl on cdt.c_doctype_id = cdttrl.c_doctype_id 
  AND cdttrl.ad_language =  (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID} ))
LEFT JOIN adempiere.ad_org ON adempiere.ad_org.ad_org_id = pay.ad_org_id
LEFT JOIN adempiere.ad_orginfo  ON adempiere.ad_org.ad_org_id = adempiere.ad_orginfo.ad_org_id
LEFT JOIN adempiere.ad_image ON adempiere.ad_orginfo.logo_id= adempiere.ad_image.ad_image_id
LEFT JOIN adempiere.c_location ON adempiere.c_location.c_location_id = adempiere.ad_orginfo.c_location_id
LEFT JOIN adempiere.c_bpartner ON adempiere.c_bpartner.c_bpartner_id = pay.c_bpartner_id
LEFT JOIN ( 
	SELECT DISTINCT ON (c_bpartner_id) 
	c_bpartner_id, c_bpartner_location_id, c_location_id, name as bplname, phone as bplphone,phone2 as bplphone2,fax as bplfax 
	FROM adempiere.c_bpartner_location as cbp_loc WHERE cbp_loc.isbillto='Y'
) as cbp_l ON adempiere.c_bpartner.c_bpartner_id = cbp_l.c_bpartner_id  
LEFT JOIN adempiere.c_location as c_bplocation on c_bplocation.c_location_id = cbp_l.c_location_id
LEFT JOIN adempiere.ad_user as use ON use.ad_user_id = pay.createdby
LEFT JOIN adempiere.ad_user as salesrep on salesrep.ad_user_id = inv.salesrep_id
LEFT JOIN c_currency curr1 on pay.c_currency_id = curr1.c_currency_id
LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language =  (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID}  ))
LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language =  (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID}  ))
LEFT JOIN c_currency curr3 on inv.c_currency_id = curr3.c_currency_id
LEFT JOIN c_currency_trl currt3 on curr3.c_currency_id = currt3.c_currency_id and currt3.ad_language =  (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID =( SELECT AD_Client_ID FROM C_Payment WHERE C_Payment_ID=$P{RECORD_ID}  ))
LEFT JOIN ( 
	SELECT  pay.C_Payment_ID, pay.IsOverrideCurrencyRate, 
	CASE WHEN pay.IsOverrideCurrencyRate ='Y'  THEN pay.CurrencyRate 
		ELSE currencyRate (pay.C_Currency_ID, $P{C_Currency_ID}, pay.DateAcct, pay.C_ConversionType_ID, pay.AD_Client_ID, pay.AD_org_ID) END as MultiplyRate
	FROM C_Payment pay WHERE C_payment_ID=$P{RECORD_ID}
) as conv ON conv.C_Payment_ID = pay.c_payment_id
LEFT JOIN ( 
	SELECT C_invoice_ID, invc1.IsOverrideCurrencyRate, COALESCE(cotyp.name,'Reemplazada') as ConversionType,
	CASE WHEN invc1.IsOverrideCurrencyRate ='Y' THEN invc1.CurrencyRate 
		ELSE currencyRate (invc1.C_Currency_ID, $P{C_Currency_ID}, invc1.DateAcct, invc1.C_ConversionType_ID, invc1.AD_Client_ID, invc1.AD_org_ID) END as MultiplyRate
	FROM C_invoice invc1
	LEFT JOIN C_ConversionType cotyp ON cotyp.C_ConversionType_ID = invc1.C_ConversionType_ID 
) as conv_inv ON conv_inv.C_Invoice_ID = inv.C_Invoice_ID
WHERE  pay.c_payment_id=$P{RECORD_ID} 
ORDER BY payo.all_documentno ASC