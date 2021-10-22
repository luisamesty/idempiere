delete from amn_payroll_detail apd 
where apd.amn_payroll_id in (select amn_payroll_id 
from amn_payroll ap
where  AMN_Period_ID=1000961)