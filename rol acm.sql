

declare @date_ DATE;
SELECT @date_= max(system_date)  from  [RSVRRealtime_ACM_CORE].[dbo].acmc_credit_system_day_status ;
drop table if exists #cusmvv
drop table if exists #customer
drop table if exists #addressT
drop table if exists #cus
drop table if exists #customer_db
-- if adress null use branch name


select
  recid,
  [value] address1 into #addressT
from
  rsvr_raw_layer_rel.st.customer_mv with (nolock)
where
  LOCAL_REF_DESC = 'Street'
  and para_m = 2;

select
  recid,
  local_ref_desc,
  [value] into #cusmvv
from
  rsvr_raw_layer_rel.st.customer_mv with (nolock)
where
  local_ref_desc in(
    'LOCALIDADE',
    'REGISTO',
    'CONSERVATORIA',
    'EMAIL.1',
    'COMPANY REGISTRATION NUMBER',
    'NAME.1',
    'PHONE.1',
    'TOWN.COUNTRY',
    'SHORT.NAME',
    'TAX.ID',
    'POSTAL.ADDRESS.1',
    'STREET',
    'PLACE.BIRTH',
    'MOTHERS NAME',
    'OCCUPATION',
    'E - MAIL.ADDRESS',
    'COUNTRY',
    'COUNTRY OF ISSUE',
    'LEGAL.ID',
    'SMS.1',
    'LEGAL.HOLDER.NAME',
    'LEGAL.ISS.DATE',
    'LEGAL.EXP.DATE',
    'EMPLOYERS.NAME',
    'EMPLOYERS.ADD',
    'LEGAL.ID.DOC.NAME',
    'LEGAL.DOC.NAME',
    'POSTAL ADDRESS COUNTRY',
    'NUIB do Cliente',
    'DIRECTORS CUSTOMER NUMBER'
  ) create index idx_ref_value_recid on #cusmvv (recid,local_ref_desc) include ([value]);

select
  recid,
  min(
    case
      when local_ref_desc = 'LOCALIDADE' then [value]
    end
  ) as 'LOCALIDADE',
  min(
    case
      when local_ref_desc = 'REGISTO' then [value]
    end
  ) as 'REGISTO',
  min(
    case
      when local_ref_desc = 'CONSERVATORIA' then [value]
    end
  ) as 'CONSERVATORIA',
  min(
    case
      when local_ref_desc = 'EMAIL.1' then [value]
    end
  ) as 'EMAIL.1',
  min(
    case
      when local_ref_desc = 'COMPANY REGISTRATION NUMBER' then [value]
    end
  ) as 'COMPANY REGISTRATION NUMBER',
  min(
    case
      when local_ref_desc = 'NAME.1' then [value]
    end
  ) as 'NAME.1',
  min(
    case
      when local_ref_desc = 'PHONE.1' then [value]
    end
  ) as 'PHONE.1',
  min(
    case
      when local_ref_desc = 'TOWN.COUNTRY' then [value]
    end
  ) as 'TOWN.COUNTRY',
  min(
    case
      when local_ref_desc = 'SHORT.NAME' then [value]
    end
  ) as 'SHORT.NAME',
  min(
    case
      when local_ref_desc = 'TAX.ID' then [value]
    end
  ) as 'TAX.ID',
  min(
    case
      when local_ref_desc = 'POSTAL.ADDRESS.1' then [value]
    end
  ) as 'POSTAL.ADDRESS.1',
  min(
    case
      when local_ref_desc = 'STREET' then [value]
    end
  ) as 'STREET',
  min(
    case
      when local_ref_desc = 'PLACE.BIRTH' then [value]
    end
  ) as 'PLACE.BIRTH',
  min(
    case
      when local_ref_desc = 'MOTHERS NAME' then [value]
    end
  ) as 'MOTHERS NAME',
  min(
    case
      when local_ref_desc = 'OCCUPATION' then [value]
    end
  ) as 'OCCUPATION',
  min(
    case
      when local_ref_desc = 'E - MAIL.ADDRESS' then [value]
    end
  ) as 'E - MAIL.ADDRESS',
  min(
    case
      when local_ref_desc = 'COUNTRY' then [value]
    end
  ) as 'COUNTRY',
  min(
    case
      when local_ref_desc = 'COUNTRY OF ISSUE' then [value]
    end
  ) as 'COUNTRY OF ISSUE',
  min(
    case
      when local_ref_desc = 'LEGAL.ID' then [value]
    end
  ) as 'LEGAL.ID',
  min(
    case
      when local_ref_desc = 'SMS.1' then [value]
    end
  ) as 'SMS.1',
  min(
    case
      when local_ref_desc = 'LEGAL.HOLDER.NAME' then [value]
    end
  ) as 'LEGAL.HOLDER.NAME',
  min(
    case
      when local_ref_desc = 'LEGAL.ISS.DATE' then [value]
    end
  ) as 'LEGAL.ISS.DATE',
  min(
    case
      when local_ref_desc = 'LEGAL.EXP.DATE' then [value]
    end
  ) as 'LEGAL.EXP.DATE',
  min(
    case
      when local_ref_desc = 'EMPLOYERS.NAME' then [value]
    end
  ) as 'EMPLOYERS.NAME',
  min(
    case
      when local_ref_desc = 'EMPLOYERS.ADD' then [value]
    end
  ) as 'EMPLOYERS.ADD',
  min(
    case
      when local_ref_desc = 'LEGAL.ID.DOC.NAME' then [value]
    end
  ) as 'LEGAL.ID.DOC.NAME',
  min(
    case
      when local_ref_desc = 'LEGAL.DOC.NAME' then [value]
    end
  ) as 'LEGAL.DOC.NAME',
  min(
    case
      when local_ref_desc = 'POSTAL ADDRESS COUNTRY' then [value]
    end
  ) as 'POSTAL ADDRESS COUNTRY',
  min(
    case
      when local_ref_desc = 'NUIB do Cliente' then [value]
    end
  ) as 'NUIB do Cliente',
  min(
    case
      when local_ref_desc = 'CLIENTE.PEP' then [value]
    end
  ) as 'CLIENTE.PEP',
  min(
    case
      when local_ref_desc = 'DIRECTORS CUSTOMER NUMBER' then [value]
    end
  ) as 'DIRECTORS CUSTOMER NUMBER' 
  into #customer
from
  #cusmvv
group by
  recid
select
  recid,
  [target],
  INDUSTRY,
  NATIONALITY,
  BIRTH_INCORP_DATE,
  GENDER,
  RESIDENCE,
  sector,
  account_officer into #cus
from
  RSVR_RAW_LAYER_REL.ST.CUSTOMER with (nolock); -- create index idx_recid on #cus (recid) ;
  -- create index idx_recid on #customer (recid) ;


with 
 customer_db as (
SELECT
distinct 
  cast(C.RECID as varchar) as cus_n,
  cast(case
    when [NUIB do Cliente] is null then c.Recid
    else [NUIB do Cliente]
  end as varchar) as 'client_number',
  isnull(CT.[NAME.1],'') as  cus_full_name,
  cast(C.TARGET as varchar) as cus_target,
  case
    when c.target IN (
      '2211',
      '2230',
      '2224',
      '2223',
      '2233',
      '2234',
      '2237',
      '2235',
      '2236',
      '2222',
      '2232',
      '2212',
      '2231',
      '2221'
    ) then 'P'
    else 'E'
  end as 'cus_type',
  isnull(CT.[SHORT.NAME],'') as  CUS_short_name,
  isnull(cast(C.INDUSTRY as varchar),'') as   CUS_Industry ,
  isnull(cast(COALESCE (CT.[LEGAL.ID], CT.[LEGAL.ID.DOC.NAME], '999999A') as varchar),'') AS CUS_ID_N,
  case
    when CT.[LEGAL.DOC.NAME] = 2 then 'B'
    when CT.[LEGAL.DOC.NAME] = 1 then 'C'
   when CT.[LEGAL.DOC.NAME] = 11 then 'A' 
    else '-'
  end as 'id_type',
  isnull(DOC.VALUE,'') as 'id_comment',
  isnull(cast(coalesce(
    try_convert(varchar, CT.[PHONE.1]),
    try_convert(varchar, CT.[SMS.1])
  ) as varchar),'') as cus_tel_no1,
  isnull(cast(coalesce(nullif(CT.[TAX.ID], ''), '99999') as varchar),'') as cus_nuit,
  concat(
    address1,
    coalesce(
      CT.[STREET],
      CT.[POSTAL.ADDRESS.1],
      [Company]
    )
  ) as cus_address_1,
  coalesce(
    coalesce(
      CT.[COUNTRY OF ISSUE],
      CT.[POSTAL ADDRESS COUNTRY]
    ),
    'MZ'
  ) as cus_country_c,
  isnull(CT.[EMAIL.1],'') as cus_email_1_1,
  coalesce(
    coalesce(
      C.NATIONALITY,
      CT.[COUNTRY OF ISSUE],
      CT.[POSTAL ADDRESS COUNTRY]
    ),
    'MZ'
  ) as cus_nationality,
  -- case
  -- when C.GENDER = 'FEMALE' then 'F'
  -- when C.GENDER = 'MALE' then 'M'
  --end as 
  coalesce(nullif(left(C.GENDER, 1), ''), '-') cus_gender,
  isnull(CT.[MOTHERS NAME],'') as CUS_Mothers_Name,
  coalesce(nullif(CT.OCCUPATION, ''), 'Funcionario') as PROF_desc,
  coalesce(nullif(CT.OCCUPATION, ''), 'Funcionario') as Cus_occupation,
  COALESCE(CT.[PLACE.BIRTH], 'Not Present') as CUS_Place_Birth,
  format(
    try_convert(
      date,
case
        when COALESCE(C.BIRTH_INCORP_DATE, '1990-01-01') = '1111-01-01' then '1990-01-01'
        else COALESCE(C.BIRTH_INCORP_DATE, '1990-01-01')
      end
    ),
    'yyyy-MM-ddTHH:mm:ss.fff'
  ) as cus_dob,
  coalesce(CT.[TOWN.COUNTRY], '-') as cus_town,
  format(
    try_convert(
      date,
case
        when COALESCE(CT.[LEGAL.ISS.DATE], '1990-01-01') = '1111-01-01' then '1990-01-01'
        else COALESCE(CT.[LEGAL.ISS.DATE], '1990-01-01')
      end
    ),
    'yyyy-MM-ddTHH:mm:ss.fff'
  ) as cus_legal_doc_issue_dte,
  format(
    try_convert(
      date,
case
        when COALESCE(CT.[LEGAL.EXP.DATE], '2099-01-01') = '1111-01-01' then '2099-01-01'
        else COALESCE(CT.[LEGAL.EXP.DATE], '2099-01-01')
      end
    ),
    'yyyy-MM-ddTHH:mm:ss.fff'
  ) as cus_legal_doc_exp_dte,
  case when 
   c.target not IN (
      '2211',
      '2230',
      '2224',
      '2223',
      '2233',
      '2234',
      '2237',
      '2235',
      '2236',
      '2222',
      '2232',
      '2212',
      '2231',
      '2221'
    ) then '' else 
  coalesce(nullif(CT.[EMPLOYERS.NAME], ''), '') end as cus_employer_name,
  case when
   c.target not IN (
      '2211',
      '2230',
      '2224',
      '2223',
      '2233',
      '2234',
      '2237',
      '2235',
      '2236',
      '2222',
      '2232',
      '2212',
      '2231',
      '2221'
    ) then '' else 
  isnull(CT.[EMPLOYERS.ADD],[COMPANY]) end as cus_employer_address,
    CASE 
             WHEN TARGET LIKE '9999' THEN 'NO ACCOUNT'
             WHEN TARGET LIKE '9998' THEN 'JOINT CUSTOMER'
             WHEN TARGET LIKE '9997' THEN 'BANK CUSTOMER'
             WHEN TARGET LIKE '2211' THEN 'PB HNI'
             WHEN TARGET LIKE '2230' THEN 'PB HNI'
             WHEN TARGET LIKE '2237' THEN 'PB HNI'
             WHEN TARGET LIKE '2240' THEN 'PB HNI'
             WHEN TARGET LIKE '22%' THEN 'PB'
             WHEN TARGET LIKE '21%' THEN 'BB'  
             WHEN TARGET LIKE '12%' THEN 'CIB'
             WHEN TARGET LIKE '11%' THEN 'CIB'
       ELSE 'OTHER' 
       END AS SEGMENT,
  C.RESIDENCE as residence_country,
  -- incorporation if null remove from schemma
  cast(CT.[COMPANY REGISTRATION NUMBER] as varchar) as incorporation_number,
  case
    when CT.[CLIENTE.PEP] is null then 'N'
    else 'Y'
  end as Cus_PEP,
  bal.[RECID],
  bal.[PREFIX],
  isnull(bal.[INSTITUTION],'') INSTITUTION,
  isnull(cast(bal.[NIB] as varchar),'') NIB,
  isnull(cast(bal.[IBAN] as varchar),'') IBAN,
  isnull(cast(bal.[CUSTOMER] as varchar),'') as CUSTOMER,
  isnull(bal.[CURRENCY],'') as CURRENCY,
  coalesce(bal.[WORKING_BALANCE], 0) as Working_balance,
  isnull(bal.[CURR_NO],0) as [CURR_NO],
  isnull(format(try_convert(date,bal.[OPENING_DATE]),'yyyy-MM-ddTHH:mm:ss.fff'),'') as  [OPENING_DATE],
  isnull(bal.[BusinessDate],'') as  [BusinessDate],
  isnull(bal.[INSERT_DATE],'') as [INSERT_DATE],
  isnull(cast([DIRECTORS CUSTOMER NUMBER] as varchar),'') director_number ,
  Company,
  branch.bch,
  ind.*,
  SEC.*,
  ACCOUNT_OFFICER,
  ACT.NAME AS OFFICER_NAME,
  gsm, 
  sg.*,
  [location]

FROM
  #customer CT with (nolock)
  LEFT JOIN #cus C with (nolock) ON C.RECID = CT.RECID
  --where c.[TARGET] like '22%'
  LEFT JOIN (
    SELECT
      RECID,
      [VALUE]
    FROM
      rsvr_raw_layer_rel.LOCALTABLE.F_BSTM_DOCUMENT_MV
    where
      [KEY] = 'DESCRIPTION'
      and PARA_M = 2
  ) DOC ON DOC.RECID = CT.[LEGAL.DOC.NAME]
  left join #addressT att with (nolock) on att.RECID=c.recid
  left join [RSVRDP_GIFIM].[dbo].[AccountWorkingBalance] bal on bal.[customer] = ct.recid
  left join ( select  [value] as  gsm, recid  as conta from rsvr_raw_layer_rel.ac.account_mv  
 where  [key]='Local.ref' and para_m='78' ) 
 gsm on gsm.conta=bal.recid

  left join (
   
 select

      co.MNEMONIC,
      right(co.recid, 3) bch,
      co_mv.*
    from
     [rsvr_raw_layer_rel].MC.COMPANY co
      JOIN 
   (
     
select
  recid,

  min(
    case
      when [KEY] = 'COMPANY.NAME' then [value]
    end
  ) as 'Company',
  min(
    case
      when [KEY] = 'NAME.ADDRESS' and para_m='3' then [value]
    end
  ) as 'Location'
from [rsvr_raw_layer_rel].MC.COMPANY_mv
group by
  recid)
   co_mv on co.recid = co_mv.recid
  ) as branch on branch.MNEMONIC = bal.prefix
  left join (
    SELECT RECID RECID_IND, [VALUE] AS INDUSTRY_NAME
  FROM [RSVR_RAW_LAYER_REL].[ST].[iNDUSTRY_MV]
  WHERE CONCAT([KEY],[PARA_M])='DESCRIPTION' 
  ) as ind on ind.recid_IND=c.industry
  LEFT JOIN ( 
    SELECT RECID RECID_SEC, [VALUE] AS SECTOR_name
  FROM [RSVR_RAW_LAYER_REL].[ST].[SECTOR_MV]
  WHERE CONCAT([KEY],[PARA_M])='DESCRIPTION' 
  ) SEC ON SEC.RECID_SEC=SECTOR
  LEFT JOIN [RSVR_RAW_LAYER_REL].[ST].[DEPT_ACCT_OFFICER] ACT ON ACT.RECID=ACCOUNT_OFFICER 
  left join( select [value] as segment_descr, recid as segment_code from rsvr_raw_layer_rel.st.target_mv with (nolock) WHERE [key] ='DESCRIPTION' ) sg on sg.segment_code=C.TARGET)

select  distinct
left(Company,3) as [BRANCH],
right(company,len(company)-4) as [BRANCH_NAME],
[Location] as [BRANCH_LOCATION],
cus_n as [CUSTOMER],
concat(left(Company,3),cus.recid) as [CONTRACT],
cus_full_name as [NAME],
[SEGMENT],
'CREDIT CARD' as [PRODUCT],
case when cus_gender='M' then 'Male' when cus_gender='F' then 'Female' end as [GENDER],
case when gsm is not  null then gsm else '' end as [WPB_CODE],
cus_employer_name as [EMPLOYER],
'' as [GROUP_CUSTOMER],
cus_nuit as [NUIT],
case when cus_pep = 'N' then 'NAO' else 'SIM' end as [PEP],
'' as [EXPORTADOR],
'' as [ENT_CORRELACIONADA],
cus_industry as [INDUSTRY_ID],
industry_name as [INDUSTRY],
sector_name as [BM_SECTORS],
currency as [CONTRACT_CCY] ,
CREDIT_LIMIT as [LIMIT],
current_debt as [BALANCE_FCY],
current_debt as [BALANCE_LCY],
case when days_in_arreas is null then '0' else days_in_arreas end as [NO_OF_DAYS],
case when days_in_arreas is null then '0' else days_in_arreas end as [MAXIMUM_DAYS],
CASE WHEN days_in_arreas  = '0' or days_in_arreas is null then '0 DAYS'
WHEN days_in_arreas between 1 and 30 then '30 DAYS'
WHEN days_in_arreas between 31 and 60 then '60 DAYS'
WHEN days_in_arreas between 61 and 90 then '90 DAYS'
WHEN days_in_arreas >90 then 'NPL' END AS 
[BUCKET],
[ACCRUED_INTEREST],
'' [INTEREST_IN_SUSP],
case when [PD_CAPITAL] is null then '' else cast(pd_capital as varchar) end as PD_CAPITAL,
case when [PD_INTEREST] is null then '' else cast(PD_interest as varchar)  end AS PD_INTEREST,
cast(cd.expiration_date  as date) as [EXPIRY_DATE],
convert(date,contract_create_date,103)  as [STARTING_DATE],
 case when datediff(year, convert(date,contract_create_date,103),cast(cd.expiration_date  as date))<1 then 'Ate 1 Ano'
 when datediff(year, convert(date,contract_create_date,103),cast(cd.expiration_date  as date)) >1 and datediff(year, convert(date,contract_create_date,103),cast(cd.expiration_date  as date)) <=5 then 'Ate 5 Anos' 
 when datediff(year, convert(date,contract_create_date,103),cast(cd.expiration_date  as date))>5 then 'Mais de 5 Anos' end as [MATURITY],
'FIXED_RATE' AS [INDEXER],
'' as [SPREAD],
interest_value as [INTEREST_RATE],
payment_option as [INSTALLMENT_LCY],
'' as [CONTRACT_TYPE],
'' as [FREQUENCY],
'12' as [TERM],
'55 Days' as [DEFERMENT],
ACCOUNT_OFFICER as [OFFICER_ID],
OFFICER_NAME as [OFFICER_NAME],
card_account as [PRODUCT_ID],
product [PRODUCT_DESC],
cus_target as [SEGMENT_ID],
segment_descr [SEGMENT_DESC],
'' as [RISK_GRADE],
'' as [CLASSE_RISCO],
'' as [RISK],
'' as [BASEL_II],
'' as [RESTRUCTURED],
'' as [RESTRUCTURED_DATE],
system_date as [BUSINESS_DATE],
'1' as [RATES],
'ON BOOK'[BOOK],
'TAXA FIXA' [UPDATED_INDEXER]


 from  [RSVRRealtime_ACM_CORE].[dbo].acmc_credit_system_day_status acm
 join customer_db cus on cus.recid=acm.debit_account
 left join [RSVRRealtime_ACM_DB].[dbo].acm_client cus1 on cus1.client_number=acm.client_number
 left join [RSVRRealtime_ACM_DB].[dbo].[batch_acm_card] cd on cd.fk_acm_client_id=cus1.id

 
 where system_date =@date_

 







     