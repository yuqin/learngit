----借款订单
#创建一张一月底订单表
drop table if exists default.jyq_comapss_stat_20180228;
create table default.jyq_comapss_stat_20180228
as
select uid,
       ord_no as order_no,
       prc_amt as principle,
       stg_num as stage,
       ord_stt as status_1,
       case when ord_stt ='LENDING' then 1 
       when ord_stt ='EXCEED' then 2
       when ord_stt ='PAY_OFF' then 3 end as status_id,
       ovd_stt as exceed_status,
       ovd_day as exceed_day,
       crt_tim as created_at,
       lst_rep_tim as updated_at,
       from_unixtime(unix_timestamp(),'yyyy-MM-dd') as day 
from dbank.loan_f_order_info 
where day='2018-02-28'
      and (bsy_typ ='' or bsy_typ='BALANCE_TRANSFER')
      and ord_stt in ('EXCEED','LENDING','PAY_OFF');

#这个是所有的借款订单-订单表
#抽数的时间很重要
drop table if exists default.jyq_comapss_stat;
create table default.jyq_comapss_stat
as
select uid,
       ord_no as order_no,
       prc_amt as principle,
       stg_num as stage,
       ord_stt as status_1,
       case when ord_stt ='LENDING' then 1 
       when ord_stt ='EXCEED' then 2
       when ord_stt ='PAY_OFF' then 3 end as status_id,
       ovd_stt as exceed_status,
       ovd_day as exceed_day,
       crt_tim as created_at,
       lst_rep_tim as updated_at,
       from_unixtime(unix_timestamp(),'yyyy-MM-dd') as day 
from dbank.loan_f_order_info 
where day='2018-10-01'
      and (bsy_typ ='' or bsy_typ='BALANCE_TRANSFER')
      and ord_stt in ('EXCEED','LENDING','PAY_OFF');


---1月还清客户订单状态---注意这里还是by订单的
drop table if exists default.jyq_comapss_stat3_201802;
create table default.jyq_comapss_stat3_201802
as
select a.*,
       b.up,
       b.down,
       case when created_at <down and updated_at <= down then 3
       when created_at < down and updated_at >down then 1
       when created_at >=down then 2 end as reloan_status 
from default.jyq_comapss_stat as a
join (
      select a.uid,max(a.rep_tim) as down,min(a.crt_dte) as up
      from      
      (select uid,max(updated_at) as rep_tim,min(created_at) as crt_dte
      from default.jyq_comapss_stat_20180228
      where status_1='PAY_OFF' 
      and substr(updated_at,1,7) ='2018-02'
      group by uid) a
      left join (
            select uid,count(1)
            from default.jyq_comapss_stat_20180228
            where status_1='LENDING' 
--            and substr(updated_at,1,7) ='2018-01'
            group by uid
      ) b on a.uid=b.uid
      left join (
            select uid,count(1) as ord_cnt,min(created_at) as crt_dte
            from default.jyq_comapss_stat_20180228
            where status_1 in ('LENDING','PAY_OFF','EXCEED')
            and substr(created_at,1,7) <='2018-02'
            group by uid
      ) c on a.uid=c.uid
      where c.uid is not null and b.uid is null 
      group by a.uid  
      ) b 
on a.uid=b.uid 
where a.created_at <date_add('2018-03-01',183);




--1月还清数据的客群分布:还清复借、还清未复借、未还清
--这里从订单推演到了客户
drop table if exists default.jyq_comapss_payoff_201802;
create table default.jyq_comapss_payoff_201802
as
select uid,
#最小的reloan_statu是现在的reloan_status，因为1是最严重的 2其次 3再其次 这种分类也有道理 
       min(reloan_status) as reloan_status,
#这又是啥意思
       max(down) as down
from default.jyq_comapss_stat3_201802
group by uid;

--用户逾期情况
drop table if exists default.jyq_comapss_exceed_201802;
create table default.jyq_comapss_exceed_201802
as
select uid,
       max(exceed_day) as max_exceed_day
from default.jyq_comapss_stat3_201802
where created_at < down
--where created_at> down 
--and created_at <date_add('2018-02-01',180)
group by uid;

--用户是否借款失败
drop table if exists default.jyq_comapss_lendfail_201802;
create table default.jyq_comapss_lendfail_201802
as
select b.uid,
       max(case when a.ord_stt in ('LEND_FAIL','LOAN_DENIED') then 1 else 0 end ) as lend_fail
from (
      select a.uid,max(a.rep_tim) as down,min(a.crt_dte) as up
      from      
      (select uid,max(updated_at) as rep_tim,min(created_at) as crt_dte
      from default.jyq_comapss_stat_20180228
      where status_1='PAY_OFF' 
      and substr(updated_at,1,7) ='2018-02'
      group by uid) a
      left join (
            select uid,count(1)
            from default.jyq_comapss_stat_20180228
            where status_1='LENDING' 
--            and substr(updated_at,1,7) ='2018-01'
            group by uid
      ) b on a.uid=b.uid
      left join (
            select uid,count(1) as ord_cnt,min(created_at) as crt_dte
            from default.jyq_comapss_stat_20180228
            where status_1 in ('LENDING','PAY_OFF','EXCEED')
            and substr(created_at,1,7) <='2018-02'
            group by uid
      ) c on a.uid=c.uid
      where c.uid is not null and b.uid is null 
      group by a.uid 
        ) as b
left join 
(select uid,crt_tim,ord_stt
from dbank.loan_f_order_info 
where date(day)=date('2018-10-01'))
as a
on a.uid=b.uid
where a.crt_tim > down 
and a.crt_tim <date_add('2018-03-01',183)
group by b.uid;


--复借用户状态分类
drop table if exists default.jyq_comapss_y_201802;
create table default.jyq_comapss_y_201802
as
select 
       a.uid,
       a.reloan_status,
       a.down,
       b.max_exceed_day,
       c.lend_fail
from default.jyq_comapss_payoff_201802 as a
left join default.jyq_comapss_exceed_201802 as b
on a.uid=b.uid
left join default.jyq_comapss_lendfail_201802 as c
on a.uid=c.uid;


--y_flag确定
drop table if exists default.jyq_comapss_yflag_201802;
create table default.jyq_comapss_yflag_201802
as
select uid,
       case when reloan_status=3 and max_exceed_day>=60 then 3
            when reloan_status=3 and lend_fail=1 and max_exceed_day<60 then 2
            when reloan_status=2 then 1
            else 0
            end as y_flag ,
            to_date(down) as down   
from default.jyq_comapss_y_201802
where reloan_status>1;





