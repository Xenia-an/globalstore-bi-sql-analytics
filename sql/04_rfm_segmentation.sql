--5:RFM-сегментация клиентов
select customer_id, customer_name, 
(select max(order_date) from orders) - max(order_date) as recency,
count(distinct order_id) as frequency,
round(sum(sales),2) as monetary
from orders 
group by customer_id, customer_name 
order by monetary desc 
limit 10;

--распределим на группы от 1 до 5
with customer_metrics as (
select customer_id, customer_name, 
(select max(order_date) from orders) - max(order_date) as recency,
count(distinct order_id) as frequency,
round(sum(sales),2) as monetary
from orders 
group by customer_id, customer_name),
rfm_scores as ( 
select customer_id, customer_name,
NTILE(5) over (order by recency desc) as r,
NTILE(5) over (order by frequency asc) as f,
NTILE(5) over (order by monetary asc) as m
from customer_metrics)
select customer_id, customer_name, r, f, m,
concat (r, f, m) as rfm_cell
from rfm_scores
order by rfm_cell desc
limit 15;

with customer_metrics as (
select customer_id, customer_name, 
(select max(order_date) from orders) - max(order_date) as recency,
count(distinct order_id) as frequency,
round(sum(sales),2) as monetary
from orders 
group by customer_id, customer_name),
rfm_scores as ( 
select customer_id, customer_name,
NTILE(5) over (order by recency desc) as r,
NTILE(5) over (order by frequency asc) as f,
NTILE(5) over (order by monetary asc) as m
from customer_metrics),
rfm_segments as (
select customer_id, customer_name,
 case 
	when r >=4 and f>=4 and m>=4 then 'VIP-клиенты'
	when r >=4 and f<=2  then 'Новички'
	when r <=2 and f>=4 and m>=4 then 'Нельзя терять'
	when r=3 and f>=4 and m>=4 then 'В зоне риска'
	when r <=2 and f<=2 and m<=2 then 'Спящие/Ушедшие'
	else 'Средний класс'
end as marketing_segment
from rfm_scores ) 
select marketing_segment,
count(*) as count_customers,
 round(count(*)*100.0/(select count(*) from rfm_segments),2) as segment_share_pct
from rfm_segments 
group by marketing_segment
order by count_customers desc;

--выведем список клиентов находящихся в зоне риска и нельзя потерять, также укажим их бизнес сегмент
 with customer_metrics as (
select customer_id, customer_name, segment, 
(select max(order_date) from orders) - max(order_date) as recency,
count(distinct order_id) as frequency,
round(sum(sales),2) as monetary
from orders 
group by customer_id, customer_name, segment),
rfm_scores as ( 
select customer_id, customer_name, segment, recency, monetary,
NTILE(5) over (order by recency desc) as r,
NTILE(5) over (order by frequency asc) as f,
NTILE(5) over (order by monetary asc) as m
from customer_metrics),
rfm_segments as (
select customer_id, customer_name, segment, recency, monetary,
 case 
	when r >=4 and f>=4 and m>=4 then 'VIP-клиенты'
	when r >=4 and f<=2  then 'Новички'
	when r <=2 and f>=4 and m>=4 then 'Нельзя терять'
	when r=3 and f>=4 and m>=4 then 'В зоне риска'
	when r <=2 and f<=2 and m<=2 then 'Спящие/Ушедшие'
	else 'Средний класс'
end as marketing_segment
from rfm_scores ) 
select customer_id, customer_name, 
segment as business_segment,
marketing_segment,
recency as days_last_order, 
monetary as total_sales 
from rfm_segments 
where marketing_segment = 'В зоне риска' or marketing_segment = 'Нельзя терять'
order by business_segment, total_sales desc;

--также посмотрим список новичков на которых стоит обратить внимание, смотрим топ 10 стран откуда пришли новички и их средний чек
 with customer_metrics as (
select customer_id, customer_name, segment, country,
(select max(order_date) from orders) - max(order_date) as recency,
count(distinct order_id) as frequency,
round(sum(sales),2) as monetary
from orders 
group by customer_id, customer_name, segment, country),
rfm_scores as ( 
select customer_id, customer_name, segment, recency, monetary, country,
NTILE(5) over (order by recency desc) as r,
NTILE(5) over (order by frequency asc) as f
from customer_metrics),
rfm_segments as (
select customer_id, customer_name, segment, recency, monetary, country,
 case 
	when r >=4 and f<=2  then 'Новички'
	else 'Остальные'
end as marketing_segment
from rfm_scores ) 
select country,
    count(*) as new_customers_count,
    round(sum(monetary), 2) as total_sales,
    round(avg(monetary), 2) as avg_check_new_customer
from rfm_segments 
where marketing_segment = 'Новички'
group by country
order by new_customers_count desc
LIMIT 10;

/*Выводы: База компании устойчива: 16.60% (798 человек) - это лояльное ядро VIP-клиентов, покупающих часто и дорого.
18.44% базы (886 человек) уже ушли в разряд Спящих.
В критической зоне оттока находятся сегменты «В зоне риска» (6.26%) и «Нельзя терять» (5.41%) - это 541 крупный исторический клиент, который перестал покупать.

Бизнес-рекомендация: Разработать программы удержания для клиентов с высоким потенциалом и признаками снижения активности.
Использовать персонализированные предложения и программы лояльности.
Регулярно отслеживать изменения в поведении клиентов для своевременного реагирования.
*/