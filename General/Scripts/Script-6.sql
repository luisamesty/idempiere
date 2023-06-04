select * from c_invoice ci 
where reversal_id is not null 
and dateacct > '2020-08-02' and c_invoice_id in (1054794,1055072)
order by documentno, dateinvoiced 