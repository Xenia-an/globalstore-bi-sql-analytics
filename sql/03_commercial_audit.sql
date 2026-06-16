-- 2: поиск убыточных мест и оценка системы скидок 
select 
case when profit < 0 then 'убыток' else 'прибыль' end as status, 
count(*) as order_count,
round(avg(discount) * 100, 1) as total_discount,
round(sum(profit),2) as total_profit
from orders 
group by 1;

--посмотрим убыточные категории товаров 
select category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders 
group by 1
order by total_profit asc;

--посмотрим по подкатегориям
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders 
group by 1
order by total_profit asc;

--посмотрим самую убыточную подкатегорию в Furniture
select category, sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders 
where category='Furniture' 
group by category, sub_category
order by total_profit asc;

--посмотрим убыток по регионам 
select category, sub_category, region, 
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders  
group by category, sub_category, region 
having sum(profit) < 0 
order by total_profit asc;

--проверим регион Southeast Asia по убыточным товарам 
select category, sub_category, region, 
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders  
where region='Southeast Asia' 
group by category, sub_category, region 
having sum(profit) < 0 
order by total_profit asc;

--посмотрим какай сегмент чаще делает убыточные покупки в регионе Southeast Asia
select segment, 
count(*) as segment_count, 
sub_category,
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders 
where region='Southeast Asia'
group by segment, sub_category 
having sum(profit)<0
order by total_profit asc;

--посмотрим какие конкретно страны в регионе приносят больше всего убытков 
select country, 
round(sum(profit),2) as total_profit,
round(avg(discount) * 100, 1) as total_discount
from orders 
where region='Southeast Asia'
group by country 
having sum(profit)<0
order by total_profit asc;

/*
 * Выводы: Было выявленна уязвимость коммерческой политики: 
 * прибыльные транзакции имеют среднюю скидку всего 1.8%, в то время как убыточные — 46.5%.
 * Главный проблемный регион Юго-Восточная Азия (Southeast Asia).
 * Там скидки под 47-48% раздаются системно во всех клиентских сегментах (Corporate, Consumer, Home Office).
 * На уровне товаров максимальные потери приносит подкатегория Столы (Tables): 
 * чистый убыток составил -$10 932 при средней скидке 24.3%.
 * 
 * Бизнес-рекомендация: Пересмотреть политику предоставления скидок в регионе Southeast Asia.
 * Провести анализ ценообразования и себестоимости товаров категории Tables.
 */

--3: ABC-анализ ассортимента 
with sub_caterogy_sales as (
select sub_category, 
round(sum(sales), 2) as total_sales
from orders 
group by sub_category)
select sub_category, total_sales, 
round(sum(total_sales) over (order by total_sales desc),2) as cumulative_sale,
round((sum(total_sales) over (order by total_sales desc)/sum(total_sales) over ())*100,2) as cumulative_share_pct
from sub_caterogy_sales 
order by total_sales desc;

--присвоим классы ABC
with sub_caterogy_sales as (
select sub_category, 
round(sum(sales), 2) as total_sales
from orders 
group by sub_category), 
cumulative_shares as(
select sub_category, total_sales, 
round((sum(total_sales) over (order by total_sales desc)/sum(total_sales) over ())*100,2) as cumulative_share_pct
from sub_caterogy_sales 
order by total_sales desc)
select sub_category, total_sales, cumulative_share_pct,
case 
	when cumulative_share_pct <= 85 then 'A (самые прибыльные 80% продаж)' 
	when cumulative_share_pct <= 96 then 'B (15% продаж)'
	else 'C (низколиквидные)'
end as abc_class
from cumulative_shares 
order by total_sales desc;

/* Выводы:
 * Группу А (83% всей выручки) формируют всего 9 ключевых подкатегорий (топ-лидеры: Phones, Copiers, Bookcases, Chairs).
 * Сюда же по объему денег входят проблемные Tables.
 * Группа В (поддерживающие товары) — это Art, Binders, Furnishings, Supplies.
 * Группа С (низколиквидный хвост, <5% выручки) — Paper, Envelopes, Fasteners, Labels. 
 */


--4: Какие подкатегории товаров являются «Дойными коровами», а какие — «Трудными детьми» (Матрица BCG)? 
select sub_category, 
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category
order by profit_margin desc;

--группируем и проводим BCG анализ 
with bcg_raw as( 
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category)
select sub_category, total_sales, profit_margin,
case 
	when total_sales >=500000 and profit_margin>= 17 then '«Звезды» (Высокий рост, высокая доля)'
	when total_sales < 500000 and profit_margin>= 17 then '«Дойные коровы» (Низкий рост, высокая доля)'
	when total_sales >=500000 and profit_margin< 17 then '«Трудные дети» (Высокий рост, низкая доля)'
	when total_sales < 500000 and profit_margin< 17 then '«Собаки» (Низкий рост, низкая доля)'
end as bcg_class
from bcg_raw 
order by total_sales desc;

--выведем только звезды 
with bcg_raw as( 
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category), 
class_bcg as (select sub_category, total_sales, profit_margin,
case 
	when total_sales >=500000 and profit_margin>= 17 then '«Звезды» (Высокий рост, высокая доля)'
	when total_sales < 500000 and profit_margin>= 17 then '«Дойные коровы» (Низкий рост, высокая доля)'
	when total_sales >=500000 and profit_margin< 17 then '«Трудные дети» (Высокий рост, низкая доля)'
	when total_sales < 500000 and profit_margin< 17 then '«Собаки» (Низкий рост, низкая доля)'
end as bcg_class
from bcg_raw )
select sub_category,
    total_sales,
    profit_margin,
    bcg_class
from class_bcg 
where bcg_class = '«Звезды» (Высокий рост, высокая доля)'
order by total_sales desc;

-- выведем только  дойных коров 
with bcg_raw as( 
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category), 
class_bcg as (select sub_category, total_sales, profit_margin,
case 
	when total_sales >=500000 and profit_margin>= 17 then '«Звезды» (Высокий рост, высокая доля)'
	when total_sales < 500000 and profit_margin>= 17 then '«Дойные коровы» (Низкий рост, высокая доля)'
	when total_sales >=500000 and profit_margin< 17 then '«Трудные дети» (Высокий рост, низкая доля)'
	when total_sales < 500000 and profit_margin< 17 then '«Собаки» (Низкий рост, низкая доля)'
end as bcg_class
from bcg_raw )
select sub_category,
    total_sales,
    profit_margin,
    bcg_class
from class_bcg 
where bcg_class = '«Дойные коровы» (Низкий рост, высокая доля)'
order by total_sales desc;

-- выведем только трудных детей 
with bcg_raw as( 
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category), 
class_bcg as (select sub_category, total_sales, profit_margin,
case 
	when total_sales >=500000 and profit_margin>= 17 then '«Звезды» (Высокий рост, высокая доля)'
	when total_sales < 500000 and profit_margin>= 17 then '«Дойные коровы» (Низкий рост, высокая доля)'
	when total_sales >=500000 and profit_margin< 17 then '«Трудные дети» (Высокий рост, низкая доля)'
	when total_sales < 500000 and profit_margin< 17 then '«Собаки» (Низкий рост, низкая доля)'
end as bcg_class
from bcg_raw )
select sub_category,
    total_sales,
    profit_margin,
    bcg_class
from class_bcg 
where bcg_class = '«Трудные дети» (Высокий рост, низкая доля)'
order by total_sales desc;

-- выведем только собак  
with bcg_raw as( 
select sub_category,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders 
group by sub_category), 
class_bcg as (select sub_category, total_sales, profit_margin,
case 
	when total_sales >=500000 and profit_margin>= 17 then '«Звезды» (Высокий рост, высокая доля)'
	when total_sales < 500000 and profit_margin>= 17 then '«Дойные коровы» (Низкий рост, высокая доля)'
	when total_sales >=500000 and profit_margin< 17 then '«Трудные дети» (Высокий рост, низкая доля)'
	when total_sales < 500000 and profit_margin< 17 then '«Собаки» (Низкий рост, низкая доля)'
end as bcg_class
from bcg_raw )
select sub_category,
    total_sales,
    profit_margin,
    bcg_class
from class_bcg 
where bcg_class = '«Собаки» (Низкий рост, низкая доля)'
order by total_sales desc;

/*Выводы:  Сопоставление объемов с чистой рентабельностью (Profit Margin) выявило
 * Подкатегории Paper (маржа 25.21%) и Labels (маржа 22.23%), находившиеся в хвосте выручки, оказались сверхэффективными. 
 * Абсолютная «Дойная корова» - Binders (маржа 25.95% при стабильном обороте $314K).
 * Настоящие «Звезды» - Copiers (маржа 18.35% при выручке $1.16M).
 * При этом Phones, Bookcases и Chairs застряли в категории «Трудных детей» из-за высокой себестоимости (маржа всего 12-14%).
 * 
 * Бизнес-рекомендация: Увеличивать продажи высокомаржинальных товаров.
 * Использовать перекрестные продажи между популярными и прибыльными категориями.
 * Изучить возможности повышения маржинальности крупных товарных групп.
 */
