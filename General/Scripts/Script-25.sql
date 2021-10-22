-- Entrega 531517 M_InOut_ID=1034585
update m_transaction set movementdate ='2021-01-21'
where m_transaction_id in (select m_transaction_id from M_Transaction 
where M_InOutLine_ID in (select M_InOutLine_ID from m_inoutline mi where mi.M_InOut_ID=1034585)) ;

-- Entrega 531521 M_InOut_ID=1034589
update m_transaction set movementdate ='2021-01-21'
where m_transaction_id in (select m_transaction_id from M_Transaction 
where M_InOutLine_ID in (select M_InOutLine_ID from m_inoutline mi where mi.M_InOut_ID=1034589)) ;

-- Reverso 531659 (Entrega 53151)  M_InOut_ID=1034750
update m_transaction set movementdate ='2021-01-21'
where m_transaction_id in (select m_transaction_id from M_Transaction 
where M_InOutLine_ID in (select M_InOutLine_ID from m_inoutline mi where mi.M_InOut_ID=1034750)) ;

-- Reverso 531923 (Entrega 531517) M_inOut_ID = 1035022
update m_transaction set movementdate ='2021-01-21'
where m_transaction_id in (select m_transaction_id from M_Transaction 
where M_InOutLine_ID in (select M_InOutLine_ID from m_inoutline mi where mi.M_InOut_ID=1035022)) ;