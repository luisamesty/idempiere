
select bps.*
	 FROM adempiere.amf_bpstatement_v4 as bps
	 LEFT JOIN c_bpartner bpa ON bpa.c_bpartner_id = bps.c_bpartner_id
	 -- Document Currency
	 LEFT JOIN c_currency curr1 on bps.c_currency_id = curr1.c_currency_id
	 LEFT JOIN c_currency_trl currt1 on curr1.c_currency_id = currt1.c_currency_id and currt1.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- User entered currency
	 LEFT JOIN c_currency curr2 on curr2.c_currency_id = $P{C_Currency_ID}
	 LEFT JOIN c_currency_trl currt2 on curr2.c_currency_id = currt2.c_currency_id and currt2.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- US$ Currency
	 LEFT JOIN C_Currency curr3 ON curr3.iso_code = 'USD' 
	 LEFT JOIN c_currency_trl currt3 on curr3.c_currency_id = currt3.c_currency_id and currt3.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	 -- Allocation Currency
	 LEFT JOIN c_currency curr4 on bps.all_currency_id = curr4.c_currency_id
	 LEFT JOIN c_currency_trl currt4 on curr4.c_currency_id = currt4.c_currency_id and currt4.ad_language = (SELECT AD_Language FROM AD_Client WHERE AD_Client_ID=$P{AD_Client_ID})
	WHERE CASE WHEN ( $P{AD_User_ID} IS NULL OR bps.ad_user_id = $P{AD_User_ID} )  THEN 1=1 ELSE 1=0 END
  		AND CASE WHEN ( $P{C_BPartner_ID} IS NULL OR bps.c_bpartner_id = $P{C_BPartner_ID} ) THEN 1=1 ELSE 1=0  END 
  		AND CASE WHEN ( $P{C_BP_Group_ID} IS NULL OR bps.c_bp_group_id = $P{C_BP_Group_ID} )  THEN 1=1 ELSE 1=0 END 
  		AND CASE WHEN ( $P{C_BP_Channel_ID} IS NULL OR bps.c_bp_channel_id = $P{C_BP_Channel_ID} ) THEN 1=1 ELSE 1=0  END
		AND CASE WHEN ( $P{BothPurchaseSales} = 'B' ) THEN 1 = 1
				WHEN ( $P{BothPurchaseSales} = 'S' AND bps.issotrx = 'Y' ) THEN 1 = 1
				WHEN ( $P{BothPurchaseSales} = 'P' AND bps.issotrx = 'N' ) THEN 1 = 1
				ELSE 1=0 END 
		AND ( bps.dateacct <= DATE( $P{DateEnd} ))