alter table weekly_sales
modify column week_date varchar(25);

-- 1. Data Cleansing Steps
create temporary table clean_weekly_sales select 
str_to_date(week_date,"%d/%m/%y") as week_date,
Week(str_to_date(week_date, "%d/%m/%y")) AS week_number,
Month(str_to_date(week_date, "%d/%m/%y")) AS month_number,
Year(str_to_date(week_date, "%d/%m/%y")) AS calendar_year,
region, 
platform, 
segment,
case when right(segment,1)='1' then "Young Adults"
when right(segment, 1)='2' then "Middle Aged"
when right(segment, 1) in ('3', '4') then "Retirees"
else "Unknown"
end as age_band,
case when left(segment, 1)='C' then "Couples"
when left(segment, 1)='F' then "Families"
else "Unknown" 
end as demographic,
transactions,
sales,
round(sales/transactions, 2) as avg_transaction
from weekly_sales;


-- 2.Data Exploration

-- What day of the week is used for each week_date value?
select DISTINCT(dayname( week_date)) AS week_day 
from clean_weekly_sales;

-- What range of week numbers are missing from the dataset?
WITH RECURSIVE week_number_cte AS (
  SELECT 1 AS week_number
  UNION ALL
  SELECT week_number + 1
  FROM week_number_cte
  WHERE week_number < 52
)  
select w.week_number
from clean_weekly_sales c
right outer join week_number_cte w
on w.week_number = c.week_number
WHERE c.week_number IS NULL;

-- How many total transactions were there for each year in the dataset?
select calendar_year, sum(transactions)
from clean_weekly_sales
group by calendar_year
order by calendar_year;

-- What is the total sales for each region for each month?
select region,month_number, sum(sales)
from clean_weekly_sales
group by region, month_number
order by region, month_number;

-- What is the total count of transactions for each platform?
select platform, sum(transactions)
from clean_weekly_sales
group by platform;

-- What is the percentage of sales for Retail vs Shopify for each month?
with cte as (select calendar_year, platform,month_number,sum(sales) as monthly_sales
from clean_weekly_sales
group by calendar_year , platform,month_number
order by month_number)

select calendar_year, month_number, 
 ROUND(100 * MAX(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) / 
      SUM(monthly_sales),2) AS retail_percentage,
ROUND(100 * MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END) / 
      SUM(monthly_sales),2) AS shopify_percentage
from cte
group by calendar_year, month_number;


with cte1 as (select calendar_year, platform,month_number,sum(sales) as monthly_sales
from clean_weekly_sales
group by calendar_year , platform,month_number
order by month_number)

select calendar_year, month_number,
MAX(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END)/sum(monthly_sales) as ret,
MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END)/sum(monthly_sales) as shop
from cte1
group by calendar_year, month_number;

-- What is the percentage of sales by demographic for each year in the dataset?
with cte as (select calendar_year, demographic, sum(sales) as yearly_sales
from clean_weekly_sales
group by calendar_year, demographic)

select calendar_year,
max(case when demographic="Couples" then yearly_sales else null end)/sum(yearly_sales) as Couples,
max(case when demographic="Families" then yearly_sales else null end)/sum(yearly_sales) as Families,
max(case when demographic="Unknown" then yearly_sales else null end)/sum(yearly_sales) as Unknowns
from cte
group by calendar_year;

-- Which age_band and demographic values contribute the most to Retail sales?
select age_band, demographic, sum(sales) as Ret_sales
from clean_weekly_sales
where platform="Retail"
group by age_band, demographic
order by Ret_sales desc;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
select calendar_year, platform, avg(avg_transaction) 
from clean_weekly_sales
group by calendar_year, platform
order by calendar_year, platform;

-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
select week_number
from clean_weekly_sales
where week_date = "2020-06-15";

WITH changes AS (
  SELECT 
    calendar_year, 
    week_number, 
    SUM(sales) AS total_sales
  FROM clean_weekly_sales
  WHERE (week_number BETWEEN 21 AND 28) 
  GROUP BY calendar_year, week_number
),
changes_2 AS (
  SELECT calendar_year,
    SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN total_sales END) AS before_change,
    SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN total_sales END) AS after_change
    
  FROM changes
  GROUP BY calendar_year)

SELECT
calendar_year, 
  before_change, 
  after_change, 
  after_change - before_change AS variance, 
 100*(after_change - before_change) / before_change AS percentage
FROM changes_2
where calendar_year='2020';
