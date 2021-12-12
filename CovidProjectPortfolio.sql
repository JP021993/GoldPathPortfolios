SELECT *
FROM CovidDeaths
where continent is not null
order by 1, 2;

SELECT location,
continent,
date,
total_cases,
new_cases,
total_deaths,
population
FROM CovidDeaths
where continent is not null
Order By 1, 2;

-- Looking at total cases vs total deaths
-- shows likelihood of passing away if you contract covid in the US
SELECT location,
continent,
date,
total_cases,
total_deaths,
(total_deaths/total_cases) * 100 AS death_rate
FROM CovidDeaths
WHERE location like '%states%'
AND continent is not null
Order By 1, 2;


-- Looking at total cases versus population
-- shows infection rate in the US
SELECT location,
continent,
date,
total_cases,
population,
(total_cases/population) * 100 AS infection_rate
FROM CovidDeaths
-- WHERE location like '%states%'
WHERE continent is null
Order By 1, 2;

-- Looking at countries with highest infection rate based on population
SELECT location,
MAX(total_cases) as highest_number_of_cases,
population,
MAX((total_cases/population) * 100) AS infection_rate
FROM CovidDeaths
where continent is null
GROUP BY location,population
Order By infection_rate DESC; 

-- Total Death Count by Country
SELECT location,
MAX(cast(total_deaths AS int)) as total_country_death_count
FROM CovidDeaths
where continent is null
GROUP BY location
Order By total_country_death_count DESC;

-- highest death count per continent
SELECT continent,
MAX(cast(total_deaths AS int)) as total_continent_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
Order By total_continent_death_count DESC;

-- Global Numbers
SELECT SUM(new_cases) AS total_cases, 
SUM(cast(new_deaths AS int)) AS total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS death_rate
-- , total_deaths, population
FROM coviddeaths
where continent is not null
-- GROUP BY date
Order By 1, 2;

-- Looking at total population vs vaccinations
-- Using CTE

WITH PopvsVac (continent,
location,
date,
population,
new_vaccinations,
RollingTotalVaccinations)
AS
(
SELECT cd.continent,
cd.location,
cd.date,
cd.population,
cv.new_vaccinations,
SUM(CAST(cv.new_vaccinations as int)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingTotalVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (RollingTotalVaccinations/population) * 100 AS PopVaccinationRate
FROM PopvsVac;

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingTotalVaccinations numeric
)

insert into #PercentPopulationVaccinated
SELECT cd.continent,
cd.location,
cd.date,
cd.population,
cv.new_vaccinations,
SUM(CAST(cv.new_vaccinations as bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingTotalVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2,3
SELECT *, (RollingTotalVaccinations/population) * 100 AS PopVaccinationRate
FROM #PercentPopulationVaccinated;

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent,
cd.location,
cd.date,
cd.population,
cv.new_vaccinations,
SUM(CAST(cv.new_vaccinations as bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingTotalVaccinations
FROM CovidDeaths AS cd
JOIN CovidVaccinations AS cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2,3
;

-- Total Cases vs Total Deaths in US View

CREATE VIEW CasesvsDeathsUS AS
SELECT location,
continent,
date,
total_cases,
total_deaths,
(total_deaths/total_cases) * 100 AS death_rate
FROM CovidDeaths
WHERE location like '%states%'
AND continent is not null
--Order By 1, 2
;



-- Highest Cases Per Country Based on Population View

CREATE VIEW HighestNumberCasesByCountryPopulation AS
SELECT location,
MAX(total_cases) as highest_number_of_cases,
population,
MAX((total_cases/population) * 100) AS infection_rate
FROM CovidDeaths
where continent is null
GROUP BY location,population
-- Order By infection_rate DESC
;

-- Death Count By Country View

CREATE VIEW DeathCountByCountry AS
SELECT location,
MAX(cast(total_deaths AS int)) as total_country_death_count
FROM CovidDeaths
where continent is null
GROUP BY location
-- Order By total_country_death_count DESC;
