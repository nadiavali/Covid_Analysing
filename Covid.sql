SELECT *
From Covid..covidDeaths
--WHERE continent is not NULL
ORDER BY 3,4


-- select needed data

SELECT location, date, total_cases, new_cases, total_deaths, population
From Covid..covidDeaths
WHERE continent is not NULL
ORDER BY 1, 2




-- Total cases vs Total Deaths percentage in Iran

SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    population,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) * 100 
    END AS deathPercentage
FROM
    Covid..covidDeaths
WHERE LOCATION LIKE '%Iran%'
and continent is not NULL
ORDER BY 
    1,2



-- Total cases Vs Population in France

SELECT 
    location,
    date,
    total_cases,
    population,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 
    END AS covid_people
FROM
    Covid..covidDeaths
WHERE LOCATION LIKE '%France%'
and continent is not NULL
ORDER BY 
    1,2



-- Countries Highest Infection rate compred to population

SELECT 
    location,
    max(total_cases) as highestInfection,
    population,
    CASE
        WHEN max(total_cases) = 0 THEN NULL
        ELSE max((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT))) * 100 
    END AS CovidInfectionPercentage
FROM
    Covid..covidDeaths
where continent is not NULL
GROUP by location, population
ORDER BY 
    CovidInfectionPercentage desc


-- Countries highest death per poulation

SELECT 
    location,
    max(total_deaths) as totalDeath
FROM
    Covid..covidDeaths
where continent is Not NULL -- without that it's showing world and continent as well
GROUP by
    location
ORDER BY 
    totalDeath desc;

-- Same for the continents: but look that numbers are not correct-->It does not sum the total_deaths for all countries in a continent
SELECT 
    continent,
    max(total_deaths) as totalDeath
FROM
    Covid..covidDeaths
where continent is NOT NULL
GROUP by
    continent
ORDER BY 
    totalDeath desc;

-- This is the correct

SELECT 
    location,
    max(total_deaths) as totalDeath
FROM
    Covid..covidDeaths
where continent is NULL
GROUP by
    location
ORDER BY 
    totalDeath desc;

--- same but you can also see the date

SELECT 
    location, date,
    max(total_deaths) as totalDeath
FROM
    Covid..covidDeaths
where continent is NULL
GROUP by
    location, date
ORDER BY 
    1;


-- select 
--     date,
--     sum(new_cases)
--     --total_cases,
--     --total_deaths,
--     case 
--         when total_cases = 0 then null
--         else (cast(total_deaths as float) / cast(total_cases as float)) * 100
--     end as deathPercentage
-- From Covid..covidDeaths
-- where continent is not NULL
-- GROUP by date
-- ORDER by 1,2

-- Global numbers
select 
    date,
    sum(new_cases) as GlobalTotalcases,
    sum(new_deaths) as GlobalTotalDeaths,
    sum(cast(new_deaths as float)) /sum(cast(new_cases as float)) * 100 as globalDeathPercentage
From Covid..covidDeaths
where continent is not NULL and new_cases != 0
GROUP by date
ORDER by 1,2


-- just checking if the first number in Global numbers section is correct
SELECT 
    *
FROM 
    Covid..covidDeaths
WHERE 
    new_deaths > new_cases and continent is null;


SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    --vac.total_vaccinations
    --vac.total_vaccinations / population *100 as totalVaccinationPercentage
    sum(ISNULL(CONVERT(int,vac.new_vaccinations),0)) OVER (PARTITION by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated

FROM Covid..covidDeaths dea
JOIN Covid..covidVaccination vac
    on dea.location = vac.location
    and dea.date = vac.date
WHERE dea.continent is not null
order by dea.location, dea.date;



---CTE Usage

with popVSvac(continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as(

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    -- Uncomment if needed:
    -- ISNULL(vac.total_vaccinations, 0) / NULLIF(dea.population, 0) * 100 AS totalVaccinationPercentage,
    sum(ISNULL(TRY_CONVERT(BIGINT, vac.new_vaccinations), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    --RollingPeopleVaccinated/ dea.population *100 can not use the column that we just created directly   
FROM Covid..covidDeaths dea
JOIN Covid..covidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)
--ORDER BY 2,3))

SELECT *,
    (CAST(RollingPeopleVaccinated as float)/ population) *100 as vaccinatedPercentage
FROM popVSvac



-- Temp table
DROP TABLE if EXISTS #VaccinatedPercentages
Create Table #VaccinatedPercentages
(
continent nvarchar(255),
Location nvarchar(255),
Date DATETIME,
Population NUMERIC(18,2),
new_vaccinations numeric,
RollingPeopleVaccinated FLOAT
);


INSERT INTO #VaccinatedPercentages

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    
    -- Uncomment if needed:
    -- ISNULL(vac.total_vaccinations, 0) / NULLIF(dea.population, 0) * 100 AS totalVaccinationPercentage,
    sum(ISNULL(TRY_CONVERT(BIGINT, vac.new_vaccinations), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    --RollingPeopleVaccinated/ dea.population *100 can not use the column that we just created directly   
FROM Covid..covidDeaths dea
JOIN Covid..covidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3))

SELECT *,
    (CAST(RollingPeopleVaccinated as float)/ Population) *100 as vaccinatedPercentage
FROM #VaccinatedPercentages;

-- Creating view to store data for later data visualizations

CREATE VIEW VaccinatedPercentages as
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    sum(ISNULL(TRY_CONVERT(BIGINT, vac.new_vaccinations), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    --RollingPeopleVaccinated/ dea.population *100 can not use the column that we just created directly   
FROM Covid..covidDeaths dea
JOIN Covid..covidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;

select *
FROM VaccinatedPercentages 