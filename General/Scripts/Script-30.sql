select row_number() OVER ( ORDER BY erptag) as tag_rn,
case when erptag is null then 'ND' else erptag end as erptag
from (
	select distinct on (cpl.erptag)
	cp.c_project_id, cpl.erptag as erptag
	from c_project cp 
	left join c_projectline cpl on cpl.c_project_id = cp.c_project_id 
	where cp.issummary ='N'
) as prjtags
order by tag_rn