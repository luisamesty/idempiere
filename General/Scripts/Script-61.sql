SELECT 
org_name, org_description, org_taxid, org_logo, 
prj_value, prj_name, prj_plannedamt, prj_committedamt, 
pha_name, SUM(plin_amtplanned) AS pha_plannedamt, SUM(plin_amtcommitted) AS pha_committedamt,
CASE WHEN prj_plannedamt != 0 THEN CAST(100*(pha_committedamt/pha_plannedamt) as numeric) ELSE CAST(0 as numeric) END as PerPhaCommitAmt
FROM (
	SELECT DISTINCT
	-- ORGANIZATION
	concat(COALESCE(cli.name,cli.value),' - Consolidado') as org_name,
	concat(COALESCE(cli.description,cli.name),' - Consolidado')  as org_description, 
	COALESCE(orginfo.taxid,'') as org_taxid,
	img1.binarydata as org_logo,
	-- C_Project
	prj.c_project_id,
	prj.Value as prj_value,
	COALESCE(prj.name,'') as prj_name,
	COALESCE(prj.Description,'') as prj_description,
	COALESCE(prj.Note,'') as prj_note,
	COALESCE(prj.PlannedAmt,CAST(0 as numeric(10,2))) as prj_plannedamt,
	COALESCE(prj.CommittedAmt,CAST(0 as numeric(10,2))) as prj_committedamt,
	-- C_ProjectPhase
	case when prj.ProjectLineLevel = 'T' or prj.ProjectLineLevel = 'A' then LPAD(pha.SeqNO::text, 10, '0') else '' end as pha_seqNo,
	COALESCE(pha.name,'') as pha_name,
	COALESCE(pha.description,'') as pha_description,
	COALESCE(pha.PlannedAmt,CAST(0 as numeric(10,2))) as pha_plannedamt,
	COALESCE(pha.CommittedAmt,CAST(0 as numeric(10,2))) as pha_committedamt,
	-- C_ProjectTask
	case when prj.ProjectLineLevel = 'T' then LPAD(tas.SeqNO::text, 10, '0') else '' end as tas_seqNo,
	COALESCE(tas.name,'') as tas_name,
	COALESCE(tas.description,'') as tas_description,
	--  TASKS HAVEN'T Start And End Dates (phase dates indeed) 
	COAlESCE(tas.PlannedAmt,CAST(0 as numeric(10,2))) as tas_plannedamt,
	COALESCE(tas.CommittedAmt,CAST(0 as numeric(10,2))) as tas_committedamt,
	-- C_ProjectLine
	plin.c_projectline_id,
	LPAD(plin.Line::text, 10, '0') as lin_seqNo,
	COALESCE(plin.description,'') as lin_description,
	COALESCE(plin.Note,'') as lin_note,
	COALESCE(plin.NoteAdvance,'') as lin_NoteAdvance,
	COALESCE(plin.plannedqty,CAST(0 as numeric(10,2))) as plin_qtyplanned,
	COALESCE(plin.invoicedqty,CAST(0 as numeric(10,2))) as plin_qtyinvoiced,
	COALESCE(plin.committedqty,CAST(0 as numeric(10,2))) as plin_qtycommitted,
	COALESCE(plin.plannedprice,CAST(0 as numeric(10,2))) as plin_plannedprice,
	COALESCE(plin.plannedamt,CAST(0 as numeric(10,2))) as plin_amtplanned,
	COALESCE(plin.committedamt,CAST(0 as numeric(10,2))) as plin_amtcommitted,
	COALESCE(plin.invoicedamt,CAST(0 as numeric(10,2))) as plin_amtinvoiced,
	COALESCE(plin.plannedmarginamt,CAST(0 as numeric(10,2))) as plin_amtplannedmargin
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
) AS All_proj
GROUP BY org_name, org_description, org_taxid, org_logo, 
all_proj.prj_value, all_proj.prj_name, all_proj.prj_plannedamt, all_proj.prj_committedamt, 
all_proj.pha_name , pha_committedamt, pha_plannedamt
