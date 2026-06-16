select  order_id, customer_id, product_id, sales, count(*)
from orders
group by order_id, customer_id, product_id, sales
having  count(*) > 1;

select 
count(case when  order_id is null  then  1 end) as null_orders,
count(case when  customer_id is null  then  1 end) as null_customers,
count(case when  order_date is null  then  1 end) as null_dates,
count(case when  sales is null  then  1 end) as null_sales
from  orders;

select 
count(*) as date_errors
from  orders
where  ship_date < order_date;

select 
count(*) as negative_sales_errors
from  orders
where  sales < 0 OR quantity <= 0;


