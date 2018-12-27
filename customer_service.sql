#客服
select a.uid,a.max_tim_dff,b.kf_contact_times,c.user_callin_times,
d.sys_callout_times,e.crd_lmt_inq_times,f.crd_card_inq_times
from
(
select uid,max(tim_dff) as max_tim_dff from dbank.dbank_f_customer_service_message_detail
where date(day) between date('2018-07-01') and date('2018-07-31')
group by uid
) as a 
left join
(
select uid,
count(uid) as kf_contact_times
from dbank.dbank_f_customer_service_message_detail
where date(day) between date('2018-07-01') and date('2018-07-31')
group by uid 
) as b 
on a.uid=b.uid
left join
(
select uid,
count(uid) as user_callin_times
from dbank.dbank_f_customer_service_message_detail
where cha_typ='usr' and date(day) between date('2018-07-01') and date('2018-07-31')
group by uid 
) as c
on a.uid=c.uid
left join
(
select uid,
count(uid) as sys_callout_times
from dbank.dbank_f_customer_service_message_detail
where cha_typ='sys' and date(day) between date('2018-07-01') and date('2018-07-31')
group by uid 
) as d
on a.uid=d.uid
left join
(
select uid,
count(uid) as crd_lmt_inq_times
from dbank.dbank_f_customer_service_message_detail
where cha_typ='usr' 
and date(day) between date('2018-07-01') and date('2018-07-31') 
and msg_ctt like '%额度%'
group by uid
) as e
on a.uid=e.uid
left join
(
select uid,
count(uid) as crd_card_inq_times
from dbank.dbank_f_customer_service_message_detail
where cha_typ='usr' 
and date(day) between date('2018-07-01') and date('2018-07-31') 
and msg_ctt like '%信用卡%'
group by uid
) as f
on a.uid=f.uid