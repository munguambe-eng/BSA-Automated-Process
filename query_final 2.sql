-- uPDATED 2025-11-19
-- DETAILS OF THE UPDATE, INCLUDED THE CONDITION TO RETURN CARDS WHEN ITS A REFUND. CASE WHEN TRANSACTION_TYPE='acf4' THEN CREDIT_ACCT_NO ELSE dEBIT_ACCT_NO.
-- updated 2025-11-21 
-- Details of the update, replaced the transaction


drop table if exists #masterr;

  drop table if exists #transactions_final;
  
  drop table if exists #CUSTOMER;
  
  drop table if exists #ac_nib;
    drop table if exists #cardd;
   with mas as (
SELECT mas.[BCM_ACCOUNT_NO]
          ,[BCM_DDA_ACCOUNT_NUMBER]+'|' as [BCM_DDA_ACCOUNT_NUMBER]
          ,[BCM_ASSOC_ACCOUNT_NUMBER]+'|' as BCM_ASSOC_ACCOUNT_NUMBER
          ,[BCM_CARDHOLDER_NBR]
          ,[BCM_CONSOL_CARD_ACCT_TYPE]
      FROM [RSVRBatch_P1C].[P1C].[P1CMozambiquePCMaster] mas with (nolock)
      JOIN (
      select [BCM_ACCOUNT_NO]
          ,max([RSVRBusinessDate]) as max_date
      FROM [RSVRBatch_P1C].[P1C].[P1CMozambiquePCMaster] with (nolock)
      group by [BCM_ACCOUNT_NO]
      ) ma on mas.BCM_ACCOUNT_NO=ma.BCM_ACCOUNT_NO and mas.RSVRBusinessDate=ma.max_date
) select * into #masterr from mas;
with transactions as (
    select
        prefix pref,
        recid reci,
        debit_amount,
		debit_value_date,
        processing_date,
        DEBIT_ACCT_NO,
        Debit_Currency,
        loc_amt_debited,
        TREASURY_RATE,
        CREDIT_CURRENCY,
		DEBIT_THEIR_REF,
		DEBIT_CUSTOMER,
		[TRANSACTION_TYPE],
		[Credit_customer],
        right(amount_credited, len(amount_Credited) -3) AMOUNT_CREDITED,
        credit_acct_no
       
    from
        rsvr_raw_layer_rel.ft.FUNDS_TRANSFER_HIS fts with (nolock) 
		    where
        processing_date  {0}
		and RECORD_STATUS='MAT'
),
full_fl as (
    select
        *
    from
         rsvr_raw_layer_rel.ft.FUNDS_TRANSFER_MV_HIS  mv with (nolock)
        join transactions tr on tr.reci = mv.recid
        and tr.pref = mv.prefix
    where
        LOCAL_REF_DESC in (
            'CODPAIS',
            'LOCK.EVENT.ID',
            'PAYMENT.DETAILS',
            'CODMOEDA',
            'Cambio',
            'IMPORTOP',
			'INPUT.VERSION'
        )
),
ft_final as (
   
            select
                *
            from
                (
                    select
                        RECID as ftid,
                        [VALUE] as VAL,
                        prefix,
                        LOCAL_REF_DESC
                    from
                        full_fl
                ) as c pivot (
                    MAX(VAL) For Local_ref_desc in (
                       [CODPAIS],
					   [LOCK.EVENT.ID],
					    [PAYMENT.DETAILS],
						[CODMOEDA],
						[Cambio],
						[IMPORTOP],
						[INPUT.VERSION]
                    )
                ) as pivotT
		WHERE [INPUT.VERSION] IN ('FUNDS.TRANSFER,POS.ACF2','FUNDS.TRANSFER,ATM.ACF0') and ([CODPAIS] IS NOT NULL OR [CODPAIS] <>'508')
	
)
,
transactions_final as (
select *  from ft_final ft
join transactions tr on tr.reci=ftid and tr.pref=ft.prefix where [CODPAIS] <> '508'
) select * into #transactions_final from transactions_final;

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

with
cus as (
		
      SELECT 
      [VALUE],
      [RECID],
	  [local_ref_desc]
      FROM [rsvr_raw_layer_rel].[st].[customer_mv] as cmv1 with (nolock)
      
		WHERE [LOCAL_REF_DESC] in ('TAX.ID','NAME.1','NUIB do Cliente') 

)
,CUSTOMER AS (
  select
                *
            from
                (
                    select
                        RECID as RECID,
                        [VALUE] as VAL,
                        [local_ref_desc]
                    from
                        CUS
                ) as c pivot (
                    MAX(VAL) For [local_ref_desc] in (
                       [TAX.ID],[NAME.1],[NUIB do Cliente]
                    )
                ) as pivotT
)


select * into #customer from customer;

SELECT distinct 
ft.reci ft,
[NUIB do Cliente]
    --    case when TRANSACTION_TYPE='ACF4' then [Credit_customer] else  DEBIT_CUSTOMER end as 'Numero Único do Cliente'
      ,cards.card_number+'' as 'Número do cartão'
      ,'Debito' as 'Tipo de Cartão'
      ,case 
      when transaction_type ='ACF4' then [CredIT_ACCT_NO]
      else [DEBIT_ACCT_NO] end as 'Numero de conta'
      ,convert(varchar,ac_nib.[ORDER.NIB])+'' as 'NIB'
      ,cus.[TAX.ID] as 'Nuit'
      ,cus.[NAME.1] as 'Nome do Titular'
      ,case when [TRANSACTION_TYPE] in ('ACF0','ACF1','ACF5') then 'ATM'
            when (ft.DEBIT_THEIR_REF like '%SKRILL%' or ft.DEBIT_THEIR_REF like '%INTERNET%' or
            ft.DEBIT_THEIR_REF like '%HTTP%' or ft.DEBIT_THEIR_REF like '%g.co/%' or
            ft.DEBIT_THEIR_REF like '%fb.me%' or ft.DEBIT_THEIR_REF like '%FACEBK%' or
            ft.DEBIT_THEIR_REF like '%.EU%' or ft.DEBIT_THEIR_REF like '%.NET%' or
            ft.DEBIT_THEIR_REF like '%WWW%' or ft.DEBIT_THEIR_REF like '%db.tt%' or
            ft.DEBIT_THEIR_REF like '%.COM%' or ft.DEBIT_THEIR_REF like '%PAYPAL%' or
            ft.DEBIT_THEIR_REF like '%GOOGLE%' or ft.DEBIT_THEIR_REF like '%Audible%' or
            ft.DEBIT_THEIR_REF like '%ALIEXPRESS%' or ft.DEBIT_THEIR_REF like '%Kindle%' or
            ft.DEBIT_THEIR_REF like '%NETFLIX%' or ft.DEBIT_THEIR_REF like '%APPLE%' or
            ft.DEBIT_THEIR_REF like '%Airlink%' or ft.DEBIT_THEIR_REF like '%AMZN%' or
            ft.DEBIT_THEIR_REF like '%ZOOM%' or ft.DEBIT_THEIR_REF like '%eBay%' or
            ft.DEBIT_THEIR_REF like '%Alibaba%' or ft.DEBIT_THEIR_REF like '%WorldVentures%' or
            ft.DEBIT_THEIR_REF like '%ONLINE%') then 'INTERNET'
            else 'POS' end as 'Tipo de terminal',
            ft.DEBIT_THEIR_REF as 'Detalhe de Terminal'
      ,'VISA' as 'Rede de Pagamento'
      ,cou.[NOME] as 'País do terminal'
      --,lkmv.[LOCAL.REF14] 
      ,cur.code as 'Moeda da Transação' 
      ,
      ft.[IMPORTOP] AS  'Montante em moeda estrangeira'   
      ,
      0 AS 'montante em usd'

      ,case when transaction_type='ACF4' then convert(decimal(15,2),0-convert(decimal(15,2),replace(ft.LOC_AMT_DEBITED,',','.')))
      else convert(decimal(15,2),ft.LOC_AMT_DEBITED) end  as 'Montante em moeda Nacional'
      ,cast(DEBIT_VALUE_DATE as date) as 'Data da operação'
      ,cast(PROCESSING_DATE as date) as 'Data da liquidação'
  FROM 
  #transactions_final ft


  left JOIN #CUSTOMER cus on cus.RECID=case when ft.transaction_type='ACF4' then ft.Credit_customer else ft.DEBIT_CUSTOMER end
  left JOIN #ac_nib ac_nib on ac_nib.RECID=case when ft.transaction_type='ACF4' then ft.Credit_acct_no else ft.DEBIT_ACCT_NO  end
  LEFT JOIN #cardd cards on cards.last_digits=case when len([PAYMENT.DETAILS])>7 then left(right([PAYMENT.DETAILS],8),7) else [PAYMENT.DETAILS] end  and account=case when ft.transaction_type='ACF4' then CREDIT_ACCT_NO ELSE  DEBIT_ACCT_NO END
  JOIN [RSVRBatch_ReferenceData].[dbo].[COUNTRY] cou with (nolock) on cou.[CODE ISO]=ft.[CODPAIS]
  left join (select distinct [Number],code  from [RSVRBatch_ReferenceData].[dbo].[CURRENCY] with (nolock)) cur  on [Number]=ft.[CODMOEDA]

  Union all

SELECT '' as ft,
[NUIB do Cliente],
-- ac.CUSTOMER
      convert(varchar,[PIR_ACCOUNT])+'' as PIR_ACCOUNT
      ,case when left([PIR_ACCOUNT],6)='438897' then 'Pre-Pago' else 'Credito' end as Card_type
      ,right(ac.RECID,13) as Account
      ,convert(varchar,ac_nib.[ORDER.NIB])+'' as Nib
      ,cus.[TAX.ID] as Nuit
      ,cus.[NAME.1] as Customer_name
      ,case when (PIR_MERCHANT_NAME like '%SKRILL%' or PIR_MERCHANT_NAME like '%INTERNET%' or
            PIR_MERCHANT_NAME like '%HTTP%' or PIR_MERCHANT_NAME like '%g.co/%' or
            PIR_MERCHANT_NAME like '%fb.me%' or PIR_MERCHANT_NAME like '%FACEBK%' or
            PIR_MERCHANT_NAME like '%.EU%' or PIR_MERCHANT_NAME like '%.NET%' or
            PIR_MERCHANT_NAME like '%WWW%' or PIR_MERCHANT_NAME like '%db.tt%' or
            PIR_MERCHANT_NAME like '%.COM%' or PIR_MERCHANT_NAME like '%PAYPAL%' or
            PIR_MERCHANT_NAME like '%GOOGLE%' or PIR_MERCHANT_NAME like '%Audible%' or
            PIR_MERCHANT_NAME like '%ALIEXPRESS%' or PIR_MERCHANT_NAME like '%Kindle%' or
            PIR_MERCHANT_NAME like '%NETFLIX%' or PIR_MERCHANT_NAME like '%APPLE%' or
            PIR_MERCHANT_NAME like '%Airlink%' or PIR_MERCHANT_NAME like '%AMZN%' or
            PIR_MERCHANT_NAME like '%ZOOM%' or PIR_MERCHANT_NAME like '%eBay%' or
            PIR_MERCHANT_NAME like '%Alibaba%' or PIR_MERCHANT_NAME like '%WorldVentures%' or
            PIR_MERCHANT_NAME like '%ONLINE%') then 'INTERNET'
            when [PIR_TRANS_CODE]='005' then 'POS' 
            when [PIR_TRANS_CODE]='005' then 'ATM' else 'ATM' end as Terminal_Type,
            PIR_MERCHANT_NAME as 'detalhe do terminal'
      ,'VISA' as 'Rede de Pagamento'
      ,cou.[NOME]
      ,cur.[Code]
      ,convert(decimal(15,2),[PIR_ORIG_TRANS_AMT]/100) as FCY_Amount,
       0 as 'Montante em USD'
      ,case when cur.[Code]='MZN' then convert(decimal(15,2),[PIR_AMT]) else  case when [PIR_TRANS_CODE]='006' then convert(decimal(15,2),[PIR_DEST_TRANS_AMT]/100*-1) else convert(decimal(15,2),[PIR_DEST_TRANS_AMT]/100) end end as LCY_Amount
      ,cast([PIR_PURCH_DT] as date)
      ,cast([PIR_POST_DT] as date)
  FROM [RSVRBatch_P1C].[P1C].[P1CMozambiquePCPSTIR] stir with (nolock)
  left  JOIN #masterr mas with (nolock) on mas.BCM_ACCOUNT_NO=[PIR_ACCOUNT]
  left JOIN [RSVR_RAW_LAYER_REL].[AC].[ACCOUNT] ac with (nolock) on ac.RECID+'|'=right([BCM_DDA_ACCOUNT_NUMBER],14)
  left JOIN #ac_nib ac_nib with (nolock) on ac_nib.RECID=left(right([BCM_DDA_ACCOUNT_NUMBER],14),13)    
  left  JOIN #customer cus with (nolock) on cus.RECID=ac.CUSTOMER
  JOIN [RSVRBatch_ReferenceData].[dbo].[COUNTRY] cou with (nolock) on stir.PIR_MERCHANT_COUNTRY_CODE=cou.[CODE_2]
  JOIN (
  SELECT [Code]
      ,[Number]
  FROM [RSVRBatch_ReferenceData].[dbo].[CURRENCY]
  group by [Code]
      ,[Number]
  ) as cur on stir.[PIR_ORIG_CURR_CODE]=cur.[Number]
  where [PIR_MERCHANT_COUNTRY_CODE]<>'MZ' and 
  [PIR_TRANS_CODE] in ('005','006','007') and [PIR_POST_DT]   {1}
   and
  [PIR_ORIG_TRANS_AMT]<>'0.00'

  union all


  select 
  lg.ft_reference as ft,
  [NUIB do Cliente],
--   cif [Numero Único do Cliente],
    lg.Card_pan [Número do cartão],
    'pre-pago' [Tipo de Cartão],
    account [Numero de conta],
    [ORDER.NIB] [NIB],
    [TAX.ID]  [NUIT],
    holder_name [Nome do Titular],
    
  case when lg.terminal_type ='A' then 'ATM Local'
  
  when lg.terminal_type ='B' then 'POS local'
  when lg.terminal_type ='C' then 'ATM abroad'
  
   when lg.terminal_type ='D' then 'POS abroad'
   
   when lg.terminal_type ='I' then 'Internet'
   
   when lg.terminal_type ='M' then 'Mobile'
   
   when lg.terminal_type ='N' then 'NA'
   end as 'Tipo de Terminal',
   [DESCRIPTION] as 'detalhe do terminal',
  
   CASE
        WHEN [origin_entity] = 'p' THEN 'SIMO'
        WHEN [origin_entity] = 's' then 'VISA'
    END as 'Rede de Pagamento',
    cou.nome 'Pais do Terminal',
    cur.code as 'Moeda da Transação',
    ORIGINAL_COUNTRY_TRANSACTION_AMOUNT as 'Montante em moeda estrangeira',
     0 as 'Montante em USD',
    TRANSACTION_AMOUNT 'Montante em moeda Nacional',
    debit_value_date 'Data da operação',
    processing_date AS 'Data da liquidação'

FROM


 [RSVR_RAW_LAYER_REL].[EB].[PPC_BCTA_MESSAGE_LOG] lg 
   join rsvr_raw_layer_rel.ft.funds_transfer_his ft on left(ft.recid,12)=lg.ft_reference and ft.prefix='S96'
  join rsvrrealtime_prepaid_cards.[dbo].[card] crd on crd.card_number=lg.card_pan
  join #customer cus on cus.recid=cif
  join #ac_nib nib on nib.recid=account
   JOIN [RSVRBatch_ReferenceData].[dbo].[COUNTRY] cou with (nolock) on cou.[CODE ISO]=country_code
      left join (select distinct [Number],code  from [RSVRBatch_ReferenceData].[dbo].[CURRENCY] with (nolock)) cur  on [Number]=currency_code
  
  WHERE processing_date  {2}
  and lg.Transaction_type='01'
  and country_code <>'508'

  union all 

  
select
op.document_number as ft,
[NUIB do Cliente],
    -- clt.client_number [Numero Único do Cliente],
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
    prt.c043_card_acceptor_name_location_1_owner as 'detalhe do terminal',
    CASE
        WHEN tr.codpais = '508' THEN 'SIMO'
        WHEN tr.codpais is null THEN null
        ELSE 'VISA'
    END as 'Rede de Pagamento',
    cou.[Nome] 'Pais do Terminal',
    cur.code as 'Moeda da Transação',
    CAST(SUBSTRING(mft.c9999_ADITIONAL_DATA,14,11) AS FLOAT)/100 as 'Montante em moeda estrangeira',
    0 as 'Montante em USD',
    tr.amount 'Montante em moeda Nacional',
    CONVERT(char(10), tr.date_value, 120) AS 'Data da operação',
    CONVERT(char(10), CONVERT(date, tr.create_date), 120) AS 'Data da liquidação'
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
left join   [RSVRRealtime_ACM_DB].[dbo].acm_mft_simo_edst_tipreg1_V00 mft on op.fk_sgc_ref_system_uuid=mft.fk_acm_mft_uuid and op.fk_sgc_mft_line_uuid=mft.line_number
left join [RSVRRealtime_ACM_DB].[dbo].acm_simo_iso8583_prt prt_hold on  mft.rrn_calculated = prt_hold.c037_retrieval_reference_number  and mft.hash_pan = prt_hold.c002_hash_pan
  left JOIN #ac_nib ac_nib on ac_nib.RECID=acc.settlement_iban
    join #customer cus on cus.recid= clt.client_number

    JOIN [RSVRBatch_ReferenceData].[dbo].[COUNTRY] cou with (nolock) on cou.[CODE ISO]=coun.numeric_code
      left join (select distinct [Number],code  from [RSVRBatch_ReferenceData].[dbo].[CURRENCY] with (nolock)) cur  on [Number]=SUBSTRING(mft.c9999_ADITIONAL_DATA,2,3)
     where op.country_code <> '508'  
and is_hold= 0 
and fk_sgc_accounting_type_id='movement'
and CONVERT(char(10), CONVERT(date, tr.create_date), 120)   {3}
