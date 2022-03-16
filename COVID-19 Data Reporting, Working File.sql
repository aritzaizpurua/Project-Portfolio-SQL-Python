/*
CREATED: MARCH 7TH, 2022.
STATUS: WORKING PROJECT
NOTE: UPDATED FILES WILL BE IN GITHUB REPOSITORY

*/

-- View Raw Dataset
SELECT *
FROM COVID19_Analysis..deaths
ORDER BY 3, 4

-- Select data that we are using
SELECT Location, date, population, total_cases, new_cases, total_deaths
FROM COVID19_Analysis..deaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths (case_pct AS Likelihood of Dying)
	-- Data starts at January 2020 up until March 7th, 2022
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) as death_pct
FROM COVID19_Analysis..deaths
ORDER BY Location, date 

-- US statistics, 79 million cases have been found as of March 7th, 2022
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) as death_pct
FROM COVID19_Analysis..deaths
WHERE Location like '%states%' AND continent IS NOT NULL
ORDER BY date DESC, total_cases

-- Date where death percentage hit the highest in the US: March 2nd, 2020 | 10.90%
SELECT TOP 1 Location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) as death_pct
FROM COVID19_Analysis..deaths
WHERE Location LIKE '%states%' AND continent IS NOT NULL
ORDER BY death_pct DESC

-- Total Cases vs Population

	-- Pct of population that has gotten COVID19
SELECT Location, date, Population, total_cases, (total_cases/Population * 100) as case_pct
FROM COVID19_Analysis..deaths
WHERE Location LIKE '%states%'
ORDER BY 1, 2

	-- Highest ratios of infection vs population
SELECT Location, Population, MAX(total_cases) AS MaxInfectionCount, MAX((total_cases/Population)) * 100 
	AS MaxPopulationInfected
FROM COVID19_Analysis..deaths
WHERE Location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MaxPopulationInfected DESC

	-- Countries with highest death count compared to population
SELECT Location, Population, MAX(CAST(total_deaths AS INT)) AS MaxDeathCount
FROM COVID19_Analysis..deaths
WHERE Location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MaxDeathCount DESC

	-- Countries with highest death count percentage compared to population
SELECT Location, Population, MAX(CAST(total_deaths AS INT)/Population) * 100 
	AS MaxDeathPct
FROM COVID19_Analysis..deaths
WHERE Location NOT LIKE '%income%' AND continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MaxDeathPct DESC

	-- Viewing Death Count AND Death Count Percentage vs Population for income classes
SELECT Location, Population, MAX(CAST(total_deaths AS INT)) AS MaxDeathCount, MAX(CAST(total_deaths AS INT)/Population) * 100 
	AS MaxDeathPct
FROM COVID19_Analysis..deaths
WHERE Location LIKE '%income%'
GROUP BY Location, Population
ORDER BY MaxDeathCount DESC

-- DISSECTING DATA BY CONTINENT

	--Showing continents with highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS death_count
FROM COVID19_Analysis..deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY death_count DESC

-- GLOBAL NUMBERS BY DATE

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 as death_pct
FROM COVID19_Analysis..deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2 

-- GLOBAL NUMBERS IN TOTAL AS OF MARCH 7TH, 2022

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 as death_pct
FROM COVID19_Analysis..deaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2 


-- Vaccination Table Analysis

-- View the data

SELECT * 
FROM COVID19_Analysis..vaccinations
ORDER BY 3, 4

-- Join tables of deaths and vaccinations and order by location/date

SELECT *
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date
ORDER BY d.location, d.date

-- Looking at Total Population vs Vaccinations. How many people are vaccinated?

-- USING CTE, We view the percentage of people vaccinated as time passes by per continent and location.

WITH PopVsVac(Continent, Location, Date, Population, New_Vaccinations, RollingCountVaccinatedPeople)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location 
	ORDER BY d.location, d.date) AS RollingCountVaccinatedPeople
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
-- ORDER BY d.continent, d.location, d.date
)
SELECT *, (RollingCountVaccinatedPeople/Population) * 100 AS vaccinated_pct
FROM PopVsVac
ORDER BY Continent, Location, Date

-- USING TEMP TABLE

DROP TABLE IF EXISTS #VaccinatedPopulationPct
CREATE TABLE #VaccinatedPopulationPct
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountVaccinatedPeople numeric
)

INSERT INTO #VaccinatedPopulationPct
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location 
	ORDER BY d.location, d.date) AS RollingCountVaccinatedPeople
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (RollingCountVaccinatedPeople/Population) * 100 AS vaccinated_pct
FROM #VaccinatedPopulationPct
ORDER BY Continent, Location, Date

-- Creating a VIEW to store data for later visualization

CREATE VIEW VaccinatedPopulationPct AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
	SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location 
	ORDER BY d.location, d.date) AS RollingCountVaccinatedPeople
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
