select * from (
	SELECT 
	count(*) as nroproc, api.ad_process_id, max(api.created), apr.value, apr.name, apr.jasperreport 
	FROM adempiere.ad_pinstance api
	left join adempiere.ad_process apr on apr.ad_process_id = api.ad_process_id 
	where apr.isreport ='Y'
	group by api.ad_process_id, apr.value, apr.name, apr.jasperreport 
) as procesos
order by nroproc desc 