	SELECT 
	--row_number() OVER ( ORDER BY arl.AD_Ref_List_ID) as tag_rn,
	prjtag.tag_rn,
	COALESCE(arl.value,'') as ERPTag_Value, 
	COALESCE(art.name,arl.name,'') as ERPTag_Name, 
	COALESCE(art.description,arl.description,'') as ERPTag_Description
	FROM AD_Reference are
	LEFT JOIN AD_Reference_Trl ret ON ret.AD_Reference_ID = are.AD_Reference_ID AND ret.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	LEFT JOIN AD_Ref_List arl ON arl.AD_Reference_ID = are.AD_Reference_ID
	LEFT JOIN AD_Ref_List_Trl art ON art.AD_Ref_List_ID = arl.AD_Ref_List_ID AND art.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID} )
	LEFT JOIN ( 
		select row_number() OVER ( ORDER BY erptag) as tag_rn,erptag
		from (
			select distinct on (cpl.erptag)
			cp.c_project_id, cpl.erptag as erptag
			from c_project cp 
			left join c_projectline cpl on cpl.c_project_id = cp.c_project_id 
			where cp.c_project_id = $P{C_Project_ID}
		) as prjtags
	) prjtag on prjtag.erptag = arl.value
	WHERE are.Name='ERPTag' and prjtag.tag_rn is not null