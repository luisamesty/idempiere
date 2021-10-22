SELECT *
FROM
	(SELECT DISTINCT
   -- ORGANIZATION
      org.ad_client_id as org_client, org.ad_org_id as org_org,
	  CASE WHEN $P{AD_Org_ID} = 0 THEN concat(COALESCE(cli.name,cli.value),' - Consolidado') ELSE coalesce(org.name,org.value,'') END as org_name,
	  CASE WHEN $P{AD_Org_ID}  = 0 THEN concat(COALESCE(cli.description,cli.name),' - Consolidado') ELSE COALESCE(org.description,org.name,org.value,'') END as org_description, 
	  CASE WHEN $P{AD_Org_ID}  = 0 THEN '' ELSE COALESCE(orginfo.taxid,'') END as org_taxid,
	  CASE WHEN $P{AD_Org_ID}  = 0 THEN img1.binarydata ELSE img2.binarydata END as org_logo,
	  CASE WHEN  org.ad_client_id = $P{AD_Client_ID}   AND $P{AD_Org_ID}  = 0 THEN 1
	             WHEN  org.ad_client_id = $P{AD_Client_ID}  AND org.ad_org_id= $P{AD_Org_ID}  THEN 1
	             ELSE 0 
	  END as imp_org
   FROM adempiere.ad_org as org
	 INNER JOIN adempiere.ad_client as cli ON (org.ad_client_id = cli.ad_client_id)
	 INNER JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
	  LEFT JOIN adempiere.ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
	 INNER JOIN adempiere.ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
	  LEFT JOIN adempiere.ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
  ) as org_inf
FULL JOIN
(
	SELECT 
  -- ORGANIZATION
	rqu.AD_Client_ID as client_id,
	rqu.AD_org_ID as org_id,
     CASE WHEN ( $P{AD_Org_ID} != 0 AND rqu.ad_org_id = $P{AD_Org_ID} ) THEN 1 
          WHEN ( $P{AD_Org_ID} = 0  ) THEN 2 
	      ELSE 0 
	 END AS imp_org_int,
	-- R_Request
	rqu.R_Request_ID as R_Request_ID,
	rqu.DocumentNo as Req_DocumentNo,
	rqu.Name as Req_Name,
	rqu.Summary as Req_Summary,
	rqu.ConfidentialType as Req_ConfidentialType,
	rqu.Priority,
	rqu.PriorityUser,
	rqu.StartDate as Req_StartDate,
	to_char(CAST(rqu.StartDate as TimeStamp),'DD-MM-YYYY') AS Req_InitialDate,
	rqu.StartTime as Req_StartTime,
	to_char(CAST(rqu.StartTime as TimeStamp),'HH:MM:SS') AS Req_InitialTime,
	-- R_RequestType
	rqu.R_RequestType_ID as R_RequestType_ID,
	rqt.Name as ReqTy_Name,
	COALESCE(rqt.Description,'') as ReqTy_Description,
	-- R_Group
	CASE WHEN rqu.R_Group_ID IS NULL THEN 1000000 ELSE  rqu.R_Group_ID END as R_Group_ID,
	CASE WHEN rqu.R_Group_ID IS NULL THEN COALESCE(gru.Name,'') ELSE 'Grupo sin definir' END as ReqGr_Name,
	COALESCE(gru.Description,'') as ReqGr_Description,
	-- R_Category
	rqu.R_Category_ID as R_Category_ID,
	cat.Name as ReqCat_Name,
	cat.Description as ReqCat_Description,
	-- R_Status_ID
	rqu.R_Status_ID as R_Status_ID,
	cat.Name as ReqSta_Value,
	sta.SeqNo as ReqSta_SeqNo,
	sta.Name as ReqSta_Name,
	sta.Description as ReqSta_Description,
	sta.isopen, sta.isclosed, sta.isfinalclose, sta.isactive,
	-- Request Update
	rqupd.R_RequestUpdate_ID as R_RequestUpdateID,
	coalesce(to_char(rqupd.Created,'DD-MM-YYYY') ,'') as ReqUpd_Created,
	coalesce(rqupd.Created,rqu.StartDate) as  ReqUpd_DatimeCreated,
	coalesce(rqupd.CreatedBy,0) as ReqUpd_CreatedBy,
	coalesce(rqupd.result,'') as ReqUpd_Result,
	coalesce(usr.Name,'') as ReqUpd_UserName
	FROM R_Request rqu
	LEFT JOIN R_RequestType rqt ON (rqu.R_RequestType_ID =rqt.R_RequestType_ID)
	left join R_StatusCategory stc on (stc.r_statuscategory_id = rqt.R_StatusCategory_ID )
	LEFT JOIN R_Status sta ON (sta.R_Status_ID=rqu.R_Status_ID )
	LEFT JOIN R_Category cat on (cat.R_Category_ID = rqu.r_category_id)
	LEFT JOIN R_Group gru ON (gru.R_Group_ID = rqu.R_Group_ID)
	LEFT JOIN R_RequestUpdate rqupd ON (rqu.R_Request_ID =rqupd.R_Request_ID)
	LEFT JOIN AD_User as usr ON (usr.AD_User_ID =  rqupd.CreatedBy )
	INNER JOIN adempiere.ad_client as cli ON (rqu.ad_client_id = cli.ad_client_id)
	INNER JOIN adempiere.ad_clientinfo as cliinfo ON (cli.ad_client_id = cliinfo.ad_client_id)
	LEFT JOIN adempiere.ad_image as img1 ON (cliinfo.logoreport_id = img1.ad_image_id)
	INNER JOIN adempiere.ad_org as org ON (rqu.ad_org_id = org.ad_org_id)
	INNER JOIN adempiere.ad_orginfo as orginfo ON (org.ad_org_id = orginfo.ad_org_id)
	LEFT JOIN adempiere.ad_image as img2 ON (orginfo.logo_id = img2.ad_image_id)
	WHERE rqu.AD_Client_ID = $P{AD_Client_ID} 
		AND rqu.StartDate BETWEEN  $P{StartDate} AND $P{EndDate}
		and case when $P{isOpen} = 'X' or  sta.isopen = $P{isOpen} then 1=1 else 1=0 END
		and case when $P{isClosed} = 'X' or  sta.isclosed = $P{isClosed} then 1=1 else 1=0 END
		and case when $P{isFinalClose} = 'X' or  sta.isfinalclose = $P{isFinalClose} then 1=1 else 1=0 END
	) as reqst ON (1= 0)
WHERE (imp_org= 1) 
   OR (client_id= $P{AD_Client_ID} AND CASE WHEN imp_org_int= 2 THEN 1=1 
                                            WHEN imp_org_int= 1 THEN imp_org_int = 1
										    ELSE org_id= $P{AD_Org_ID} 
									   END
	)
ORDER BY reqst.r_request_id, reqst.ReqTy_Name, reqst.ReqSta_SeqNo, reqst. Req_StartDate, reqst.ReqUpd_DatimeCreated