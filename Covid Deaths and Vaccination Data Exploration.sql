--LOOKING AT OUT DATA
SELECT *
FROM CovidDeaths

SELECT * 
FROM CovidVaccinations

--SELECTING THE DATA I WILL BE USING

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths

-- CALCULATING THE CHANCE OF DEATH(DEATH PERCENTAGE)

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
,(cast(total_deaths AS INT)/ total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates
ORDER BY 1, 2


-- CALCULATING THE INFECTION RATE(INFECTION PERCENTAGE) 

SELECT continent, location, date, total_cases, new_cases, total_deaths, population
,(total_cases/ population) * 100 AS Infection_Percentage
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates
ORDER BY 1, 2


-- CALCULATING THE HIGHEST INFECTION RATE COUNTRIES PER POPULATION PERCENTAGE (PER-REGION not CONTINENT)

SELECT continent, location, MAX(total_cases) AS total_cases, population, (MAX(total_cases)/population) * 100 AS Infection_Rate
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates
GROUP BY continent, location, population
ORDER BY 1, 2

-- CALCULATING COVID-19 CASUALITES AND HIGHEST DEATH PERCENTAGE - HIGHEST DEATHCOUNT PER POPULATION - (UP TO MID 2021)

------------------------------------------------ CASUALTIES -------------------------------------------

SELECT continent, location, population, MAX(CONVERT(INT, total_deaths))
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent, location, population
ORDER BY 1, 2

------------------------------------------------ PERCENTAGE --------------------------------------------

WITH highestDP (continent, location, population, highest_deathcount) AS
(
SELECT continent, location, population, MAX(CONVERT(INT, total_deaths))
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
)

SELECT *, (highest_deathcount/population)*100 AS HDCPercentage 
FROM highestDP
ORDER BY 1, 2


-- we can calculate the continental scale using our previous query by altering it a little-bit
---------------------------------------------- CONTINENTAL SCALE ----------------------------------------

SELECT location, population, MAX(CONVERT(INT, total_deaths)) AS HighestDeathCount
FROM CovidDeaths
WHERE continent IS  NULL
AND LOCATION != 'World' 
AND LOCATION != 'International'
GROUP BY continent, location, population
ORDER BY 1, 2

-- this can happen because the structure of our data has the overall summary of covid information on continental scale

-- GLOBAL NUMBERS
-- GLOBAL DEATH PERCENTAGE PER-DAY

SELECT date, SUM(new_cases) AS total_infection, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases)) AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

-- GLOBAL DEATH PERCENTAGE

SELECT  SUM(new_cases) AS total_infection, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases)) AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL


-- JOINING THE DEATH AND VACCINATION TABLE 

SELECT *
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
ORDER BY 1, 2


-- LOOKING AT THE DATA WE'RE GOING TO BE USING IN THE JOIN 

SELECT death.continent, death.location, death.date, death.total_cases, death.new_cases, death.total_deaths, death.population,
vac.new_vaccinations
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL 
ORDER BY 2, 3

-- WE'LL BE USING ROLLING COUNT OF PEOPLE VACCINATED --


SELECT death.continent, death.location, death.date, death.total_cases, death.new_cases, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollVaccinatedCount
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL 
ORDER BY 2, 3

-- TO ADD THE PERCENTAGE OF ROLL COUNT, IM USING A CTE TO MAKE IT MORE ORGANIZED AND EASIER


WITH VacPercentage(continent, location, date, total_cases, new_cases, population, new_vaccinations, rollvaccinationcount) AS (
SELECT death.continent, death.location, death.date, death.total_cases, death.new_cases, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollVaccinatedCount
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL 
)

SELECT *, (rollvaccinationcount/population)*100 AS percentageRollVac
FROM VacPercentage
order by 2, 3

-- WE CAN ALSO USE TEMPORARY TABLES TO ESTABLISH THIS :

DROP TABLE IF EXISTS #VacPercentage
CREATE TABLE #VacPercentage (
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	total_cases numeric, 
	new_cases numeric, 
	population numeric, 
	new_vaccinations numeric, 
	rollvaccinationcount numeric
	)

INSERT INTO #VacPercentage
SELECT death.continent, death.location, death.date, death.total_cases, death.new_cases, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollVaccinatedCount
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL

SELECT *, (rollvaccinationcount/population)*100 AS percentageRollVac
FROM #VacPercentage
order by 2, 3

-- CREATING VIEW FOR LATER DATA VISUALIZATIONS :

CREATE VIEW DeathPercentage AS
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
,(cast(total_deaths AS INT)/ total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates

CREATE VIEW InfectionRate AS
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
,(total_cases/ population) * 100 AS Infection_Percentage
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates

CREATE VIEW HighestInfectionRatePerCountries AS
SELECT continent, location, MAX(total_cases) AS total_cases, population, (MAX(total_cases)/population) * 100 AS Infection_Rate
FROM CovidDeaths
WHERE continent IS NOT NULL --Because the Structure of our imported data, we need to use this clause in order to avoid duplicates
GROUP BY continent, location, population

CREATE VIEW CasualtiesPercentage AS
WITH highestDP (continent, location, population, highest_deathcount) AS
(
SELECT continent, location, population, MAX(CONVERT(INT, total_deaths))
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
)

SELECT *, (highest_deathcount/population)*100 AS HDCPercentage 
FROM highestDP


CREATE VIEW ContinentalHighDeathCount AS
SELECT location, population, MAX(CONVERT(INT, total_deaths)) AS HighestDeathCount
FROM CovidDeaths
WHERE continent IS  NULL
AND LOCATION != 'World' 
AND LOCATION != 'International'
GROUP BY continent, location, population

CREATE VIEW GlobalDeathPercentagePerDay AS
SELECT date, SUM(new_cases) AS total_infection, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases)) AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

CREATE VIEW GlobalDeathPercentage AS
SELECT  SUM(new_cases) AS total_infection, SUM(cast(new_deaths AS INT)) AS total_deaths, (SUM(cast(new_deaths AS INT))/SUM(new_cases)) AS GlobalDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL

CREATE VIEW PercentagePeopleVaccinated AS
WITH VacPercentage(continent, location, date, total_cases, new_cases, population, new_vaccinations, rollvaccinationcount) AS (
SELECT death.continent, death.location, death.date, death.total_cases, death.new_cases, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollVaccinatedCount
FROM CovidDeaths death
JOIN CovidVaccinations vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL 
)

SELECT *, (rollvaccinationcount/population)*100 AS percentageRollVac
FROM VacPercentage
