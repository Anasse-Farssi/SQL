--Creating tables

CREATE TABLE olympics_data
(
--some values come with Na and will cause error if in a numirical category such as Age..
	ID		int,
	Name	VARCHAR(120),
	Sex		VARCHAR(10),
	Age		VARCHAR(40),
	Height	VARCHAR(40),
	Weight	VARCHAR(40),
	Team	VARCHAR(50),
	NOC		VARCHAR(30),
	Games	VARCHAR(60),
	Year	INT,
	Season	VARCHAR(10),
	City	VARCHAR(40),
	Sport	VARCHAR(60),
	Event	VARCHAR(90),
	Medal	VARCHAR(20)
);

	
CREATE TABLE Noc_regions
(
NOC		VARCHAR(20),
Regions	VARCHAR(50),
Notes	VARCHAR(50)
);

--making sure every column is correct:

SELECT * FROM Noc_regions;
SELECT * FROM olympics_data;

--importing data from the csv file into tables:

COPY Noc_regions
 FROM 'C:\Users\Admin\Downloads\archive (2)\noc_regions.csv' HEADER CSV DELIMITER ',';

--original data has douplicates 'i cleaned my copy using excel'
COPY olympics_data
 FROM 'C:\Users\Admin\Downloads\archive (2)\athlete_events.csv' HEADER CSV DELIMITER ',';

 
SELECT * FROM Noc_regions limit(10); --everything looks good.
SELECT * FROM olympics_data limit(10);--everything looks good.
SELECT count(id) FROM olympics_data; -- using id to compare the data to our csv file and everything is good
SELECT count(noc) FROM Noc_regions; -- same thing everything looks good
--let's get started:
--1. How many olympics games have been held?
SELECT
	COUNT(DISTINCT games) AS olympics_games_Nr FROM olympics_data;
-- Answer is 51.

--2. List all Olympics games held so far:
SELECT 
	games,season,city FROM olympics_data 
	Group by  year,games,season,city Order By games;
--we have 52 result because "1956 summer" was held in Melbourne with the exception of the equestrian events,
--which were held in Stockholm, Sweden..

--3. Mention the total number of nations who participated in each olympics game?

--ANSWER 1 TOTAL FOR EACH NATION
SELECT 
	NOC,COUNT(noc) AS NUMBER from olympics_data
	GROUP BY NOC ORDER BY 1 ;

--ANSWER 2  EACH NATION for every game:
SELECT
	games,NOC,COUNT(noc) AS NUMBER from olympics_data
	GROUP BY  games , NOC ORDER BY games ;

--ANSWER 3 FOR TOTAL NUMBER OF NATIONS:
SELECT
	COUNT(DISTINCT noc) AS TOTAL_NUMBER from olympics_data;

--4. Which year saw the highest and lowest no of countries participating in olympics
-- there are a number of ways to get to the same results like using a subquery,CTE, or temp table 
-- I will use the first two and let the temp table to another chance..
--subquery:
SELECT country1.games, country1.lowest, 
	   country2.games, country2.lowest as highest
FROM
	(SELECT games, COUNT(DISTINCT noc) AS lowest FROM olympics_data 
 	GROUP BY games ORDER BY lowest LIMIT 1) AS country1,
	(SELECT games, COUNT(DISTINCT noc) AS lowest FROM olympics_data 
 	GROUP BY games ORDER BY lowest DESC LIMIT 1) AS country2;

--CTE + subquery :
WITH miv_vs_max AS (
	SELECT 
	games, COUNT(DISTINCT noc) AS number_of_countries
 	FROM olympics_data 
 	GROUP BY games)
	SELECT 
	games,number_of_countries as min_and_max
	FROM miv_vs_max WHERE number_of_countries = (SELECT MIN(number_of_countries)from miv_vs_max) 
	OR number_of_countries =( select Max(number_of_countries) from miv_vs_max );

--5. Which nation has participated in all of the olympic games:
--TOTAL NUMBER OF GAMES IS 51 AS SHOWN IN QUESTION 1, SO WE NEED TO LOCATE COUNTRIES THAT PLAYED 51 OLYMPIC GAME:
WITH games_p AS (
	SELECT 
	regions,games,COUNT(regions)OVER(PARTITION BY regions) AS count 
	FROM olympics_data AS od 
	JOIN noc_regions AS nr ON od.noc = nr.noc
	GROUP BY regions,games ORDER BY COUNT DESC)
	SELECT regions,ROUND(AVG(count),0) AS games_played FROM games_p
	GROUP BY regions ORDER BY games_played DESC,regions LIMIT(4);

--6. Identify the sport which was played in all summer olympics.
--SIMILLAR TO THE PREVIOUS ONE
WITH sport_p AS (
	SELECT 
	games, sport,COUNT(games)OVER(PARTITION BY sport) AS count 
	FROM olympics_data GROUP BY sport,games order by count desc,sport )
	SELECT sport,ROUND(AVG(count),0) nr_sport_played from sport_p 
	GROUP BY sport ORDER BY nr_sport_played DESC ,sport LIMIT(5);

--7. Which Sports were just played only once in the olympics.
WITH sport_p AS (
	SELECT
	games, sport,COUNT(games)OVER(PARTITION BY sport) AS count 
	FROM olympics_data GROUP BY sport,games order by count desc,sport )
	SELECT sport,ROUND(AVG(count),0) AS nr_sport_played,games from sport_p 
	WHERE count = 1
	GROUP BY games,sport ORDER BY sport ;
	
--8. Fetch the total number of sports played in each olympic games.
	
	SELECT games,COUNT(distinct sport ) nr_sports FROM olympics_data
	GROUP BY games ORDER BY 2 DESC;
	
--9. Fetch oldest athletes to win a gold medal
SELECT
	medal FROM olympics_data GROUP BY medal;

SELECT
	name,age,medal,sex,noc,games,sport
	FROM olympics_data 
	WHERE medal like '%Gold%'
	AND age != 'NA'
	ORDER BY age DESC LIMIT(5);
	
--10. Find the Ratio of male and female athletes participated in all olympic games.
--RATIO 	    
		SELECT
		'For every 1 female there are '|| ROUND((male.GENDER/female.GENDER ),2) ||' male' AS ratio_m_f ,
		CONCAT('1 : ',ROUND((male.GENDER/female.GENDER ),2) ) AS ratio_number FROM
		(SELECT SEX ,CAST(COUNT(SEX) AS DECIMAL) AS GENDER 
		 FROM olympics_data WHERE SEX LIKE '%M%' GROUP BY SEX) AS male,
		(SELECT SEX ,CAST(COUNT(SEX) AS DECIMAL) AS GENDER 
		 FROM olympics_data WHERE SEX LIKE '%F%' GROUP BY SEX) as female;
--PERCENTAGE		 
		 SELECT
		 ROUND(100 * COUNT(CASE WHEN SEX LIKE '%M%' THEN 1 END) 
			   / COUNT(1), 2) AS male_percentage,
		 ROUND(100 * COUNT(CASE WHEN SEX LIKE '%F%' THEN 1 END) 
			   / COUNT(1), 2) AS female_percentage
		 FROM olympics_data;

--11. Fetch the top 5 athletes who have won the most gold medals.
	
	SELECT NAME, MEDAL , COUNT(MEDAL) AS NR_OF_MEDALS 
	FROM  olympics_data WHERE MEDAL !='NA'  
	GROUP BY NAME, MEDAL ORDER BY 3 DESC LIMIT(5);
	
--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT
	name,regions,COUNT(medal) FROM olympics_data  as od 
	JOIN  noc_regions AS nr ON nr.noc = od.noc
	WHERE medal !='NA'GROUP BY name,regions
	ORDER BY 3 DESC LIMIT(7);

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
--14. List down total gold, silver and bronze medals won by each country.
-- THE ANSWER FOR 13+14 + POINTS COLUMN
SELECT  
	RANK() OVER(ORDER BY points DESC) AS RANK,
	Nations,Gold_medals,Silver_medals,Bronze_medals,
	Total_medals,points FROM (
	SELECT 
	regions AS Nations ,
	SUM(CASE WHEN om.MEDAL = 'Gold'   THEN 1 ELSE 0 END) AS Gold_medals,
	SUM(CASE WHEN om.MEDAL = 'Silver' THEN 1 ELSE 0 END) AS Silver_medals,
	SUM(CASE WHEN om.MEDAL = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_medals,
	COUNT(medal) AS Total_medals,
	SUM( CASE
        WHEN om.MEDAL = 'Gold' THEN 3
      	WHEN om.MEDAL = 'Silver' THEN 2
	  	WHEN om.MEDAL = 'Bronze' THEN 2
        ELSE 0
   		 END ) as points
	FROM olympics_data AS om
	JOIN noc_regions AS ng
	ON om.noc = ng.noc
	WHERE MEDAL !='NA' AND MEDAL IS NOT NULL 
	GROUP BY regions  ORDER BY 6 DESC) AS SUB 
LIMIT (10);

-- question nr 13 Alone:

	SELECT NOC , MEDAL ,COUNT(MEDAL) 
	FROM olympics_data WHERE MEDAL !='NA' AND MEDAL IS NOT NULL 
	GROUP BY NOC , MEDAL ORDER BY 3 DESC;
	
	
	
--15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT DISTINCT
	regions AS Nations , games,
	SUM(CASE WHEN om.MEDAL = 'Gold'   THEN 1 ELSE 0 END) AS Gold_medals,
	SUM(CASE WHEN om.MEDAL = 'Silver' THEN 1 ELSE 0 END) AS Silver_medals,
	SUM(CASE WHEN om.MEDAL = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_medals,
	COUNT(medal) AS Total_medals,
	SUM( CASE
        WHEN om.MEDAL = 'Gold' THEN 3
      	WHEN om.MEDAL = 'Silver' THEN 2
	  	WHEN om.MEDAL = 'Bronze' THEN 2
        ELSE 0
   		 END ) as points
	FROM olympics_data AS om
	JOIN noc_regions AS ng
	ON om.noc = ng.noc
	WHERE MEDAL !='NA' AND MEDAL IS NOT NULL 
	GROUP BY games, regions  ORDER BY 7 DESC 
LIMIT(10) ;
	
	
--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
-- I WILL USE TEMP TABLE SINCE I PROMISED TO DO SO ;
DROP TABLE IF EXISTS MEDALS;
CREATE TEMPORARY TABLE MEDALS (
	Nations VARCHAR(30),
	GAMES VARCHAR(30),
	Gold_medals INT ,
	Silver_medals INT ,
	Bronze_medals INT,
	Total_medals INT
) 
INSERT INTO MEDALS 
SELECT DISTINCT
	regions AS Nations , games,
	SUM(CASE WHEN om.MEDAL = 'Gold'   THEN 1 ELSE 0 END) AS Gold_medals,
	SUM(CASE WHEN om.MEDAL = 'Silver' THEN 1 ELSE 0 END) AS Silver_medals,
	SUM(CASE WHEN om.MEDAL = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_medals,
	COUNT(medal) AS Total_medals
	FROM olympics_data AS om
	JOIN noc_regions AS ng
	ON om.noc = ng.noc
	WHERE MEDAL !='NA' AND MEDAL IS NOT NULL 
	GROUP BY games, regions;

SELECT DISTINCT games , 
CONCAT(FIRST_VALUE (Gold_medals) OVER (PARTITION BY games ORDER BY Gold_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Gold_medals DESC)) AS GOLD, 
CONCAT(FIRST_VALUE (Silver_medals) OVER (PARTITION BY games ORDER BY Silver_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Silver_medals DESC)) AS SILVER, 
CONCAT(FIRST_VALUE (Bronze_medals) OVER (PARTITION BY games ORDER BY Bronze_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Bronze_medals DESC)) AS BRONZE
FROM MEDALS
GROUP BY games ,NATIONS, Gold_medals,Silver_medals,Bronze_medals 
ORDER BY 1;


--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
	-- with the use of the temp table created earlier
	
	SELECT DISTINCT games , 
CONCAT(FIRST_VALUE (Gold_medals) OVER (PARTITION BY games ORDER BY Gold_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Gold_medals DESC)) AS GOLD, 
CONCAT(FIRST_VALUE (Silver_medals) OVER (PARTITION BY games ORDER BY Silver_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Silver_medals DESC)) AS SILVER, 
CONCAT(FIRST_VALUE (Bronze_medals) OVER (PARTITION BY games ORDER BY Bronze_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Bronze_medals DESC)) AS BRONZE,
 CONCAT(FIRST_VALUE (Total_medals) OVER (PARTITION BY games ORDER BY Total_medals DESC),
   ' ',FIRST_VALUE (Nations) OVER (PARTITION BY games ORDER BY Total_medals DESC)) AS max_total_Medals
FROM MEDALS
GROUP BY games ,NATIONS, Gold_medals,Silver_medals,Bronze_medals,Total_medals
ORDER BY 1;


--18.Which countries have never won gold medal but have won silver/bronze medals?

SELECT Nations,Gold_medals,Silver_medals,Bronze_medals 
FROM MEDALS WHERE Gold_medals <= 0 ORDER BY 2 DESC , 3 DESC;

--19. In which Sport/event, Morocco has won highest medals.

SELECT
	regions ,COUNT(medal) total_medals , sport 
	FROM olympics_data AS od
 	JOIN noc_regions AS nr on od.noc = nr.noc
 	WHERE regions LIKE '%Morocco%' AND medal IS NOT NULL AND medal != 'NA'
 	GROUP BY regions , sport
	ORDER BY  2 DESC LIMIT(1)
 
 
--20. Break down all olympic games where Morocco won medal for "Athletics" and how many medals in each olympic games
 
 SELECT
	regions ,COUNT(medal) total_medals , sport ,GAMES
	FROM olympics_data AS od
 	JOIN noc_regions AS nr on od.noc = nr.noc
 	WHERE regions LIKE '%Morocco%' AND medal IS NOT NULL 
	AND medal != 'NA' AND SPORT = 'Athletics'
 	GROUP BY regions , sport,GAMES
	ORDER BY  2 DESC
 
	
	
	--why some results are not correct?
	--answer:
--It seems that there are some inaccuracies in the data related to the representation of certain teams 
--in the Olympic Games under the flag of the United States	
--for example:"Union des Socits Franais de Sports Athletiques" 'FRENCH',"BLO Polo Club Rugby" United kingdem ,"Formosa" Taiwan
--These discrepancies are present in multiple countries and correcting them would require a significant amount of time and resources.
--It's important to acknowledge that historical data can be complex and challenging to 
--obtain accurately, and there may be inconsistencies and inaccuracies in some sources. 
--Nevertheless, it's crucial to strive for accuracy and clarity when discussing important 
--events like the Olympic Games.
--please use the query bellow and compare teams with noc which refers to :
	select  team,noc,games,medal , count(medal) from olympics_data  where games = '1900 Summer' and noc = 'USA' and medal !='NA'
	group by games ,team, medal,noc
	
