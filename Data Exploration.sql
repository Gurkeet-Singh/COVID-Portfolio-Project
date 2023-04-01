SELECT * FROM public."CovidDeaths"
Order by 3,4

SELECT * FROM public."CovidVaccinations"
Order by 3,4

ALTER TABLE public."CovidDeaths"
ALTER COLUMN date TYPE DATE using ("date"::text::date);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Selecting data to be used

SELECT Location, date, total_cases, new_cases, total_deaths
FROM public."CovidDeaths"
Order by 1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total cases vs total deaths
-- Shows how likely an individual suffer death
SELECT Location, date, total_cases, total_deaths, total_deaths/total_cases*100 AS death_ratio
FROM public."CovidDeaths"
Order by 1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Shows number of cases compared to the overall country population
SELECT Location, date, total_cases, population, total_cases/population*100 AS case_percentage
FROM public."CovidDeaths"
WHERE Location like 'India'
Order by 1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Chance of being infected per country
SELECT Location, population, MAX(total_cases), MAX(total_cases/population)*100 AS percentage_population_infected
FROM public."CovidDeaths"
WHERE total_cases IS NOT NULL
GROUP BY 1,2
Order by percentage_population_infected DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Country with most deaths per population
SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM public."CovidDeaths"
WHERE continent IS NOT NULL AND Total_deaths IS NOT NULL
GROUP BY 1
Order by TotalDeathCount DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Getting into continental details
SELECT continent, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY 1
Order by TotalDeathCount DESC

SELECT Location AS continents, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM public."CovidDeaths"
WHERE continent IS NULL
GROUP BY 1
Order by TotalDeathCount DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Cases per day
SELECT date, SUM(total_cases)
FROM public."CovidDeaths"
WHERE total_cases IS NOT NULL
GROUP BY 1
Order by 1,2

SELECT date, SUM(new_cases) AS cases, SUM(new_deaths) AS deaths
FROM public."CovidDeaths"
WHERE new_cases IS NOT NULL
GROUP BY 1
Order by 1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Total
SELECT SUM(new_cases) AS cases, SUM(new_deaths) AS deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM public."CovidDeaths"
WHERE new_cases IS NOT NULL
Order by 1,2

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
ON dea.location = vac.location
AND vac.date = dea.date

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea."location", dea.date) AS vaccination_rolling
FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

WITH PopVsVac(continent, location, date, population, new_vaccinations, vaccination_rolling)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea."location",
	dea.date) AS vaccination_rolling
FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, vaccination_rolling/population*100
FROM PopVsVac

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- New Table
DROP TABLE IF EXISTS Population_vaccinated;

CREATE TABLE Population_vaccinated (
	continent VARCHAR,
	location VARCHAR,
	date DATE,
	population NUMERIC,
	new_vaccinations NUMERIC,
	vaccination_rolling NUMERIC
);

INSERT INTO Population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea."location",
	dea.date) AS vaccination_rolling
FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

SELECT *, vaccination_rolling/population*100 AS percent_vaccinated
FROM Population_vaccinated;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Setting up view
CREATE VIEW Population_vaccinated1 AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea."location",
	dea.date) AS vaccination_rolling
FROM public."CovidDeaths" dea
JOIN public."CovidVaccinations" vac
	ON dea.location = vac.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- New tables with correct locations  
SELECT *
INTO CovidDeathsCleaned
FROM "CovidDeaths"
WHERE continent IS NOT NULL

SELECT *
INTO CovidVaccinatedCleaned
FROM "CovidDeaths"
WHERE continent IS NOT NULL


SELECT location, MAX(date)
INTO vaccinated_today
FROM covidvaccinationscleaned
GROUP BY 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- New table for cases visualization
DROP TABLE IF EXISTS continent_cases;
SELECT continent, location, MAX(total_cases)
INTO continent_cases
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY 1,2;

SELECT continent, SUM(max)
FROM continent_cases
GROUP BY 1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- New table for death visualization
DROP TABLE IF EXISTS continent_deaths;
SELECT continent, location, MAX(total_deaths) AS deaths
INTO continent_deaths
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY 1,2;

SELECT continent, SUM(deaths)
FROM continent_deaths
GROUP BY 1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- New table for vaccine visualization
DROP TABLE IF EXISTS continent_vaccines;
SELECT continent, location, MAX(total_vaccinations) AS deaths
INTO continent_vaccines
FROM "CovidVaccinations"
WHERE continent IS NOT NULL
GROUP BY 1,2;

SELECT continent, SUM(deaths)
FROM continent_vaccines
GROUP BY 1;
