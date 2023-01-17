SELECT *
FROM Covid_Analysis..Deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT *
FROM Covid_Analysis..Vaccinations
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Analysis..Deaths
ORDER BY 1,2

--Looking at total deaths vs total cases to find total death rate in the US
--Shows likelihood of dying if you contract covid

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Covid_Analysis..Deaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Looking at total cases vs population to find total case rate in the US
--Shows what percentage of population got covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS population_infected
FROM Covid_Analysis..Deaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS highest_population_infected
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY highest_population_infected DESC

--Looking at countries with highest death count

SELECT Location, MAX(cast(total_deaths AS BIGINT)) AS total_death_count
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


--Breaking things down by continent


-- Showing continents with the highest death count

SELECT continent, MAX(cast(total_deaths AS BIGINT)) AS total_death_count
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- Global numbers

SELECT SUM(new_cases) AS world_cases, SUM(cast(new_deaths AS BIGINT)) AS world_deaths, (SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases))*100 AS world_death_percentage
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

SELECT date, SUM(new_cases) AS world_cases, SUM(cast(new_deaths AS BIGINT)) AS world_deaths, (SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases))*100 AS world_death_percentage
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


--Looking at total population vs vaccinations

--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_vaccinations
----, (
--FROM Covid_Analysis..Deaths dea
--JOIN Covid_Analysis..Vaccinations vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

-- Use CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_vaccinations
--, (
FROM Covid_Analysis..Deaths dea
JOIN Covid_Analysis..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rolling_vaccinations/population)*100 AS vaccination_percentage
FROM PopvsVac


-- Temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_vaccinations
--, (
FROM Covid_Analysis..Deaths dea
JOIN Covid_Analysis..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rolling_vaccinations/population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_vaccinations
--, (
FROM Covid_Analysis..Deaths dea
JOIN Covid_Analysis..Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

--Queries used for visualization

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS BIGINT)) AS total_deaths, SUM(cast(new_deaths AS BIGINT))/SUM(new_cases)*100 AS death_percentage
FROM Covid_Analysis..Deaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

SELECT location, SUM(CAST(new_deaths AS BIGINT)) AS total_death_count
FROM Covid_Analysis..Deaths
--WHERE location like '%states%'
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_death_count DESC

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM Covid_Analysis..Deaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY percent_population_infected DESC

SELECT location, population, date, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM Covid_Analysis..Deaths
--WHERE location like '%states%'
GROUP BY location, population, date
ORDER BY percent_population_infected DESC