--MIGHT WANT TO CREATE A STORED PROCEDURE, VIEW OR SOMETHING SIMILAR TO QUERY OFF OF IT FOR ALL THE QUESTIONS?

---------------------------------------------------------------------------------------------------

--STANDBY - 1.What is the average of vaccinations per month per continent?

DROP TABLE IF EXISTS #AverageVax --DEVELOP THIS TEMP TABLE MORE
SELECT *
INTO #AverageVax
FROM COVID19_Analysis..vaccinations

/* THIS IS FOR THE END QUERY ONCE WE HAVE PERFORMED CALCULATIONS: 
WHERE (Day(date) BETWEEN 30 AND 31) OR (Month(date) = 02 AND Day(Date) BETWEEN 28 AND 29) */

SELECT continent, location, date, total_vaccinations AS world_vax, new_vaccinations AS new_vax, SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location, date) AS sum_vax--continent, total_vaccinations
FROM #AverageVax
WHERE continent IS NOT NULL AND (Day(date) = 01)

--WHERE CONVERT(date, date) LIKE  '%-30' AND CONVERT(datetime, date) LIKE '%-31'

---------------------------------------------------------------------------------------------------

--STANDBY - 2.How many new cases for each month for each location?

DROP TABLE IF EXISTS #NewCases
SELECT continent, iso_code, location, date, population, new_cases
INTO #NewCases
FROM COVID19_Analysis..deaths

SELECT continent, location, date, new_cases, SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date) AS count_newcases
FROM #NewCases
WHERE continent IS NOT NULL --FIGURE OUT >>>>>>> HOW TO FILTER FOR EACH MONTH (MAYBE CONVERT THIS QUERY INTO THE ACTUAL TEMP TABLE AND THEN QUERY OFF OF IT????)
ORDER BY location, date

---------------------------------------------------------------------------------------------------

--ANSWERED - 3.What is the 5th largest country, by vaccination count, in each continent.
DROP TABLE IF EXISTS #CountryVax
SELECT d.continent,
		d.iso_code, 
		d.location,
		SUM(CAST(v.new_vaccinations AS BIGINT)) AS totalvax, 
		ROW_NUMBER() OVER (PARTITION BY d.continent ORDER BY d.location) AS row_num
INTO #CountryVax
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date
GROUP BY d.continent, 
			d.iso_code, 
			d.location

SELECT *
FROM #CountryVax
WHERE continent IS NOT NULL AND row_num = 5
--CHECK THE NULLS AND WHY? ANSWER: In Africa and Oceania, there are locations with no vaccination data, perhaps vaccination supplies never arrived.

---------------------------------------------------------------------------------------------------

--ANSWERED - 4.For location='Belgium', what is the net change in vacinations for each day.
-- For net change use (Xn/Xn-1) - 1 for % or (Xn - Xn-1) for number

DROP TABLE IF EXISTS #BelgiumVax
SELECT d.iso_code, 
		d.location,
		v.date,
		v.new_vaccinations,
		SUM(CAST(v.new_vaccinations AS BIGINT)) OVER (PARTITION BY d.location ORDER BY d.location, v.date) AS SUMnew_vax
INTO #BelgiumVax
FROM COVID19_Analysis..deaths d
JOIN COVID19_Analysis..vaccinations v
	ON d.location = v.location AND d.date = v.date --IS THIS JOIN REALLY NECESSARY? I DONT THINK SO, DIG FURTHER.
WHERE d.location = 'Belgium' 
ORDER BY d.location, 
			v.date

WITH BelgiumCTE AS (
SELECT *, LAG(SUMnew_vax, 1) OVER (PARTITION BY location ORDER BY date) as lagSUMnew_vax
FROM #BelgiumVax
)

SELECT iso_code, location, date, SUMnew_vax, (CAST(SUMnew_vax AS BIGINT) - lagSUMnew_vax) AS netchg_vax
FROM BelgiumCTE

---------------------------------------------------------------------------------------------------

--STANDBY - 5.What is the 90th, 95th and 99th percentile of vacinnations per day for all locations.

DROP TABLE IF EXISTS #PercentileVax
SELECT  location,
		date,
		new_vaccinations,
		AVG(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY location ORDER BY location) AS avg_vax
	--	CASE WHEN PERCENT_RANK() OVER (PARTITION BY location ORDER BY location, date) > 0.90
	--	THEN '90th'
	--	WHEN PERCENT_RANK() OVER (PARTITION BY location ORDER BY location, date) > 0.95
	--	THEN '95th'
	--	WHEN PERCENT_RANK() OVER (PARTITION BY location ORDER BY location, date) > 0.99
	--	THEN '99th'
	--END AS percentile
INTO #PercentileVax
FROM COVID19_Analysis..vaccinations v
GROUP BY location,
		date,
		new_vaccinations
ORDER BY location,
		avg_vax

SELECT location,
		avg_vax,
		CASE WHEN PERCENT_RANK() OVER (PARTITION BY avg_vax ORDER BY location) > 0.90
		THEN '90th'
		WHEN PERCENT_RANK() OVER (PARTITION BY avg_vax ORDER BY location) > 0.95
		THEN '95th'
		WHEN PERCENT_RANK() OVER (PARTITION BY avg_vax ORDER BY location) > 0.99
		THEN '99th'
	END AS percentile
FROM #PercentileVax 
GROUP BY location,
		avg_vax
ORDER BY location

--**** CHECK THIS QUERY, COULD QUERY THE PARTITION BY OF PERCENTILE BY THE ROLLING COUNT OF VACCINATIONS PER LOCATION?

---------------------------------------------------------------------------------------------------

--STANDBY - 6.What is the max & min number of vaccinations per day per country
--Might be useful to utilize the rank operator? besides form max and min?? Research RANK and DENSE RANK

---------------------------------------------------------------------------------------------------

--ANSWERED - 7.How does the ratio of deaths to vaccinations change over time for a given location. 

---------------------------------------------------------------------------------------------------

--STANDBY - 8.Are there any outliers in deaths? If so, why?

---------------------------------------------------------------------------------------------------

--STANDBY - 9.Which country has the highest deaths per capita? Is this unique to a location or continent?

---------------------------------------------------------------------------------------------------

/*
-- INDEXES
10. For column 'continent' compare query execution time between the following cases:
	(For this you'll need to research how to measure query execution time. There is a command you need to run before each query.)

	- WHERE continent = 'Europe'
	- WHERE continent LIKE '%Europe'
	- WHERE continent LIKE '%Europe%'
		- What do you notice? Why are some faster than others?

	- Now add an index to column continent
	- Redo all the queries from above and compare. What do you notice now?
	- Check the execution plan for some of the queries above.

11. Learn window functions
	- What is the difference between ROW_NUMBER, RANK, DENSE_RANK? Give examples of each
	- Learn how to use LAG

12. What is the difference between WHERE and HAVING?

FOCUS ON SYNTAX STRUCTURE, WHERE >> GROUP BY >> HAVING

SELECT  city, 
		state, 
		SUM(population)
FROM table
WHERE continent='Europe'
GROUP BY city, state
HAVING SUM(population) > 10


*/









 



