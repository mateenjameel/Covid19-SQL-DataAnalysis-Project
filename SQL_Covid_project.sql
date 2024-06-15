SELECT *
FROM covid_deaths
ORDER BY 3,4


SELECT location, COUNT(location)
FROM COVID_DEATHS
WHERE continent IS NOT NULL
GROUP BY LOCATION
ORDER BY location


-- SELECTING DATA TO BE USE
SELECT location, date,population,total_cases, new_cases
FROM covid_deaths
ORDER BY 1,2


-- LOOKING AT TOTAL CASES VS TOTAL DEATHS
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS Death_Percenteage
FROM covid_deaths
WHERE location LIKE '%Australia%'
ORDER BY 1,2


--Looking at Total cases vs population
SELECT location, date, population, total_cases, (total_cases / population) * 100 AS Percent_Population_Affected
FROM covid_deaths
WHERE location LIKE '%Australia%'
ORDER BY 1,2


--Looking at countries with higest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count , MAX((total_cases / population)) * 100 AS higest_Infection_Percenatge
FROM covid_deaths
GROUP BY location, population
ORDER BY higest_Infection_Percenatge DESC


--LOOKING AT COUNTRIES WITH HIGHEST DEATH COUNTS
SELECT location, population, MAX(total_deaths) AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Total_Death_Count DESC


--BREAKING THINGS BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC


SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC


--Calculating Total Population by Continent
SELECT continent, SUM(population) AS Total_Population
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Population DESC



--CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(CAST(total_deaths AS INT)) AS Total_Death_Count, MAX(CAST(total_deaths AS INT) / POPULATION) AS Highest_Death_Percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC


--GLOBAL NUMBERS  (around the World)
SELECT date, SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100
END AS Death_Percentage

FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date,Total_Deaths DESC


--Total Cases and Total Deaths around the world
SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS Total_Deaths, 
	SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS Death_Percentage

FROM covid_deaths
WHERE continent IS NOT NULL



--JOINING TWO TABLES

SELECT *
FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location


-- LOOKING AT TOTAL_POPULATION VS VACCINATION
SELECT cd.continent, cd.location,cd.date, cd.population, cv.new_vaccinations
FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location

WHERE cd.continent IS NOT NULL
ORDER BY 2,3



SELECT cd.continent, cd.location,cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.LOCATION) Sum_NewVaccinations 
FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location

WHERE cd.continent IS NOT NULL
ORDER BY 2,3


-- Using Partion by to Sum all New_Vaccinations Record based on Rolling Total
SELECT cd.continent, cd.location,cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.LOCATION ORDER BY cd.location, cd.date) Rolling_Sum_Vaccinations
FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location

WHERE cd.continent IS NOT NULL
ORDER BY 2,3


--Using  CTE TO CALCULATE Vaccination_Percentage
WITH POPL_VS_VACCIN AS
(SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Rolling_Sum_Vaccinations

FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location
	WHERE cd.continent IS NOT NULL)

SELECT *, (POPL_VS_VACCIN.Rolling_Sum_Vaccinations / POPL_VS_VACCIN.population) * 100 AS Vaccination_Percantage
FROM POPL_VS_VACCIN;


--COUNTRY HAVING HIGHEST VACCINATION PERCENTAGE 
WITH POPL_VS_VACCIN AS
(SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Rolling_Sum_Vaccinations

FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location
	WHERE cd.continent IS NOT NULL)

SELECT TOP 1 *, (POPL_VS_VACCIN.Rolling_Sum_Vaccinations / POPL_VS_VACCIN.population) * 100 AS Vaccination_Percantage
FROM POPL_VS_VACCIN
ORDER BY Vaccination_Percantage DESC


-- USING TEMP TABLE
DROP TABLE IF EXISTS #PERCENT_POPULATION_VACCINATION

CREATE TABLE #PERCENT_POPULATION_VACCINATION

(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_Sum_Vaccination numeric)


-- Insert data into the temporary table
INSERT INTO #PERCENT_POPULATION_VACCINATION
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(COALESCE(cv.new_vaccinations, 0) AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Rolling_Sum_Vaccinations

FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location


--SELCT WITH VACCINATION PERCENTAGE
SELECT *, (Rolling_Sum_Vaccination / Population) * 100 AS Vaccination_Percentage
FROM #PERCENT_POPULATION_VACCINATION


--CREATING VIEW TO STORE DATA FOR VISUALIZATION
CREATE VIEW PERCENT_POPULATION_VACCINATIONS AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(COALESCE(cv.new_vaccinations, 0) AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Rolling_Sum_Vaccinations

FROM covid_deaths AS cd
JOIN covid_vaccinations AS cv
	ON cd.date = cv.date
	AND cd.location = cv.location

WHERE cd.continent IS NOT NULL

SELECT *
FROM PERCENT_POPULATION_VACCINATIONS
