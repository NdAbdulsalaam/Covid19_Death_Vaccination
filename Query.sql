-- The Query was carried out uxsing BigQuery
-- AS part of Data Analytics Professional Certificate

-- Data was uploaded as CSV file and named COVID19
-- Focus is on Africa
-- I Visualized using with Tableaua


-- Updated: September 2022


  ---- START QUERY ----

--View the start and last date
SELECT 
	Min(date) AS start_date, MAX(date) AS end_date
FROM 
  `casestudy-362514.Covid19.death`;

-- Preview the table
SELECT  *
FROM 
	`casestudy-362514.Covid19.death`
ORDER BY 
	location, date; --sort by country first and the date


-- Location and date columns should not contain missing values
SELECT  *
FROM 
	`casestudy-362514.Covid19.death`
WHERE 
	location IS NULL OR date IS NULL;

-- Select data to be used
SELECT
	date, continent, location, total_cases, new_cases, total_deaths, population
FROM 
	`casestudy-362514.Covid19.death`
WHERE
	location IS NOT NULL
ORDER BY
	date;

-- Look for counties with infection count
SELECT 
  date, continent, location, total_cases
FROM 
    `casestudy-362514.Covid19.death`
ORDER BY 
  total_cases DESC;


-- Let me look for Africa lone
SELECT 
  date, continent, location, total_cases
FROM 
    `casestudy-362514.Covid19.death`
WHERE continent = 'Africa'
ORDER BY
  total_cases DESC;

-- Let's check for US
SELECT 
  date, continent, location, total_cases
FROM 
    `casestudy-362514.Covid19.death`
WHERE location LIKE '%States%'
ORDER BY
  total_cases DESC;

-- Check for countries with highest infection rate in Africa
SELECT
  location, AVG(population) AS avg_population, AVG(total_cases) AS avg_cases, (AVG(total_cases)/AVG(population))*100 AS infection_rate
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL AND
   continent = 'Africa'
GROUP BY 
  location
ORDER BY
  infection_rate DESC;


-- Check for countries with highest death rate in Africa
SELECT  
  location, AVG(population) AS population, AVG(total_deaths) AS avg_death,
  (AVG(total_deaths)/AVG(total_cases))*100 AS death_rate
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL AND
   continent = 'Africa'
GROUP BY 
  location
ORDER BY
  death_rate DESC;


-- Check for total cases vs population in Africa
SELECT  
  date, location, total_cases, population, (total_cases/population)*100 AS PercentPopInfected
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL AND
   continent = 'Africa'
ORDER BY
  PercentPopInfected DESC;

-- Check for what is happening in the world
-- Show countries with the highest death count per population
SELECT  
  location, max(total_deaths) AS maxDeathCount
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL
GROUP BY  
   location
ORDER BY
  maxDeathCount DESC;

-- Check for continent total cases and deaths 
SELECT  
  continent, SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths, sum(cast(new_deaths as int))/ sum(new_cases) * 100 as percentDeath
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL
GROUP BY  
   continent
ORDER BY
  percentDeath DESC;

--Total cases and total deaths by day
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/ SUM(new_cases) * 100 AS percentDeath
  FROM 
    `casestudy-362514.Covid19.death`
WHERE 
   location IS NOT NULL
GROUP BY  
   date
ORDER BY
  percentDeath DESC;


-- Looking at Total Population vs Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.total_vaccinations,
SUM(CAST(v.total_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM 
    `casestudy-362514.Covid19.death` AS d
JOIN `casestudy-362514.Covid19.vaccinations` AS v
	ON (d.location = v.country
	AND d.date = v.date)
WHERE d.location IS NOT NULL
ORDER BY RollingPeopleVaccinated DESC;

-- USE CTE to get Rolling percetage of people vaccinated
WITH PopVac AS (
    SELECT d.continent, d.location, d.date, d.population, v.total_vaccinations,
SUM(CAST(v.total_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
  FROM 
    `casestudy-362514.Covid19.death` AS d
  JOIN `casestudy-362514.Covid19.vaccinations` AS v
	ON (d.location = v.country
	AND d.date = v.date)
  WHERE d.location IS NOT NULL
  ORDER BY RollingPeopleVaccinated DESC
  )
SELECT *
FROM PopVac;

-- USE TEMP TABLE, let's try the same as above
drop table if exists #PercentPopVaccinated
create table #PercentPopVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.total_vaccinations,
SUM(CAST(v.total_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
  FROM 
    `casestudy-362514.Covid19.death` AS d
  JOIN `casestudy-362514.Covid19.vaccinations` AS v
	ON (d.location = v.country
	AND d.date = v.date)
  WHERE d.location IS NOT NULL
  ORDER BY RollingPeopleVaccinated DESC
  )
SELECT *
FROM PopVac;

-- Creating view to store data
CREATE VIEW PercentPopVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.total_vaccinations,
SUM(CAST(v.total_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
  FROM 
    `casestudy-362514.Covid19.death` AS d
  JOIN `casestudy-362514.Covid19.vaccinations` AS v
	ON (d.location = v.country
	AND d.date = v.date)
  WHERE d.location IS NOT NULL
  ORDER BY RollingPeopleVaccinated DESC
