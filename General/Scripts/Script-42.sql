select * from ad_column where ad_table_id in 
(select ad_table_id from ad_table where tablename='LCO_WithholdingCategory')