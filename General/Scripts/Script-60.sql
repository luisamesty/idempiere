SELECT 
-- ORGANIZATION
CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.name,cli.value),' - Consolidado') ELSE coalesce(org.name,org.value,'') END as org_name,
CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.description,cli.name),' - Consolidado') ELSE COALESCE(org.description,org.name,org.value,'') END as org_description, 
COALESCE(orginfo.taxid,'') as org_taxid,
CASE WHEN $P{AD_Org_ID}= 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
-- C_Project
prj.c_project_id,
prj.Value as prj_value,
COALESCE(prj.name,'') as prj_name,
COALESCE(prj.Description,'') as prj_description,
COALESCE(prj.Note,'') as prj_note,
COALESCE(prj.PlannedAmt,CAST(0 as numeric(10,2))) as prj_plannedamt,
COALESCE(prj.CommittedAmt,CAST(0 as numeric(10,2))) as prj_committedamt,
CASE WHEN  prj.plannedamt > 0 AND prj.committedamt > 0 THEN CAST(prj.committedamt / prj.plannedamt as numeric(10,2)) ELSE  0 END as prj_percentcommittedamt,
prj.ProjectLineLevel as prj_projectlinelevel,
-- C_ProjectPhase
case when prj.ProjectLineLevel = 'T' or prj.ProjectLineLevel = 'A' then LPAD(pha.SeqNO::text, 10, '0') else '' end as pha_seqNo,
COALESCE(pha.name,'') as pha_name,
COALESCE(pha.description,'') as pha_description,
COALESCE(pha.help,'') as pha_help,
COALESCE(pha.PlannedAmt,CAST(0 as numeric(10,2))) as pha_plannedamt,
COALESCE(pha.CommittedAmt,CAST(0 as numeric(10,2))) as pha_committedamt,
CASE WHEN prj.PlannedAmt <> 0 AND  pha.PlannedAmt <> 0 THEN COALESCE(100*(pha.PlannedAmt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as pha_plannedpercent,
CASE WHEN prj.PlannedAmt <> 0 AND  pha.committedamt <> 0 THEN COALESCE(100*(pha.committedamt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as pha_committedpercent,
CASE WHEN  pha.plannedamt > 0 AND pha.committedamt > 0 THEN CAST(100*(pha.committedamt / pha.plannedamt) as numeric(10,2)) ELSE  0 END as pha_percentcommittedamt,
-- C_ProjectTask
case when prj.ProjectLineLevel = 'T' then LPAD(tas.SeqNO::text, 10, '0') else '' end as tas_seqNo,
COALESCE(tas.name,'') as tas_name,
COALESCE(tas.description,'') as tas_description,
COALESCE(tas.help,'') as tas_help,
--  TASKS HAVEN'T Start And End Dates (phase dates indeed) 
COAlESCE(tas.PlannedAmt,CAST(0 as numeric(10,2))) as tas_plannedamt,
COALESCE(tas.CommittedAmt,CAST(0 as numeric(10,2))) as tas_committedamt,
CASE WHEN prj.PlannedAmt <> 0 AND  tas.PlannedAmt <> 0 THEN COALESCE(100*(tas.PlannedAmt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as tas_plannedpercent,
CASE WHEN prj.PlannedAmt <> 0 AND  tas.committedamt <> 0 THEN COALESCE(100*(tas.committedamt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as tas_committedpercent,
CASE WHEN  tas.plannedamt > 0 AND tas.committedamt > 0 THEN CAST(100*(tas.committedamt / tas.plannedamt) as numeric(10,2)) ELSE  0 END as tas_percentcommittedamt,
-- C_ProjectLine
plin.c_projectline_id,
LPAD(plin.Line::text, 10, '0') as lin_seqNo,
COALESCE(plin.description,'') as lin_description,
COALESCE(plin.Note,'') as lin_note,
COALESCE(plin.NoteAdvance,'') as lin_NoteAdvance,
ROW_NUMBER () OVER ( PARTITION BY prj.C_Project_ID ORDER BY CONCAT(prj.Value,LPAD(pha.seqno::text, 10, '0'),LPAD(tas.seqno::text, 10, '0'),LPAD(plin.Line::text, 10, '0'))) as prj_nolin,
ROW_NUMBER () OVER ( PARTITION BY pha.C_ProjectPhase_ID ORDER BY CONCAT(prj.Value,LPAD(pha.seqno::text, 10, '0'),LPAD(tas.seqno::text, 10, '0'))) as pha_nolin,
ROW_NUMBER () OVER ( PARTITION BY tas.C_ProjectTask_ID ORDER BY CONCAT(prj.Value,LPAD(pha.seqno::text, 10, '0'),LPAD(tas.seqno::text, 10, '0'),LPAD(plin.Line::text, 10, '0'))) as tas_nolin,
ROW_NUMBER () OVER ( PARTITION BY plin.C_ProjectLine_ID ORDER BY CONCAT(prj.Value,LPAD(pha.seqno::text, 10, '0'),LPAD(tas.seqno::text, 10, '0'),LPAD(plin.Line::text, 10, '0'))) as lin_nolin,
COALESCE(plin.plannedqty,CAST(0 as numeric(10,2))) as plin_qtyplanned,
COALESCE(plin.invoicedqty,CAST(0 as numeric(10,2))) as plin_qtyinvoiced,
COALESCE(plin.committedqty,CAST(0 as numeric(10,2))) as plin_qtycommitted,
COALESCE(plin.plannedprice,CAST(0 as numeric(10,2))) as plin_plannedprice,
COALESCE(plin.plannedamt,CAST(0 as numeric(10,2))) as plin_amtplanned,
COALESCE(plin.committedamt,CAST(0 as numeric(10,2))) as plin_amtcommitted,
COALESCE(plin.invoicedamt,CAST(0 as numeric(10,2))) as plin_amtinvoiced,
COALESCE(plin.plannedmarginamt,CAST(0 as numeric(10,2))) as plin_amtplannedmargin,
CASE WHEN  plin.plannedamt > 0 AND plin.committedamt > 0 THEN CAST(100*(plin.committedamt / plin.plannedamt) as numeric(10,2)) ELSE  0 END as plin_percentcommittedamt,
CASE WHEN  plin.plannedamt > 0 AND plin.invoicedamt > 0 THEN CAST(100*(plin.invoicedamt / plin.plannedamt) as numeric(10,2)) ELSE  0 END as plin_percentinvoicedamt, 
CASE WHEN  plin.plannedqty > 0 AND plin.committedqty > 0 THEN CAST(100*(plin.committedqty / plin.plannedqty) as numeric(10,2)) ELSE  0 END as plin_percentcommittedqty,
CASE WHEN  plin.plannedqty > 0 AND plin.invoicedqty > 0 THEN CAST(100*(plin.invoicedqty / plin.plannedqty) as numeric(10,2)) ELSE  0 END as plin_percentinvoicedqty, 
CASE WHEN prj.PlannedAmt <> 0 AND  plin.PlannedAmt <> 0 THEN COALESCE(100*(plin.PlannedAmt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as plin_plannedpercent,
CASE WHEN prj.PlannedAmt <> 0 AND  plin.committedamt <> 0 THEN COALESCE(100*(plin.committedamt/prj.committedamt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as plin_committedpercent
FROM C_project prj
LEFT JOIN C_ProjectLine plin ON(plin.C_Project_ID = prj.C_Project_ID)
LEFT JOIN C_ProjectPhase pha ON (pha.C_ProjectPhase_ID =plin.C_ProjectPhase_ID )
LEFT JOIN C_ProjectTask tas ON (tas.C_ProjectTask_ID = plin.C_ProjectTask_ID)
INNER JOIN ad_client as cli ON (prj.ad_client_id = cli.ad_client_id)
INNER JOIN ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
LEFT JOIN ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
INNER JOIN ad_org as org ON (prj.ad_org_id = org.ad_org_id)
INNER JOIN ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
LEFT JOIN ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
WHERE prj.C_Project_ID = $P{C_Project_ID}
ORDER BY prj.Value ASC , pha_seqNo ASC,  tas_SeqNO ASC, LPAD(plin.Line::text, 10, '0') ASC