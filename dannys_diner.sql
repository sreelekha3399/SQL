SELECT * FROM Eight_week.sales;

-- What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(price) as total_amount_spent
from sales s
join menu m
on s.product_id = m. product_id
group by customer_id;

-- How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as No_of_days_visited
from sales
group by customer_id;

-- What was the first item from the menu purchased by each customer?
select distinct customer_id, product_name from
(select customer_id, order_date, product_name,
rank() over (partition by customer_id order by order_date asc) as rnum
from sales s
join menu m
on s.product_id=m.product_id)x
where rnum=1;

-- Using group concat to have a comma separated values
select distinct customer_id, group_concat(distinct product_name separator ',') from
(select customer_id, order_date, product_name,
rank() over (partition by customer_id order by order_date asc) as rnum
from sales s
join menu m
on s.product_id=m.product_id)x
where rnum=1
group by customer_id;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(*)
from sales s
join menu m
on s.product_id=m.product_id
group by m.product_name
order by count(*) desc
limit 1;

with t1 as (select product_id
from sales
group by product_id
order by count(*) desc
limit 1)

select customer_id, count(s.product_id)
from sales s
join t1 on s.product_id = t1.product_id
group by customer_id;

-- Which item was the most popular for each customer?
with t2 as (select customer_id, product_name, count(s.product_id) as cnt
from sales s
join menu m
on s.product_id=m.product_id
group by customer_id, product_name
)

select customer_id, product_name from( select customer_id, product_name, cnt, 
rank() over (partition by customer_id order by cnt desc) as rnum
from t2)x
where rnum=1;

-- Which item was purchased first by the customer after they became a member?
with t3 as (select s.customer_id, order_date, join_date, product_name,
rank() over (partition by customer_id order by order_date asc) as rnum
from sales s
join members m
on s.customer_id= m.customer_id and s.order_date >= m.join_date
join menu m1
on s.product_id=m1.product_id
order by order_date asc)

select customer_id, product_name
from t3
where rnum=1;

-- Which item was purchased just before the customer became a member?
with t4 as (select s.customer_id, order_date, join_date, product_name,
rank() over (partition by customer_id order by order_date asc) as rnum
from sales s
join members m
on s.customer_id= m.customer_id and s.order_date < m.join_date
join menu m1
on s.product_id=m1.product_id
order by order_date asc)

select customer_id, group_concat(product_name separator ',') as items
from t4
where rnum=1
group by customer_id;

-- What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(distinct s.product_id), sum(price)
from sales s
join members m
on s.customer_id= m.customer_id and s.order_date < m.join_date
join menu m1
on s.product_id=m1.product_id
group by s.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,
sum(case when product_name="sushi" then 2*10*price else 10*price end) as points
from sales s
join menu m
on s.product_id=m.product_id
group by customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id,
sum(case when order_date>=join_date and order_date<join_date+7  then 2*10*price
when order_date<join_date and product_name="sushi" then 2*10*price
else 10*price
end) as points
from sales s
join menu m on s.product_id=m.product_id
join members m1 on s.customer_id=m1.customer_id
where order_date<="2021-01-31"
group by s.customer_id

