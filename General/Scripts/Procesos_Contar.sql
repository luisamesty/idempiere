	select api.ad_process_id , 
	case when count(*) is not null then count(*) else  0 end as no_calls
	from ad_pinstance api 
	group by api.ad_process_id 
	order by no_calls asc