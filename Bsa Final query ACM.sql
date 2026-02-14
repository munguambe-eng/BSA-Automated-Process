  SELECT [VALUE] as account
      ,right([RECID],16) as card_number
      ,left(right([RECID],8),7) as last_digits 
	  into #cardd
  FROM [RSVR_RAW_LAYER_REL].[ST].[CARD_ISSUE_MV] with (nolock)
  where [KEY]='ACCOUNT'



        SELECT [VALUE] as [ORDER.NIB]
                  ,[RECID]
				  into #ac_nib
              FROM [RSVR_RAW_LAYER_REL].[AC].[ACCOUNT_MV] with (nolock)
            where [KEY]='LOCAL.REF' and PARA_M ='61';


select
    clt.client_number [Numero Único do Cliente],
    op.account [Número do cartão],
    'CREDITO' [Tipo de Cartão],
    acc.settlement_iban [Numero de conta],
    [ORDER.NIB] as NIB,
    clt.fiscal_number [NUIT],
    clt.full_name [Nome do Titular],
    CASE
        WHEN op.fk_sgc_event_id = 'T001' THEN 'ATM'
  WHEN op.fk_sgc_event_id = 'T015' and  (prt.c025_pos_condition_code IN ('01','59') or prt_hold.c025_pos_condition_code IN ('01','59')) THEN 'E-COMMERCE'
  ELSE 'POS'        
    END as 'Tipo de Terminal',
    CASE
        WHEN tr.codpais = '508' THEN 'SIMO'
        WHEN tr.codpais is null THEN null
        ELSE 'VISA'
    END as 'Rede de Pagamento',
    cou.[Nome] 'Pais do Terminal',
    cur.code as 'Moeda da Transação',
    CAST(SUBSTRING(mft.c9999_ADITIONAL_DATA,14,11) AS FLOAT)/100 as 'Montante em moeda estrangeira',
    tr.amount 'Montante em moeda Nacional',
    CONVERT(char(10), tr.date_value, 120) AS 'Data da operação',
    CONVERT(char(10), CONVERT(date, tr.data), 120) AS 'Data da liquidação'
from
    [RSVRRealtime_ACM_DB].[dbo].sgc_account_transaction tr
     join [RSVRRealtime_ACM_DB].[dbo].sgc_transaction_log_operation op on op.uuid = tr.transaction_log_operation_uuid
    left join [RSVRRealtime_ACM_DB].[dbo].acm_account acc on acc.account_number = op.account
    left join [RSVRRealtime_ACM_DB].[dbo].acm_client_contract con on con.fk_acm_contract_id = acc.fk_acm_contract_id
    left join [RSVRRealtime_ACM_DB].[dbo].acm_client clt on clt.id = con.fk_acm_client_id
    left join [RSVRRealtime_ACM_DB].[dbo].acm_country_table_iso3166 coun with(nolock) on coun.numeric_code = op.country_code
    left join [RSVRRealtime_ACM_DB].[dbo].acm_currency curr with(nolock) on curr.numeric_code = tr.original_currency_code
    left join [RSVRRealtime_ACM_DB].[dbo].acm_event ev with(nolock) on ev.uuid = op.fk_sgc_event_id
    left join [RSVRRealtime_ACM_DB].[dbo].acm_simo_iso8583_prt prt on prt.uuid = op.fk_sgc_ref_system_uuid
left join  [RSVRRealtime_ACM_DB].[dbo].acm_mft_simo_edst_tipreg1_V00 mft on op.fk_sgc_ref_system_uuid=mft.fk_acm_mft_uuid and op.fk_sgc_mft_line_uuid=mft.line_number
left join [RSVRRealtime_ACM_DB].[dbo].acm_simo_iso8583_prt prt_hold on  mft.rrn_calculated = prt_hold.c037_retrieval_reference_number  and mft.hash_pan = prt_hold.c002_hash_pan
  left JOIN #ac_nib ac_nib on ac_nib.RECID=acc.settlement_iban
    JOIN [RSVRBatch_ReferenceData].[dbo].[COUNTRY] cou with (nolock) on cou.[CODE ISO]=coun.numeric_code
      left join (select distinct [Number],code  from [RSVRBatch_ReferenceData].[dbo].[CURRENCY] with (nolock)) cur  on [Number]=SUBSTRING(mft.c9999_ADITIONAL_DATA,2,3)
     where op.country_code <> '508'  
and is_hold= 0 
and fk_sgc_accounting_type_id='movement'
     order by op.create_date desc;
