-- 1: Динамика продаж компании по месяцам (MoM Growth)
--Как продажи растут от года к году (YoY)
select  
extract (year from order_date) as sales_year,
count (distinct order_id) as total_orders,
round (sum(sales), 2) as sum_sales,
round (sum(profit), 2) as sum_profit,
round ((sum(profit) / sum(sales) * 100), 2) as profit_margin
from orders
group by sales_year
order by sales_year;

select  
extract (month from  order_date) as month_num,
to_char(order_date, 'Month') as month_name, 
round (avg(sales), 2) as avg_sales, 
round (sum(sales), 2) as total_sales, 
round (sum(profit), 2) as total_profit
from orders
group by month_num, month_name
order by month_num;

with monthly_raw as (
select 
date_trunc('month', order_date)::date as sales_month,
round(sum(sales), 2) as current_sales,
round(sum(profit), 2) as current_profit
from orders
group by sales_month),
monthly_with_lag as (
select sales_month, current_sales, current_profit,
lag(current_sales, 1) over (order by sales_month) as previous_sales
from monthly_raw)
select sales_month,
current_sales as sales,
previous_sales,
round(((current_sales - previous_sales) / previous_sales * 100), 2) as sales_growth_mom_pct,
current_profit as profit
from monthly_with_lag
order by sales_month;

select 
extract(month from order_date) as month_num,
round(sum(case when extract(year from order_date) = 2011 then sales else 0 end), 2) as sales_2011,
round(sum(case when extract(year from order_date) = 2012 then sales else 0 end), 2) as sales_2012,
round(sum(case when extract(year from order_date) = 2013 then sales else 0 end), 2) as sales_2013,
round(sum(case when extract(year from order_date) = 2014 then sales else 0 end), 2) as sales_2014
from orders
group by month_num
order by month_num;


/* Вывод: В компании действует выраженная модель сезонности. 
 * Вместо одного классического зимнего пика, у бизнеса есть два пика продаж: 
 * Август-Сентябрь (период подготовки к учебному/деловому сезону с выручкой >$1.01M) 
 * и Ноябрь-Декабрь (рождественский бум с пиком в $1.20M)
 * Также есть периоды спада это Январь-Февраль(спад после новогодних праздников)
 * и Июль (естественный откат рынка к средним показателям после июньского закрытия полугодия) 
 * При этом глобальный годовой тренд показывает стабильное удвоение масштабов бизнеса из года в год.
 
 *Рекомендации: Планировать запуск новых продуктов и маркетинговые кампании на периоды максимального спроса (август–сентябрь и ноябрь–декабрь).
 *Использовать дополнительные акции и рекламные активности в феврале для стимулирования продаж.
 *Учитывать сезонные пики при планировании запасов и логистики
 */