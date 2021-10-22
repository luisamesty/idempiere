select mo.documentno ,mt.m_transaction_id, mt.M_InOutLine_ID, mt.movementdate , Date_part('day',mt.created - mt.movementdate) as days 
from M_Transaction mt
left join M_InOutLine mi on mi.m_inoutline_id =mt.m_inoutline_id 
left join M_InOut mo on mo.m_inout_id =mi.m_inout_id 
--where M_InOutLine_ID in (select M_InOutLine_ID from m_inoutline mi where mi.M_InOut_ID=1034585)
where Date_part('day',mt.created - mt.movementdate) > 300 and mt.created >= '2020-01-01'