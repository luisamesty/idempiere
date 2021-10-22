select
rqu.r_status_id, rqu.documentno, rqu.name, sta."name" 
FROM R_Request rqu
LEFT JOIN R_RequestType rqt ON (rqu.R_RequestType_ID =rqt.R_RequestType_ID)
left join R_StatusCategory stc on (stc.r_statuscategory_id = rqt.R_StatusCategory_ID )
LEFT JOIN R_Status sta ON (sta.R_Status_ID=rqu.R_Status_ID )
WHERE rqu.AD_Client_ID = $P{AD_Client_ID} 
		AND rqu.StartDate BETWEEN  $P{StartDate} AND $P{EndDate}
		order by rqu.documentno