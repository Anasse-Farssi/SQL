-----------------------     https://ourworldindata.org/covid-deaths     ----------------------- 


SELECT  * FROM cov19..cases 
SELECT  * FROM cov19..vac
SELECT  * FROM cov19..newdt
DELETE FROM cov19..cases WHERE continent IS NULL
DELETE FROM cov19..vac WHERE continent IS NULL
DELETE FROM cov19..newdt WHERE continent IS NULL

-----how many people get infected 
-----Countries with Highest Infection Rate compared to Population
				--CREATE VIEW infection_percentage
				--AS 
	SELECT location, population,
	MAX(	total_cases)AS Cases,
	MAX(	total_cases/population)*100
	AS infection_percentage
	FROM cov19..cases 
	--WHERE location LIKE '%CCO'
	GROUP BY location,population
	ORDER BY 4 DESC

-----percentage of cases out of tests

				--CREATE VIEW 
				--cases_per_tests_percentage
				--AS 

	SELECT 
	continent,	location,	date,
	total_tests,	total_cases,
	ROUND(	CAST(	total_cases AS float)/
	CONVERT(	float,	total_tests)*100,2)
	As positive_cases_out_of_tests 
	FROM cov19..cases
	WHERE total_tests >=1
	--AND LOCATION LIKE '%cco'
	ORDER BY date,positive_cases_out_of_tests DESC

----- PERCENTAGE OF DEATHS FROM CASES

	SELECT 
	continent,	location,	date,
	total_cases,	total_deaths,
	ROUND(	CAST(	total_deaths AS FLOAT)/
	CONVERT(	FLOAT,	total_cases)*100,2)
	As death_percentage
	FROM cov19..cases
	WHERE total_cases >= 1
	ORDER BY 1,3,5 DESC

----- DEATH PERCENTAGE for each country

	SELECT 
	location,
	MAX(	population) 'population',
	MAX(	CAST(	total_deaths AS INT )) total_deaths,
	CONVERT(	DECIMAL(10,5),
	MAX(	total_deaths /population)*100)
	As death_per_country
	FROM cov19..cases
	WHERE total_deaths >= 1
	GROUP BY location
	ORDER BY location,death_per_country


----- TESTS PERCENTAGE OF EACH COUNTRY, AND NUMBER OF TESTS FOR EACH PERSON 

	SELECT 
	location,	
	MAX(	population) AS 'population',
	MAX(	CAST(	total_tests AS bigint )) total_tests,
	CONVERT(	DECIMAL(10,3),
	MAX(	total_tests /population)*100)
	As tests_percentage,
	CONVERT(	DECIMAL(10,3),
	MAX(	total_tests /population))
	As tests_per_person
	FROM cov19..cases
	where total_tests IS NOT NULL
	GROUP BY location
	ORDER BY tests_percentage desc

--GLOBALY

--1-INTERNATIONAL

	SELECT
	SUM(	DISTINCT cases.population) AS population,
	SUM(	newdt.new_cases) as total_cases,
	SUM(	cast(newdt.new_deaths as int)) as total_deaths, 
	SUM(	cast(newdt.new_deaths as int))	/
	SUM(	newdt.New_Cases)*100 as DeathPercentage
	FROM    cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date


--2-By continent

	SELECT 
	cases.continent,
	SUM(	DISTINCT population) as population ,
	SUM(	newdt.new_cases) as total_cases,
	SUM(	CAST(	newdt.new_deaths AS INT)) AS total_deaths, 
	SUM(	CAST(	newdt.new_deaths AS INT))	/ 
	SUM(	newdt.New_Cases)*100 as DeathPercentage
	FROM cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	GROUP BY cases.continent
	ORDER BY 2  DESC

-- 3-BY COUNTRY
	
	SELECT 
	cases.location,
	Max(	cases.population	) 
	OVER(	PARTITION BY cases.location ) as population ,
	SUM(	newdt.new_cases) AS total_cases,
	SUM(	cast(	newdt.new_deaths AS INT	)	) AS total_deaths, 
	SUM(	convert(	INT,newdt.new_deaths)	)	/ 
	SUM(	newdt.New_Cases	)*100 AS DeathPercentage
	FROM cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	WHERE total_cases IS NOT NULL 
	AND total_deaths IS NOT NULL
	GROUP BY cases.location,population
	ORDER BY location,5 DESC


--		Vaccinations

-- Total Population vs Vaccinations
----People that has recieved at least one Covid Vaccine

	SELECT cases.continent, 
	cases.location, 
	cases.date, 
	cases.population, 
	newdt.new_vaccinations,
	SUM(	CONVERT(bigint,newdt.new_vaccinations))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS RollingPeopleVaccinated
	FROM COV19..cases AS cases
	JOIN cov19..newdt as newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	WHERE newdt.new_vaccinations IS NOT NULL

----CTE----

	WITH population_vs_vac (	
	Continent,
	Location,
	Date,
	Population,
	New_Vaccinations,
	RollingPeopleVaccinated	) 
	AS 
	(	SELECT cases.continent, 
	cases.location, 
	cases.date, 
	cases.population, 
	newdt.new_vaccinations,
	SUM(	CONVERT(	bigint,newdt.new_vaccinations))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS RollingPeopleVaccinated
	FROM COV19..cases AS cases
	JOIN cov19..newdt as newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	WHERE newdt.new_vaccinations IS NOT NULL	)
	select *,
	(RollingPeopleVaccinated /population)*100 
	as vac_percentage  from population_vs_vac 

--temp table 

	DROP Table if exists #Per_pop_vaccinated
	Create Table #Per_pop_vaccinated
	(Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric)

	Insert into #Per_pop_vaccinated
	SELECT cases.continent, 
	cases.location, 
	cases.date, 
	cases.population, 
	newdt.new_vaccinations,
	SUM(	CONVERT(	bigint,newdt.new_vaccinations))
	OVER (Partition by cases.Location ORDER BY
	cases.location,  cases.date
	ROWS UNBOUNDED PRECEDING)
	AS RollingPeopleVaccinated
	FROM COV19..cases AS cases
	JOIN cov19..newdt as newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	WHERE newdt.new_vaccinations IS NOT NULL

	Select *,(RollingPeopleVaccinated/Population)*100 
	AS percentage
	FROM #Per_pop_vaccinated

	SELECT continent ,Avg (RollingPeopleVaccinated/Population)*100 AS PR_VACCINATIONS
	FROM #Per_pop_vaccinated
	GROUP BY Continent 
	ORDER BY PR_VACCINATIONS DESC

	-- Total Population vs Vaccinations

----People fully vaccinated 

----CTE----

	WITH population_vs_vac (	
	Continent,
	Location,
	Date,
	Population,
	fully_vaccinated,
	people_fully_vaccinated	) 
	AS 
	(	SELECT cases.continent, 
	cases.location, 
	cases.date, 
	cases.population, 
	vac.fully_vaccinated,
	max(	CONVERT(	bigint,vac.fully_vaccinated))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS 	people_fully_vaccinated
	FROM COV19..cases AS cases
	JOIN cov19..vac as vac 
	ON cases.location = vac.location
	AND
	cases.date = vac.date
	WHERE vac.fully_vaccinated IS NOT NULL	)
	
	select *,(people_fully_vaccinated /population)*100 
	as fully_vac_percentage  from population_vs_vac 
	

	--temp table 

	DROP Table if exists #Per_pop_fully_vaccinated
	Create Table #Per_pop_fully_vaccinated
	(Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	fully_vaccinated numeric,
	people_fully_vaccinated numeric)

	Insert into #Per_pop_fully_vaccinated
	SELECT cases.continent, 
	cases.location, 
	cases.date, 
	cases.population, 
	vac.fully_vaccinated,
	MAX(	CONVERT(	bigint,vac.fully_vaccinated))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS 	people_fully_vaccinated
	FROM COV19..cases AS cases
	JOIN cov19..vac AS vac 
	ON cases.location = vac.location
	AND
	cases.date = vac.date
	WHERE vac.fully_vaccinated IS NOT NULL
	

	SELECT 
	continent,	location,
	date,	population,
	people_fully_vaccinated,
	(people_fully_vaccinated /population)*100 
	AS fully_vac_percentage  
	FROM #Per_pop_fully_vaccinated 
	ORDER BY continent,location, date



	SELECT location , MAX(people_fully_vaccinated /population)*100 
	AS fully_vac_percentage FROM #Per_pop_fully_vaccinated
	group by Location
	order by location

	
--CREATING VIEW -------------------------------------------------------------------------------------------------------------------

	GO
	CREATE VIEW VIEW_T_1 AS	
	WITH CTE_VIEW_1(continent,location, 
	date , population,
	total_cases,new_deaths,
	death_percent_cases,
	total_tests,
	positive_percentage
	,new_vaccinations,rolling_new_vaccinations,
	people_fully_vaccinated)
	AS( 
	SELECT cases.continent, 
	cases.location, 
	CONVERT(DATE,cases.date) AS DATE, 
	cases.population,
	cases.total_cases,
	newdt.new_deaths,
	ROUND(	CAST(	cases.total_deaths AS FLOAT)/
	CONVERT(	FLOAT,	cases.total_cases)*100,2)
	As death_percent_cases,
	cases.total_tests,
	ROUND(	CAST(	cases.total_cases AS float)/
	CONVERT(	float,	cases.total_tests)*100,2)
	As positive_percentage_out_of_tests ,
	newdt.new_vaccinations,
	SUM(	CONVERT(bigint,newdt.new_vaccinations))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS rolling_new_vaccinations,
	MAX(	CONVERT(	bigint,vac.fully_vaccinated))
	OVER(	Partition by cases.Location ORDER BY
	cases.location, cases.date 
	ROWS UNBOUNDED PRECEDING)
	AS 	people_fully_vaccinated
	FROM COV19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	JOIN COV19..VAC AS vac
	ON
	VAC.location = newdt.location
	AND
	VAC.date = newdt.date)
	SELECT *,(people_fully_vaccinated /population)*100 
	AS fully_vac_percentage,(rolling_new_vaccinations/population)*100 
	AS new_vac_percentage FROM CTE_VIEW_1
	GO
	SELECT * FROM  VIEW_T_1
--------------------------------------------------------------------------------------------------------------------------------
	CREATE VIEW GROUPED_CO
	AS
	SELECT cases.location,
	MAX(	cases.population) 'population',
	MAX(	cases.total_cases)AS Cases,
	MAX(	cases.total_cases/cases.population)*100
	AS infected_in_country ,
	MAX(	CAST(	cases.total_tests AS bigint )) total_tests,
	CONVERT(	DECIMAL(10,3),
	MAX(	cases.total_tests /cases.population)*100)
	AS tests_percentage,
	CONVERT(	DECIMAL(10,3),
	MAX(	cases.total_tests /population))
	AS tests_per_person,
	MAX(	CAST(	cases.total_deaths AS INT )) total_deaths,
	SUM(	convert(	INT,newdt.new_deaths)	)	/ 
	SUM(	newdt.New_Cases	)*100 AS Death_Per_cases,
	CONVERT(	DECIMAL(10,5),
	MAX(	cases.total_deaths /cases.population)*100)
	As death_per_country
	FROM cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	GROUP BY cases.location,population
	ORDER BY location,5 DESC

--------------------------------------------------------------------------------------------------------------------------------
	
--	GLOBALY
CREATE VIEW GLOBAL
	AS
	SELECT
	SUM(	DISTINCT cases.population) AS population,
	SUM(	newdt.new_cases) as total_cases,
	SUM(	cast(newdt.new_deaths as int)) as total_deaths, 
	SUM(	cast(newdt.new_deaths as int))	/
	SUM(	newdt.New_Cases)*100 as DeathPercentage
	FROM    cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date

--	By continent
	
	CREATE VIEW BY_CONTINENT
	AS
	SELECT 
	cases.continent,
	SUM(	DISTINCT population) as population ,
	SUM(	newdt.new_cases) as total_cases,
	SUM(	CAST(	newdt.new_deaths AS INT)) AS total_deaths, 
	SUM(	CAST(	newdt.new_deaths AS INT))	/ 
	SUM(	newdt.New_Cases)*100 as DeathPercentage,
	CONVERT(FLOAT,SUM(	newdt.new_cases) / MAX(cases.total_tests)*100)
	As positive_cases_out_of_tests_PERCENTAGE,
	(SUM(	newdt.new_cases) / sum(distinct population)) *100 
	AS infection_percentage
	FROM cov19..cases AS cases
	JOIN cov19..newdt AS newdt 
	ON cases.location = newdt.location
	AND
	cases.date = newdt.date
	join cov19..vac as vac 
	ON newdt.location = vac.location
	AND
	newdt.date = vac.date
	GROUP BY cases.continent



