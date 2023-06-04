-- PROJECT TREE STRUCTURE
	WITH RECURSIVE Nodos AS (
	    SELECT TRN1.AD_Tree_ID,TRN1.Node_ID, 0 as level, TRN1.Parent_ID, 
		ARRAY [TRN1.Node_ID::text]  AS ancestry, 
		TRN1.Node_ID as Star_An
		FROM ad_treenode TRN1 
		WHERE TRN1.AD_tree_ID=(
			SELECT tree.AD_Tree_ID
			FROM AD_Client adcli
			LEFT JOIN C_AcctSchema accsh ON adcli.AD_Client_ID = accsh.AD_Client_ID
			LEFT JOIN C_AcctSchema_Element accee ON accee.C_AcctSchema_ID = accsh.C_AcctSchema_ID 
			LEFT JOIN AD_Tree tree ON tree.AD_Client_ID=adcli.AD_Client_ID AND tree.TreeType='PJ'
			WHERE accee.ElementType='PJ' AND accsh.C_AcctSchema_ID=$P{C_AcctSchema_ID}
		) 
		AND TRN1.isActive='Y' AND TRN1.Parent_ID = 0
	    UNION ALL
		SELECT TRN1.AD_Tree_ID, TRN1.Node_ID, TRN2.level+1 as level,TRN1.Parent_ID, 
		TRN2.ancestry || ARRAY[TRN1.Node_ID::text] AS ancestry,
		COALESCE(TRN2.Star_An,TRN1.Parent_ID) as Star_An
		FROM ad_treenode TRN1 
		INNER JOIN Nodos TRN2 ON (TRN2.node_id =TRN1.Parent_ID)
		WHERE TRN1.AD_tree_ID=(
			SELECT tree.AD_Tree_ID
			FROM AD_Client adcli
			LEFT JOIN C_AcctSchema accsh ON adcli.AD_Client_ID = accsh.AD_Client_ID
			LEFT JOIN C_AcctSchema_Element accee ON accee.C_AcctSchema_ID = accsh.C_AcctSchema_ID 
			LEFT JOIN AD_Tree tree ON tree.AD_Client_ID=adcli.AD_Client_ID AND tree.TreeType='PJ'
			WHERE accee.ElementType='PJ' AND accsh.C_AcctSchema_ID=$P{C_AcctSchema_ID}
		)  AND TRN1.isActive='Y' 
	) 
--	
SELECT 
-- ORGANIZATION
CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.name,cli.value),' - Consolidado') ELSE coalesce(org.name,org.value,'') END as org_name,
CASE WHEN $P{AD_Org_ID}= 0 THEN concat(COALESCE(cli.description,cli.name),' - Consolidado') ELSE COALESCE(org.description,org.name,org.value,'') END as org_description, 
COALESCE(orginfo.taxid,'') as org_taxid,
CASE WHEN $P{AD_Org_ID}= 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
-- C_Bpartner
COALESCE(cbp.value,'') as bpa_value,
COALESCE(cbp.name,'') as bpa_name,
-- PAR
PAR.Level, 
PAR.Node_ID, 
PAR.Parent_ID,
PAR.Star_An as START_ID,
PAR.ANCESTRY,
-- C_Project
PRJ.IsSummary,
repeat('     ',PAR.Level) || PRJ.NAME as name_indented,
--
prj.Value as prj_value,
COALESCE(prj.name,'') as prj_name,
COALESCE(prj.Description,'') as prj_description,
COALESCE(prj.Note,'') as prj_note,
CASE WHEN prj.DateContract IS NOT NULL THEN to_char(prj.DateContract,'YYYY-MM-DD')  ELSE '-' END AS DateContract,
CASE WHEN prj.DateContract IS NOT NULL THEN to_char(prj.DateFinish,'YYYY-MM-DD')  ELSE '-' END AS DateFinish,
COALESCE(prj.PlannedAmt,CAST(0 as numeric(10,2))) as prj_plannedamt,
COALESCE(prj.CommittedAmt,CAST(0 as numeric(10,2))) as prj_committedamt,
CASE WHEN  prj.plannedamt > 0 AND prj.committedamt > 0 THEN CAST(prj.committedamt / prj.plannedamt as numeric(10,2)) ELSE  0 END as prj_percentcommittedamt,
prj.ProjectLineLevel as prj_projectlinelevel,
-- C_ProjectPhase
case when prj.ProjectLineLevel = 'T' or prj.ProjectLineLevel = 'A' then LPAD(pha.SeqNO::text, 10, '0') else '' end as pha_seqNo,
COALESCE(pha.name,'') as pha_name,
COALESCE(pha.description,'') as pha_description,
COALESCE(pha.help,'') as pha_help,
CASE WHEN pha.StartDate IS NOT NULL THEN to_char(pha.StartDate,'YYYY-MM-DD')  ELSE '-' END  AS pha_startdate,
CASE WHEN pha.EndDate IS NOT NULL THEN to_char(pha.EndDate,'YYYY-MM-DD')  ELSE '-' END  AS pha_enddate,
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
CASE WHEN pha.StartDate IS NOT NULL THEN to_char(pha.StartDate,'YYYY-MM-DD')  ELSE '-' END  AS tas_startdate,
CASE WHEN pha.EndDate IS NOT NULL THEN to_char(pha.EndDate,'YYYY-MM-DD')  ELSE '-' END  AS tas_enddate,
COAlESCE(tas.PlannedAmt,CAST(0 as numeric(10,2))) as tas_plannedamt,
COALESCE(tas.CommittedAmt,CAST(0 as numeric(10,2))) as tas_committedamt,
CASE WHEN prj.PlannedAmt <> 0 AND  tas.PlannedAmt <> 0 THEN COALESCE(100*(tas.PlannedAmt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as tas_plannedpercent,
CASE WHEN prj.PlannedAmt <> 0 AND  tas.committedamt <> 0 THEN COALESCE(100*(tas.committedamt/prj.PlannedAmt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as tas_committedpercent,
CASE WHEN  tas.plannedamt > 0 AND tas.committedamt > 0 THEN CAST(100*(tas.committedamt / tas.plannedamt) as numeric(10,2)) ELSE  0 END as tas_percentcommittedamt,
-- C_ProjectLine
LPAD(plin.Line::text, 10, '0') as lin_seqNo,
COALESCE(plin.description,'') as lin_description,
COALESCE(plin.Note,'') as lin_note,
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
CASE WHEN prj.PlannedAmt <> 0 AND  plin.committedamt <> 0 THEN COALESCE(100*(plin.committedamt/prj.committedamt),CAST(0 as numeric(10,2))) ELSE  CAST(0 as numeric(10,2)) END as plin_committedpercent,
-- M_Product
COALESCE(prod.Value,'') as pro_value,
COALESCE(prod.Name,'') as pro_Name,
-- ERPTag_Reference
COALESCE(reflst.tag_rn,0) as tag_rn,
COALESCE(ErpTag_Refs.ERPTag_Ref_name,'Tag_name') as ERPTag_Ref_name,
COALESCE(ErpTag_Refs.ERPTag_Ref_description,'Tag_description') as ERPTag_Ref_description,
-- ERPTag
COALESCE(reflst.ERPTag_Value,'') as ERPTag_Value,
COALESCE(reflst.ERPTag_name,'') as ERPTag_name ,
COALESCE(reflst.ERPTag_description,'') as ERPTag_description,
-- ERPStageTag_Reference
COALESCE(reflst2.stagetag_rn,0) as stagetag_rn,
COALESCE(ErpTag_Refs.ERPStageTag_Ref_name,'StageTag_name') as ERPStageTag_Ref_name,
COALESCE(ErpTag_Refs.ERPStageTag_Ref_description,'StageTag_description') as ERPStageTag_Ref_description,
-- ERPStageTag
COALESCE(reflst2.ERPStageTag_Value,'') as ERPStageTag_Value,
COALESCE(reflst2.ERPStageTag_name,'') as ERPStageTag_name ,
COALESCE(reflst2.ERPStageTag_description,'') as ERPStageTag_description
FROM Nodos PAR
LEFT JOIN C_Project PRJ ON PRJ.C_Project_ID = PAR.NODE_ID
LEFT JOIN C_ProjectLine plin ON(plin.C_Project_ID = prj.C_Project_ID)
LEFT JOIN C_ProjectPhase pha ON (pha.C_ProjectPhase_ID =plin.C_ProjectPhase_ID )
LEFT JOIN C_ProjectTask tas ON (tas.C_ProjectTask_ID = plin.C_ProjectTask_ID)
LEFT JOIN C_Bpartner cbp ON prj.C_BPartner_ID = cbp.C_BPartner_ID
LEFT JOIN M_Product prod ON prod.M_Product_ID = plin.M_Product_ID
LEFT JOIN (
	SELECT 
	row_number() OVER ( ORDER BY arl.AD_Ref_List_ID) as tag_rn,
	COALESCE(arl.value,'') as ERPTag_Value, 
	COALESCE(art.name,arl.name,'') as ERPTag_Name, 
	COALESCE(art.description,arl.description,'') as ERPTag_Description
	FROM AD_Reference are
	LEFT JOIN AD_Reference_Trl ret ON ret.AD_Reference_ID = are.AD_Reference_ID AND ret.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	LEFT JOIN AD_Ref_List arl ON arl.AD_Reference_ID = are.AD_Reference_ID
	LEFT JOIN AD_Ref_List_Trl art ON art.AD_Ref_List_ID = arl.AD_Ref_List_ID AND art.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	WHERE are.Name='ERPTag'
) reflst ON reflst.ERPTag_Value = plin.ERPTag
LEFT JOIN (
	SELECT 
	row_number() OVER ( ORDER BY arl.AD_Ref_List_ID) as stagetag_rn,
	COALESCE(arl.value,'') as ERPStageTag_Value, 
	COALESCE(art.name,arl.name,'') as ERPStageTag_Name, 
	COALESCE(art.description,arl.description,'') as ERPStageTag_Description
	FROM AD_Reference are
	LEFT JOIN AD_Reference_Trl ret ON ret.AD_Reference_ID = are.AD_Reference_ID AND ret.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	LEFT JOIN AD_Ref_List arl ON arl.AD_Reference_ID = are.AD_Reference_ID
	LEFT JOIN AD_Ref_List_Trl art ON art.AD_Ref_List_ID = arl.AD_Ref_List_ID AND art.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	WHERE are.Name='ERPStageTag'
) reflst2 ON reflst2.ERPStageTag_Value = plin.ERPStageTag
LEFT JOIN (
	SELECT max(ERPTag_Ref_name) as ERPTag_Ref_name, max(ERPTag_Ref_description) as ERPTag_Ref_description, 
		max(ERPStageTag_Ref_name) as ERPStageTag_Ref_name, max(ERPStageTag_Ref_description) as ERPStageTag_Ref_description
	FROM (
		SELECT 
		case when are.Name='ERPTag' then COALESCE(ret.name,are.name) else '' end as ERPTag_Ref_name,
		case when are.Name='ERPTag' then COALESCE(ret.description,are.description) else '' end as ERPTag_Ref_description,
		case when are.Name='ERPStageTag' then COALESCE(ret.name,are.name) else '' end as ERPStageTag_Ref_name,
		case when are.Name='ERPStageTag' then COALESCE(ret.description,are.description) else '' end as ERPStageTag_Ref_description
		FROM AD_Reference are
		LEFT JOIN AD_Reference_Trl ret ON ret.AD_Reference_ID = are.AD_Reference_ID AND ret.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
		WHERE are.Name='ERPTag' or are.Name='ERPStageTag'
	) as ErpTags
) as ErpTag_Refs on 1 = 1
INNER JOIN ad_client as cli ON (prj.ad_client_id = cli.ad_client_id)
INNER JOIN ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
LEFT JOIN ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
INNER JOIN ad_org as org ON (prj.ad_org_id = org.ad_org_id)
INNER JOIN ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
LEFT JOIN ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
WHERE prj.AD_Client_ID = $P{AD_Client_ID} AND PRJ.IsSummary ='N'
 AND CASE WHEN ( $P{C_BPartner_ID} IS NULL OR prj.c_bpartner_id = $P{C_BPartner_ID} ) THEN 1=1 ELSE 1=0  END
 AND CASE WHEN ( $P{C_Project_ID} IS NULL OR PAR.ANCESTRY::text LIKE CONCAT('%',CAST($P{C_Project_ID} as text),'%')  )  THEN 1=1 ELSE 1=0 END
 AND CASE WHEN ( $P{isShowZERO} ='Y' OR ( $P{isShowZERO} ='N' AND  (prj.PlannedAmt <> 0 OR  prj.CommittedAmt <> 0 ) ) )  THEN 1=1 ELSE 1=0 END
ORDER BY PAR.ANCESTRY ASC , pha_seqNo ASC,  tas_SeqNO ASC, LPAD(plin.Line::text, 10, '0') ASC