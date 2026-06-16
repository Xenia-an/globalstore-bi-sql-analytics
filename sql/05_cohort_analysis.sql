--6: Когортный анализ и удержание клиентов (Retention Rate)
select customer_id, customer_name, order_date, 
extract (year from order_date) as order_year,
extract (year from min(order_date) over(partition by customer_id))  as first_year
from orders 
order by customer_id, order_year
limit 20;

with client_lifecycle as( 
select customer_id, customer_name, 
extract (year from order_date) as order_year,
extract (year from min(order_date) over(partition by customer_id))  as first_year
from orders )
select customer_id, customer_name, order_year, first_year,
(order_year - first_year) as year_life
from client_lifecycle
group by customer_id, customer_name, order_year, first_year
order by customer_id, year_life;

--Retention Rate
with client_lifecycle as( 
select customer_id, customer_name, 
extract (year from order_date) as order_year,
extract (year from min(order_date) over(partition by customer_id))  as first_year
from orders ), 
lifecycle_intervals as( 
select customer_id, first_year, 
(order_year - first_year) as year_life
from client_lifecycle
group by customer_id, first_year, order_year),
fierst_count as (
select  first_year,
count(distinct customer_id )  as total_firstyear_customer
from lifecycle_intervals
where year_life = 0
group by first_year)
select 
l.first_year as "Когорта",
f.total_firstyear_customer as "Привлечено клиентов",
'100.0%' as "Год 0",
round(sum(case when l.year_life=1 then 1 else 0 end )*100.0/f.total_firstyear_customer,2)||'%' as "Год 1",
round(sum(case when l.year_life=2 then 1 else 0 end)*100.0/f.total_firstyear_customer,2)||'%' as "Год 2",
round(sum(case when l.year_life=3 then 1 else 0 end)*100.0/f.total_firstyear_customer,2)||'%' as "Год 3"
from lifecycle_intervals l
join fierst_count f on l.first_year = f.first_year
group by l.first_year, f.total_firstyear_customer
order by l.first_year;

/* Выводы: Большинство клиентских когорт демонстрируют достаточно высокий уровень удержания.
Многие покупатели продолжают совершать заказы спустя несколько лет после первой покупки.
При этом количество новых клиентов в более поздние периоды снижается, что может свидетельствовать о замедлении темпов привлечения аудитории.

Рекомендации: Провести анализ каналов привлечения новых покупателей и их эффективности.
Продолжать развивать программы удержания существующих клиентов.
Сбалансировать инвестиции между удержанием текущих клиентов и привлечением новых.
*/
