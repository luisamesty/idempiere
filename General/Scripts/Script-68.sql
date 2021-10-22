SELECT abv.c_invoice_id, abv.c_payment_Id, abv.documentno_p, abv.cha_name, abv.all_description  FROM 
amf_bpstatement_v4 abv 
WHERE abv.ad_client_id = 1000000
--AND abv.c_invoice_id NOT IN (SELECT c_invoice_id FROM amf_bpstatement_v41  )