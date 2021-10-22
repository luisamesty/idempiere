select 
civ.c_invoice_id, civ.grandtotal,
invoiceopen(civ.c_invoice_id,civ.C_InvoicePaySchedule_ID) as openall,
amf_invoiceopen(civ.c_invoice_id,civ.C_InvoicePaySchedule_ID) as amf_openall,
invoiceopentodate(civ.c_invoice_id,civ.C_InvoicePaySchedule_ID, '2020-10-31') as opentodate,
amf_invoiceopentodate(civ.c_invoice_id,civ.C_InvoicePaySchedule_ID, '2020-10-31') as amf_opentodate
from c_invoice_v civ 
where civ.c_invoice_id = 1054553