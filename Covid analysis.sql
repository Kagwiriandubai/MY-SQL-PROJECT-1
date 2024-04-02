SELECT *
FROM dbo.CovidDeaths$
ORDER BY 3,4,5


SELECT *
FROM dbo.CovidVaccinations$
ORDER BY 1,2,3

--select data that we will be using 

SELECT location, total_cases, new_cases, date,  population
FROM dbo.CovidDeaths$
ORDER BY 1,2,3

--calculating the probability of catching a virus
--Total cases vs population


SELECT location, date, new_cases, population, (total_cases/population)*100 AS pdr
FROM dbo.CovidDeaths$
WHERE location LIKE '%states%'
ORDER BY 1,2,3

---looking at total cases vs total death cases

SELECT location,total_deaths, total_cases, date, (total_deaths/total_cases)*100 AS deathpercentage
FROM dbo.CovidDeaths$
WHERE location LIKE '%states%'
ORDER BY 1,2,3

--Looking at countries with the highest infection rate


SELECT --date,
location,population,MAX(total_cases) AS HighestInfectionCount, MAX((total_deaths/total_cases)*100) AS
PercentagePopulationIffected
FROM dbo.CovidDeaths$
--WHERE location LIKE '%states%'
GROUP BY location, population --,date
ORDER BY PercentagePopulationIffected DESC

--showing continet with highest death count per population


SELECT location,MAX(CAST (total_deaths AS INT)) AS HighestDeathCount
FROM dbo.CovidDeaths$
--WHERE location LIKE '%states%'
WHERE continent is NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

---Global Numbers for new cases, total deaths and infection percentage 
SELECT continent,-- SUM(new_cases) AS TotalNewCases,
SUM(CAST(total_deaths AS INT)) AS TotalDeaths 
--(SUM(new_cases)/SUM(CAST(total_deaths AS INT)))*100 AS InfectionPercentage
FROM dbo.CovidDeaths$
WHERE continent is not null
GROUP BY continent
Order By TotalDeaths DESC 

----total deaths,total newcases and infection percentage 
SELECT SUM(total_cases) AS TotalCases, SUM(CAST(total_deaths AS INT)) AS TotalDeaths, 
(SUM(CAST(total_deaths AS INT))/SUM(total_cases))*100 AS InfectionPercentage
FROM dbo.CovidDeaths$
WHERE continent is not null
---GROUP BY date
Order By 1, 2

--joining the covid deaths table and the covid vccination table 
SELECT *
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date

---looking for total population versus vaccinations 
SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null
ORDER BY 2, 3

----Default rationing SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations
SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations, SUM(CAST (dcv.new_vaccinations AS INT)) OVER
(PARTITION BY dcd.location ORDER BY dcd.location, dcd.date) AS Rotationalvaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null
ORDER BY 2, 3

----USE CTE'S
WITH PopvsVac (location, continent, date, population, new_vaccinations, Rotationalvaccinations)
AS
(
SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations, SUM(CAST (dcv.new_vaccinations AS INT)) OVER
(PARTITION BY dcd.location ORDER BY dcd.location, dcd.date)  AS Rotationalvaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null
)
SELECT *, (Rotationalvaccinations/population)*100
FROM PopvsVac 


----using temp tables
 CREATE TABLE #PercentPopulationVaccinated
 (
 location nvarchar(255),
 continent nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 Rotationalvaccinations numeric,
 )
 INSERT INTO #PercentPopulationVaccinated

 SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations, SUM(CAST (dcv.new_vaccinations AS INT)) OVER
(PARTITION BY dcd.location ORDER BY dcd.location, dcd.date)  AS Rotationalvaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null

SELECT *, (Rotationalvaccinations/population)*100
FROM #PercentPopulationVaccinated

---creating the view for later visualization

CREATE VIEW POPULATIONVERSUSVACCINATION AS
SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null
--ORDER BY 2, 3


---view for rotationed new vaccination 

CREATE VIEW Rotationalvaccinations AS
SELECT dcd.location, dcd.continent, dcd.date, population, dcv.new_vaccinations, SUM(CAST (dcv.new_vaccinations AS INT)) OVER
(PARTITION BY dcd.location ORDER BY dcd.location, dcd.date) AS Rotationalvaccinations
FROM dbo.CovidDeaths$ dcd
JOIN dbo.CovidVaccinations$ dcv
ON dcd.location=dcv.location
AND dcd.date=dcv.date
WHERE dcd.continent is not null
--ORDER BY 2, 3