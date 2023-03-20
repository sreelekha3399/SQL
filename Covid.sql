SELECT * FROM `Covid-19`.coviddeaths;
SELECT * FROM `Covid-19`.covidvaccination;

-- Total number of records in the table
SELECT count(*) from coviddeaths;

-- Structure of a table
DESCRIBE coviddeaths;
DESCRIBE covidvaccination;

-- Checking for the data types of the columns
SELECT column_name, data_type
from INFORMATION_SCHEMA.COLUMNS 
where table_schema = 'Covid-19' and table_name = 'coviddeaths';

-- Found that date is of text data type. Need to convert the date into date datatype
Update coviddeaths set date=STR_TO_DATE(date, "%Y-%m-%d");
Update covidvaccination set date=STR_TO_DATE(date, "%Y-%m-%d");

-- Select the data that is needed for the analysis
select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1,2;

-- Percentage of deaths in United States (Shows the likelihood of dying if affected with Covid-19)
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_of_deaths
from coviddeaths
where location like '%states%'
order by 2;

-- Percentage of population affected with Covid-19
select location, date, population, total_cases, total_deaths, (total_cases/population)*100 as percentage_of_cases
from coviddeaths
where location like '%states%'
order by 2;

-- Country wise infection rate
select location, population, max(total_cases), max((total_cases/population))*100 as percentage_infected
from coviddeaths
-- where location like '%india%'
group by 1,2
order by percentage_infected desc;

-- Countries with highest death count per population
select location, population,max(total_deaths), max((total_deaths/population))*100 as percentage_died
from coviddeaths
group by 1,2
order by percentage_died desc
limit 10;

-- Continent wise death counts
select continent, max(cast(total_deaths as double)) as Total_death_count
from coviddeaths
where continent is not null
group by 1
order by Total_death_count desc;

-- New cases date wise
select date, sum(new_cases) as Total_new_cases
from coviddeaths
group by 1
order by Total_new_cases desc;


-- Join deaths and vaccination table to get more insights. Before that convert date in vaccination to date datatype.

-- Out of total population, how many people got vaccinated?
-- Let's answer this question using various approaches(CTEs, Vies, Temporary tables) in sql.

-- Approach 1 - Using CTE
with t1 as (select d.continent as Continent, d.location as location, d.date as date, d.population as population, v.new_vaccinations,
sum(cast(new_vaccinations as double)) over (partition by d.location order by d.location, d.date) as RollingVaccinationCount
from coviddeaths as d
join covidvaccination as v
on d.location=v.location and d.date=v.date
where d.continent is not null)

select Continent, location, population, max(RollingVaccinationCount) as Total_population_vaccinated, max(RollingVaccinationCount/population*100) as "Percentage of population vaccinated"
from t1
group by 1,2,3
order by 1 asc, 4 desc;


-- Approac 2 - Using Views
DROP VIEW IF EXISTS Percentageofpopulationvaccinated;

create view Percentageofpopulationvaccinated as
(select d.continent as Continent, d.location as location, d.date as date, d.population as population, v.new_vaccinations,
sum(cast(new_vaccinations as double)) over (partition by d.location order by d.location, d.date) as RollingVaccinationCount
from coviddeaths as d
join covidvaccination as v
on d.location=v.location and d.date=v.date
where d.continent is not null
order by 2,3);

select *, (RollingVaccinationCount/population)*100 as percentage
from Percentageofpopulationvaccinated;

-- Approach 3 - Using Temporary tables
CREATE TEMPORARY TABLE PERCENT_OF_PEOPLE_VACCINATED
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
New_Vaccinations double,
Rolling_PeopleVaccinated numeric
);

SET SESSION sql_mode = '';

INSERT INTO PERCENT_OF_PEOPLE_VACCINATED
select d.continent as Continent, d.location as location, d.date as date, d.population as population, v.new_vaccinations,
sum(cast(new_vaccinations as double)) over (partition by d.location order by d.location, d.date) as RollingVaccinationCount
from coviddeaths as d
join covidvaccination as v
on d.location=v.location and d.date=v.date
;

select *, (Rolling_PeopleVaccinated/population)*100 as percentage
from  PERCENT_OF_PEOPLE_VACCINATED;


