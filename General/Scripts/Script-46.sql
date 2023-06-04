select inv.documentno , inv.issotrx, * 
from lco_invoicewithholding li 
left join c_invoice inv on inv.c_invoice_id = li.c_invoice_id 
where li.c_invoice_id not in (select c_invoice_id from c_invoice)