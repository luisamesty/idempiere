-- adempiere.amf_bpstatement_v41  Release 4.1 2021-06-09
-- IMPROVE PERformance on BPStatement Queries
DROP VIEW IF EXISTS adempiere.amf_bpstatement_v41;
-- ************************************************************************************
-- MAIN SELECT  
-- MAIN VIEW  amf_bpstatement_v4
-- ************************************************************************************
CREATE VIEW adempiere.amf_bpstatement_v41 AS 
SELECT 
	row_number() over(PARTITION BY bpst.ord, bpst.document_id) as rn, 
	CASE 
		--  Sales 1 UNALLOCATED INVOICES 
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'DB' 
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'DB' 
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'CR'
		--  Sales 2 ALLOCATED INVOICES
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'DB' 
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'DB' 
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'CR'
		--  Sales 3 INVOICE ALLOCATIONS (Payments(3) )
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		--  Sales 4  INVOICE ALLOCATIONS (Charges(4) )
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('ARI','ARF')) THEN 'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('ARW','ARC')) THEN 'CR'
		--  Sales 5 INVOICE ALLOCATIONS (Other Documnents(5) )
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('ARC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('APC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('ARC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('APC')) THEN 'CR'
		-- Sales 11 UNALLOCATED PAYMENTS
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		-- Sales 12 ALLOCATED PAYMENTS
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		-- Sales 13 PAYMENT ALLOCATION
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal > 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='Y' AND bpst.grandtotal < 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		-- Purchase 1 UNALLOCATED INVOICES 
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('API','APF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('APW','APC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('API','APF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 1 AND bpst.docbasetype IN ('APW','APC')) THEN 'DB'
		-- Purchase 2 ALLOCATED INVOICES 
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('API','APF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('APW','APC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('API','APF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 2 AND bpst.docbasetype IN ('APW','APC')) THEN 'DB'
		-- Purchase 3 INVOICE ALLOCATIONS (Payments(3) )
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 3 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		-- Purchase 4  INVOICE ALLOCATIONS (Charges(4))
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('API','APF')) THEN 'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('APW','APC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('API','APF')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 4 AND bpst.docbasetype IN ('APW','APC')) THEN 'DB'
		-- Purchase 5 INVOICE ALLOCATIONS (Other Documnents(5) )
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('ARC')) THEN 'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('APC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('ARC')) THEN 'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 5 AND bpst.docbasetype IN ('APC')) THEN 'DB'
		-- Purchase 11 UNALLOCATED PAYMENTS
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 11 AND bpst.docbasetype IN ('ARR')) THEN  'DR'
		-- Purchase 12  ALLOCATED PAYMENTS
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 12 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		-- Purchase 13 PAYMENT ALLOCATION
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('APP')) THEN  'CR'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal > 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('ARR')) THEN  'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('APP')) THEN  'DB'
		WHEN (bpst.isSOTrx ='N' AND bpst.grandtotal < 0 AND bpst.ord= 13 AND bpst.docbasetype IN ('ARR')) THEN  'CR'
		-- GL JOURNAL 21
		WHEN (bpst.grandtotal >= 0 AND bpst.ord= 21 AND bpst.docbasetype IN ('GLJ')) THEN  'DB'
		WHEN (bpst.grandtotal < 0 AND bpst.ord= 21 AND bpst.docbasetype IN ('GLJ')) THEN  'CR'		
        END as signdbcr,
	bpst.*
	FROM
	(	SELECT
		fa.ad_client_id, fa.ad_org_id,
		reg.c_region_id, 
		reg.name AS region, 
		COALESCE(cbp_us.ad_user_id,0) as ad_user_id,
		COALESCE(cbp_us.name,cbp_us.description,'N/D') as bprep,
		COALESCE(cbp_g.c_bp_group_id,0) as c_bp_group_id,  
		COALESCE(cbp_g.name, 'N/D') as bpgroup, 
		COALESCE(cbp_ch.c_bp_channel_id,0) AS c_bp_channel_id, 
		COALESCE(cbp_ch.name, 'N/D') as bpchannel, 
		cbp.c_bpartner_id as c_bpartner_id,
		cbp.salesrep_id, 
		cbp.bp_value AS vpartner, 
		COALESCE(cbp_l.phone,'') as phone, 
		COALESCE(cbp_l.phone2,'') as phone2, 
		COALESCE(cbp_us2.description,'') as username,  
		COALESCE(cbp_us2.phone,'') as userphone, 
		COALESCE(cbp_us2.phone2,'') as userphone2,
		cbp.bp_name AS bpartner, 
		cbp.bp_taxid AS bp_taxid, 
		cbp.isCustomer,
		cbp.isVendor,
		cbp.isEmployee,
		bpcev.C_ElementValue_ID, 
		bpcev.value as bpcev_value, 
		bpcev.name as bpcev_name,
		-- NEW bpst
		CASE WHEN ad_table_id = 335 THEN pay.c_payment_id WHEN ad_table_id = 318 THEN inv.c_invoice_id ELSE 0 END AS document_id,
		CASE WHEN ad_table_id = 318 THEN inv.c_invoice_id ELSE 0 END AS c_invoice_id,
		CASE WHEN ad_table_id = 335 THEN pay.c_payment_id ELSE 0 END AS c_payment_id,
		CASE WHEN ad_table_id = 335 THEN pay.isreceipt
			WHEN ad_table_id = 318 THEN inv.isSOTrx 
			ELSE 'N' END AS isSOTrx,
		CASE WHEN ad_table_id = 335 THEN CONCAT(TRIM(baa.name),' ',TRIM(pay.description))
			WHEN ad_table_id = 318 THEN inv.description 
			ELSE '' END AS document,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.datedeposit IS NOT NULL THEN concat('FecDep:',to_char(pay.datedeposit,'DD/MM/YYYY')) ELSE '' END
			WHEN ad_table_id = 318 THEN 
				CASE WHEN inv.documentno IS NOT NULL THEN concat('Ord:',inv.documentno,'_',to_char(inv.dateordered,'DD/MM/YYYY')) 
					ELSE CONCAT('Asignacion Pago',inv.documentno) END
			ELSE '' END AS reference,
		fa.dateacct AS date_act, 
		CASE WHEN ad_table_id = 335 THEN pay.docstatus WHEN ad_table_id = 318 THEN inv.docstatus ELSE '' END AS docstatus,
		CASE WHEN ad_table_id = 335 THEN pay.documentno WHEN ad_table_id = 318 THEN inv.documentno ELSE '' END AS documentno,
		CASE WHEN ad_table_id = 335 THEN paya.inv_documentno WHEN ad_table_id = 318 THEN inva.pay_documentno ELSE '' END AS documentnoa,
		CASE WHEN ad_table_id = 335 THEN CONCAT(to_char(pay.dateacct,'YYYY-MM-DD'),'_',pay.documentno) 
			WHEN ad_table_id = 318 THEN CONCAT(to_char(inv.dateacct,'YYYY-MM-DD'),'_',inv.documentno)  ELSE '' END AS documentno_p,
		CASE WHEN ad_table_id = 335 THEN pay.dateacct WHEN ad_table_id = 318 THEN inv.dateinvoiced ELSE fa.datetrx END AS datedoc_p,
		CASE WHEN ad_table_id = 335 THEN pay.datetrx WHEN ad_table_id = 318 THEN inv.dateinvoiced ELSE fa.datetrx END AS datedoc,
		fa.dateacct AS dateacct,
		-- OLD bpst
		CASE WHEN ad_table_id = 335 THEN 
			CASE 	WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_tp.docbasetype='APP' AND baa.isPettyCash='N' THEN doc_tapp.c_doctype_id 
				WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_tp.docbasetype='ARR' THEN doc_tapp.c_doctype_id 
				ELSE doc_tp.c_doctype_id END 
			WHEN ad_table_id = 318 THEN inv.c_doctype_id 
		ELSE 0 END AS c_doctype_id,
		CASE WHEN ad_table_id = 335 THEN doc_tp.docbasetype WHEN ad_table_id = 318 THEN doc_ti.docbasetype ELSE '' END AS docbasetype,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_tp.docbasetype='APP' AND baa.isPettyCash='N' THEN 'CaTR-CR' 
					 WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_tp.docbasetype='ARR' THEN 'BaTR-DB'
					 ELSE COALESCE(doc_ttp.shortname,doc_tp.docbasetype) END 
			WHEN ad_table_id = 318 THEN COALESCE(doc_tti.shortname,doc_ti.docbasetype)
		ELSE '' END AS shortname,
		CASE WHEN ad_table_id = 335 THEN 
			CASE WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='B' AND doc_tp.docbasetype='APP' AND baa.isPettyCash='N' THEN 'CAJA-TR-CR' 
				WHEN pay.c_charge_id IS NOT NULL AND baa.bankaccounttype ='C' AND doc_tp.docbasetype='ARR' THEN 'BANCO-TR-DB'
				ELSE COALESCE(doc_ttp.shortname,doc_tp.docbasetype) END
			WHEN ad_table_id = 318 THEN COALESCE(doc_tti.shortname,doc_ti.docbasetype)
		ELSE '' END AS shortnamep,
		fa.c_currency_id,
		cur.iso_code,
		CASE WHEN ad_table_id = 335 THEN pay.c_conversiontype_id WHEN ad_table_id = 318 THEN inv.c_conversiontype_id ELSE 0 END AS c_conversiontype_id,
		CASE WHEN ad_table_id = 335 THEN NULL WHEN ad_table_id = 318 THEN inv.c_paymentterm_id ELSE NULL END AS c_paymentterm_id,
		CASE WHEN ad_table_id = 335 THEN 0 WHEN ad_table_id = 318 THEN pay_t.netdays ELSE 0 END AS paydays,
			CASE WHEN ad_table_id = 335 THEN pay.dateacct
				WHEN ad_table_id = 318 THEN 
					CASE WHEN ips.c_invoicepayschedule_id IS NULL THEN 
						CASE WHEN inv.DateShipment <> inv.DateAcct THEN inv.DateShipment + pay_t.Netdays*INTERVAL'1 day'
							ELSE inv.DateAcct+pay_t.Netdays*INTERVAL'1 day' END
			      ELSE amf_invoicepaymenttermduedate(pay_t.c_paymentterm_id, inv.c_invoice_id) END
		ELSE NULL END AS duedate,
		CASE WHEN ad_table_id = 335 THEN 
				0
			WHEN ad_table_id = 318 THEN 
				CASE WHEN ips.c_invoicepayschedule_id IS NULL THEN 
					CASE WHEN inv.DateShipment <> inv.DateAcct 
						THEN date_part('day',age(inv.DateShipment + pay_t.Netdays*INTERVAL'1 day', inv.DateAcct ) )
						ELSE date_part('day',age(inv.DateAcct+pay_t.Netdays*INTERVAL'1 day', inv.DateAcct ) ) END
		     	ELSE date_part('day',age(adempiere.amf_invoicepaymenttermduedate(inv.c_paymentterm_id, inv.c_invoice_id), inv.dateinvoiced ) ) END
		ELSE 0 END AS daysdue,
		CASE WHEN ad_table_id = 335 THEN NULL
			WHEN ad_table_id = 318 THEN CASE WHEN ips.isvalid='Y' THEN ips.c_invoicepayschedule_id ELSE 0 END
		ELSE NULL END AS c_invoicepayschedule_id,
		CASE WHEN ad_table_id = 335 THEN NULL WHEN ad_table_id = 318 THEN ips.duedate ELSE NULL END AS o_duedate,
		CASE WHEN ad_table_id = 335 THEN 0 WHEN ad_table_id = 318 THEN inv.totallines ELSE 0 END AS source_totallines,
		CASE WHEN ad_table_id = 335 THEN (pay.payamt+pay.writeoffamt+pay.discountamt) WHEN ad_table_id = 318 THEN inv.grandtotal ELSE 0 END AS grandtotal, 
		CASE WHEN ad_table_id = 335 THEN (pay.payamt+pay.writeoffamt+pay.discountamt) WHEN ad_table_id = 318 THEN inv.grandtotal ELSE 0 END AS source_grandtotal, 
		CASE WHEN ad_table_id = 335 THEN 0 WHEN ad_table_id = 318 THEN inv.withholdingamt ELSE 0 END AS source_withholdingamt,
		CASE WHEN ad_table_id = 335 THEN 
	 			CASE WHEN pay.IsAllocated='N' THEN 11 WHEN pay.IsAllocated='Y' THEN 12 	END
			WHEN ad_table_id = 318 THEN 
	 			CASE WHEN inv.isPaid ='N' THEN 1 WHEN inv.isPaid ='Y' THEN 2 END
		ELSE 0 END	AS ord,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.IsAllocated='N' THEN 'N'
					WHEN pay.IsAllocated='Y' THEN 'Y' END 
			WHEN ad_table_id = 318 THEN inv.ispaid ELSE 'N' 
		END as ispaid,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.IsAllocated='N' THEN 'N'
					WHEN pay.IsAllocated='Y' THEN 'Y'
				END
			WHEN ad_table_id = 318 THEN 
				CASE WHEN inv.isPaid ='N' THEN 'N'
					WHEN inv.isPaid ='Y' THEN 'Y'		
				END  
			ELSE 'N' 
		END as IsAllocated,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN paya.all_invoice_id IS NOT NULL AND paya.all_charge_id IS NULL THEN 13
					WHEN paya.all_invoice_id IS NULL AND (cha.c_charge_id IS NOT NULL OR paya.all_charge_id IS NOT NULL) THEN 14
					END 				
			WHEN ad_table_id = 318 THEN 
				CASE WHEN paya.all_payment_id IS NOT NULL THEN 3
					WHEN paya.all_payment_id IS  NULL AND inva.all_charge_id IS NOT NULL THEN 4
					WHEN paya.all_payment_id IS  NULL AND inva.all_charge_id IS NULL THEN 5
					END
			ELSE 0 
		END  as all_ord,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.c_charge_id  IS NOT NULL THEN pay.C_Currency_ID ELSE paya.all_currency_id END
			WHEN ad_table_id = 318 THEN 
				inva.all_currency_id 
			ELSE fa.c_currency_id 
		END AS All_Currency_ID,
		-- 
		CASE WHEN ad_table_id = 335 THEN
				CASE WHEN pay.c_charge_id IS NOT NULL THEN pay.dateacct ELSE paya.all_dateacct END
			WHEN ad_table_id = 318 THEN inva.all_dateacct ELSE NULL 
		END AS All_dateacct,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.c_charge_id IS NOT NULL THEN pay.datetrx ELSE paya.all_datetrx END 
			WHEN ad_table_id = 318 THEN inva.all_datetrx ELSE NULL 
		END AS All_datetrx,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.c_charge_id IS NOT NULL THEN pay.documentno ELSE paya.all_documentno END 
			WHEN ad_table_id = 318 THEN inva.all_documentno ELSE NULL 
		END AS All_DocumentNo,
		CASE WHEN ad_table_id = 335 THEN 
				CASE WHEN pay.c_charge_id IS NOT NULL THEN 
					COALESCE(doc_ttp.shortname ,doc_ttp.printname) 
				ELSE 
					paya.all_printname 
				END 
			WHEN ad_table_id = 318 THEN inva.all_printname ELSE NULL 
		END AS All_printname,
		CASE WHEN ad_table_id = 335 THEN paya.isseniatbook 
			WHEN ad_table_id = 318 THEN inva.isseniatbook ELSE NULL 
		END AS Inv_isSeniatBook,
		CASE WHEN ad_table_id = 335 THEN paya.all_description WHEN ad_table_id = 318 THEN inva.all_description ELSE NULL END AS All_description,
		CASE WHEN ad_table_id = 335 THEN paya.all_amount WHEN ad_table_id = 318 THEN inva.all_amount ELSE NULL END AS All_amount,
		CASE WHEN ad_table_id = 335 THEN paya.all_discountamt WHEN ad_table_id = 318 THEN inva.all_discountamt ELSE NULL END AS All_discountamt,
		CASE WHEN ad_table_id = 335 THEN paya.all_writeoffamt WHEN ad_table_id = 318 THEN inva.all_writeoffamt ELSE NULL END AS All_writeoffamt,
		CASE WHEN ad_table_id = 335 THEN paya.all_invoice_id WHEN ad_table_id = 318 THEN inva.all_invoice_id ELSE NULL END AS All_invoice_id,
		CASE WHEN ad_table_id = 335 THEN paya.inv_documentno WHEN ad_table_id = 318 THEN inva.inv_documentno ELSE NULL END AS Inv_DocumentNo,
		CASE WHEN ad_table_id = 335 THEN paya.inv_docbasetype WHEN ad_table_id = 318 THEN inva.inv_docbasetype ELSE NULL END AS Inv_docbasetype,
		CASE WHEN ad_table_id = 335 THEN paya.inv_currency_id WHEN ad_table_id = 318 THEN inva.inv_currency_id ELSE NULL END AS Inv_Currency_ID,
		CASE WHEN ad_table_id = 335 THEN paya.inv_conversiontype_id WHEN ad_table_id = 318 THEN inva.inv_conversiontype_id ELSE NULL END AS Inv_ConversionType_ID,
		CASE WHEN ad_table_id = 335 THEN paya.docsubtypewh WHEN ad_table_id = 318 THEN inva.docsubtypewh ELSE NULL END AS Inv_DocSubTypeWH,
		CASE WHEN ad_table_id = 335 THEN paya.inv_printname WHEN ad_table_id = 318 THEN inva.inv_printname ELSE NULL END AS Inv_printname,
		CASE WHEN ad_table_id = 335 THEN paya.inv_dateacct WHEN ad_table_id = 318 THEN inva.inv_dateacct ELSE NULL END AS Inv_dateacct,
		CASE WHEN ad_table_id = 335 THEN paya.inv_dateinvoiced WHEN ad_table_id = 318 THEN inva.inv_dateinvoiced ELSE NULL END AS Inv_dateinvoiced,
		CASE WHEN ad_table_id = 335 THEN paya.inv_grandtotal WHEN ad_table_id = 318 THEN inva.inv_grandtotal ELSE NULL END AS Inv_grandtotal,
		CASE WHEN ad_table_id = 335 THEN paya.all_payment_id WHEN ad_table_id = 318 THEN inva.all_payment_id ELSE NULL END AS All_payment_id,
		CASE WHEN ad_table_id = 335 THEN paya.pay_documentno WHEN ad_table_id = 318 THEN inva.pay_documentno ELSE NULL END AS Pay_documentno,
		CASE WHEN ad_table_id = 335 THEN paya.pay_dateacct WHEN ad_table_id = 318 THEN inva.pay_dateacct ELSE NULL END AS Pay_dateacct,
		CASE WHEN ad_table_id = 335 THEN paya.pay_datetrx WHEN ad_table_id = 318 THEN inva.pay_datetrx ELSE NULL END AS Pay_datetrx,
		CASE WHEN ad_table_id = 335 THEN paya.pay_currency_id WHEN ad_table_id = 318 THEN NULL ELSE NULL END AS Pay_Currency_ID,
		CASE WHEN ad_table_id = 335 THEN paya.pay_printname WHEN ad_table_id = 318 THEN inva.pay_printname ELSE NULL END AS Pay_printname,
		CASE WHEN ad_table_id = 335 THEN paya.pay_conversiontype_id WHEN ad_table_id = 318 THEN inva.pay_conversiontype_id ELSE NULL END AS Pay_ConversionType_ID,
		CASE WHEN ad_table_id = 335 THEN paya.pay_payamt WHEN ad_table_id = 318 THEN inva.pay_payamt ELSE NULL END AS Pay_PayAmt,
		CASE WHEN ad_table_id = 335 THEN paya.pay_datedeposit WHEN ad_table_id = 318 THEN inva.pay_datedeposit ELSE NULL END AS Pay_datedeposit,
		CASE WHEN ad_table_id = 335 THEN paya.pay_cha_name WHEN ad_table_id = 318 THEN inva.all_cha_name ELSE NULL END AS Cha_name,
		CASE WHEN ad_table_id = 335 THEN paya.all_charge_id WHEN ad_table_id = 318 THEN inva.all_charge_id ELSE NULL END AS All_charge_id
		--
	FROM ( 
		SELECT DISTINCT ON (c_bpartner_id, dateacct, ad_table_id, record_id)
		ad_client_id, ad_org_id, c_bpartner_id, dateacct, datetrx, ad_table_id, record_id, description, c_currency_id 
		FROM fact_acct
	) AS fa 
	-- Payments
	LEFT JOIN amf_c_payment_v4_v pay ON pay.c_payment_id = fa.record_id AND fa.ad_table_id = 335
	LEFT JOIN amf_c_payment_allocate_v paya ON paya.all_payment_id = pay.c_payment_id
	LEFT JOIN c_bankaccount baa ON baa.c_bankaccount_id = pay.c_bankaccount_id
	LEFT JOIN c_charge  cha  ON pay.c_charge_id = cha.c_charge_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='APP' ) AS  doc_tapp ON doc_tapp.ad_client_id= pay.ad_client_id
	LEFT JOIN ( SELECT ad_client_id, c_doctype_id, docbasetype FROM c_doctype WHERE docbasetype='ARR' ) AS  doc_tarr ON doc_tarr.ad_client_id= pay.ad_client_id
	LEFT JOIN c_doctype doc_tp ON pay.c_doctype_id = doc_tp.c_doctype_id
	LEFT JOIN c_doctype_trl doc_ttp ON doc_tp.c_doctype_id = doc_ttp.c_doctype_id AND doc_ttp.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=pay.AD_Client_ID)
	-- Invoices
	LEFT JOIN amf_c_invoice_v4_v inv ON inv.c_invoice_id = fa.record_id AND fa.ad_table_id = 318
	LEFT JOIN c_doctype doc_ti ON inv.c_doctype_id = doc_ti.c_doctype_id
	LEFT JOIN c_doctype_trl doc_tti ON doc_ti.c_doctype_id = doc_tti.c_doctype_id AND doc_tti.ad_language::text = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=inv.AD_Client_ID)
	LEFT JOIN amf_c_payment_allocate_v inva ON inva.all_invoice_id = inv.c_invoice_id 
	LEFT JOIN c_invoicepayschedule ips ON inv.c_invoice_id = ips.c_invoice_id
	LEFT JOIN c_paymentterm pay_t ON inv.c_paymentterm_id = pay_t.c_paymentterm_id
	-- BP Info
	LEFT JOIN (
		SELECT
		    C_BPartner_ID,
			ad_client_id,
			c_bp_group_id,
			c_bp_channel_id,
			salesrep_id,
			isCustomer,
			isVendor,
			isEmployee,
			Value as bp_value,
		    COALESCE(CASE WHEN  EXISTS( SELECT 1 FROM information_schema.columns 
		         WHERE table_name='c_bpartner' and column_name='amerp_nameseniat') THEN amerp_nameseniat 
			ELSE 'name' END, name,name2,'') as bp_name,
		    COALESCE(CASE WHEN  EXISTS( SELECT 1 FROM information_schema.columns 
		           WHERE table_name='c_bpartner' and column_name='amerp_rifseniat') THEN amerp_rifseniat 
			ELSE taxid END,taxid,'') as bp_taxid
		FROM  adempiere.C_BPartner
	) cbp ON (fa.c_bpartner_id = cbp.c_bpartner_id)
	-- Default BP Location
	LEFT JOIN ( 
		SELECT DISTINCT ON (c_bpartner_id) * FROM adempiere.c_bpartner_location as cbp_loc WHERE cbp_loc.isbillto='Y'
	) as cbp_l ON cbp.c_bpartner_id = cbp_l.c_bpartner_id  
	LEFT JOIN adempiere.c_location clc ON clc.c_location_id = cbp_l.c_location_id
	LEFT JOIN adempiere.c_region reg ON clc.c_region_id = reg.c_region_id
	LEFT JOIN adempiere.c_bp_group cbp_g ON cbp.c_bp_group_id = cbp_g.c_bp_group_id
	LEFT JOIN adempiere.c_bp_channel cbp_ch ON cbp.c_bp_channel_id = cbp_ch.c_bp_channel_id 
	LEFT JOIN adempiere.ad_user as cbp_us ON cbp.salesrep_id = cbp_us.ad_user_id
	LEFT JOIN ( 
		SELECT DISTINCT ON (c_bpartner_id) * FROM adempiere.ad_user
	) as cbp_us2 ON cbp.c_bpartner_id = cbp_us2.c_bpartner_id 
	-- Default Account Schema for Client
	LEFT JOIN (
		SELECT DISTINCT ON (ci.AD_Client_ID)
		ci.AD_Client_ID, sc.C_Currency_ID, ci.C_AcctSchema1_ID as C_AcctSchema_ID 
		FROM  AD_ClientInfo ci
		left join C_ACCTSchema sc on sc.c_acctschema_id  = ci.c_acctschema1_id 
	) as sch ON sch.AD_Client_ID = cbp.ad_client_id
	-- Account Element for BP on default Account Schema
	LEFT JOIN (
	 	SELECT 
		cbpac.C_Bpartner_ID, account_id as C_ElementValue_ID, cev.value, cev.name, cbpcu.c_acctschema_id
		FROM C_Bpartner cbpac
		LEFT JOIN C_BP_Customer_Acct cbpcu ON cbpcu.C_Bpartner_ID = cbpac.C_Bpartner_ID
		LEFT JOIN C_ValidCombination cvaco ON cvaco.C_ValidCombination_ID = cbpcu.c_receivable_acct
		LEFT JOIN C_ElementValue cev ON (cvaco.account_id = cev.C_ElementValue_ID) 
	) bpcev ON bpcev.C_Bpartner_ID = fa.c_bpartner_id  AND bpcev.C_AcctSchema_ID = sch.C_AcctSchema_ID
	LEFT JOIN c_currency cur ON fa.c_currency_id = cur.c_currency_id
	WHERE fa.ad_table_id IN (318,335)
	AND (pay.isallocated ='N' OR inv.ispaid ='N' )
) as bpst 
ORDER BY bprep, bpgroup, bpchannel, vpartner, dateacct, rn, ord, all_ord, documentno_p, datedoc_p, ord ;
ALTER TABLE adempiere.amf_bpstatement_v41 ;
  OWNER TO postgres;