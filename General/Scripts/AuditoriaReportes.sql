select  
coalesce(callsjr.no_calls_rep,0) as no_calls_rep,
coalesce(calls.no_calls_proc,0) as no_calls_proc, 
coalesce(to_char(last_date,'YYYY-MM-DD'),'NOT-USED') as last_date,
pr.jasperreport, pr.AD_Process_ID, pr.name 
from AD_Process pr
left join (
	select api.ad_process_id , 
	case when count(*) is not null then count(*) else  0 end as no_calls_proc
	from ad_pinstance api 
	group by api.ad_process_id 
--	order by no_calls_proc desc
) calls on calls.ad_process_id = pr.ad_process_id 
left join (
	select  apr.jasperreport ,
	case when count(*) is not null then count(*) else  0 end as no_calls_rep
	from ad_pinstance api 
	left join AD_Process apr on apr.ad_process_id = api.ad_process_id 
	where apr.jasperreport is not null
	group by apr.jasperreport
	order by no_calls_rep desc
) callsjr on callsjr.jasperreport = pr.jasperreport 
left join(
	select api.ad_process_id , 
	max(created) as last_date
	from ad_pinstance api 
	group by api.ad_process_id 
) ultimo on ultimo.ad_process_id = pr.ad_process_id
where pr.isreport ='Y' and pr.jasperreport is not null
and substr(lower(pr.jasperreport),1,19) ='attachment:bpartner'
order by no_calls_rep DESC