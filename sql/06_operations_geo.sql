--7: проверка работы логистики(Каково среднее время доставки заказов клиентам, и зависит ли скорость от выбранного класса доставки (Ship Mode)?)
select 
ship_mode, 
count (*) as count_order,
round (avg(ship_date - order_date),2) as avgdate_ship,
round (avg(shipping_cost)::numeric,2) as avgcost_shipping
from orders
group by ship_mode;

select sub_category,
round (sum(sales), 2) as total_sales,
round (sum(shipping_cost)::numeric, 2) as total_shipping_cost,
round ((sum(shipping_cost) / sum(sales) * 100)::numeric, 2) as shipping_share_pct
from  orders
group by sub_category
order by shipping_share_pct desc;

/*Выводы: Скорость доставки соответствует выбранным тарифам: 
 * более быстрые способы доставки обходятся дороже, а стандартная доставка остается наиболее экономичным вариантом.
 * 
 * Рекомендации: Продвигать тарифы с оптимальным соотношением цены и скорости доставки.
 * Искать возможности снижения логистических расходов без ухудшения клиентского опыта.
 */


--8: Какие страны являются наиболее и наименее прибыльными?
select country, market,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit,
round(sum(profit)/sum(sales)*100,2) as profit_margin
from orders  
group by country, market
order by total_profit asc;

/* Выводы: Наибольшую прибыль компании приносят США, Китай и Индия.
В то же время Турция и Нигерия показывают значительные убытки.
Индонезия обеспечивает высокий объем продаж, однако уровень прибыльности остается относительно низким.

Рекомендации: Провести дополнительный анализ причин низкой прибыльности в проблемных странах.
Пересмотреть ценовую и скидочную политику на убыточных рынках.
Сосредоточить дальнейшее развитие на наиболее прибыльных регионах и странах.
*/