DROP VIEW IF EXISTS forestation;

CREATE VIEW forestation
AS
(SELECT f.country_code,
        f.country_name,
        f.year,
        f.forest_area_sqkm,
        l.total_area_sq_mi * 2.59 AS l_total_sqkm,
        r.region,
        r.income_group,
        f.forest_area_sqkm/(l.total_area_sq_mi * 2.59) * 100 AS percent_land
 FROM forest_area f
 JOIN land_area AS l
 ON f.country_code = l.country_code
 AND f.year = l.year
 JOIN regions AS r
 ON l.country_code = r.country_code);



 SELECT forest_area_sqkm
FROM   forestation
WHERE  region = 'World'
       AND year = 1990 ;

SELECT forest_area_sqkm
FROM   forestation
WHERE  region = 'World'
       AND year = 2016 ;

SELECT DISTINCT country_name, l_total_sqkm
FROM forestation
WHERE l_total_sqkm BETWEEN 1270000 AND 1350000;


WITH f_1990
     AS (SELECT forest_area_sqkm,
                country_name
         FROM   forestation
         WHERE  region = 'World'
                AND year = 1990),
     f_2016
     AS (SELECT forest_area_sqkm,
                country_name
         FROM   forestation
         WHERE  region = 'World'
                AND year = 2016),
     f_9016
     AS (SELECT f_1990.forest_area_sqkm AS frst_1990,
                f_2016.forest_area_sqkm AS frst_2016,
                f_1990.country_name,f_1990.forest_area_sqkm - f_2016.forest_area_sqkm AS change,
                ( f_2016.forest_area_sqkm - f_1990.forest_area_sqkm ) * 100 /
                f_1990.forest_area_sqkm AS percent_change
         FROM   f_1990
                join f_2016
                  ON f_1990.country_name = f_2016.country_name)
SELECT frst_1990,
       frst_2016,
       country_name,
       change,
       Round(percent_change :: NUMERIC, 2) AS percent_change
FROM   f_9016;


SELECT region, sum(forest_area_sqkm)/sum(l_total_sqkm) *100 AS percent_forest_area
FROM forestation
GROUP BY 1;

SELECT region, sum(forest_area_sqkm)/sum(l_total_sqkm) *100 AS percent_forest_area
FROM forestation
WHERE country_name = 'World' AND year = 2016
GROUP BY 1;


SELECT region, ROUND(cast(sum(forest_area_sqkm)/sum(l_total_sqkm) *100 AS numeric),2) AS percent_forest_area
FROM forestation
WHERE year = '2016'
GROUP BY 1
ORDER BY 2 DESC;

SELECT region, sum(forest_area_sqkm)/sum(l_total_sqkm) *100 AS percent_forest_area
FROM forestation
WHERE country_name = 'World' AND year = 1990
GROUP BY 1;

SELECT region, ROUND(cast(sum(forest_area_sqkm)/sum(l_total_sqkm) *100 AS numeric),2)AS percent_forest_area
FROM forestation
WHERE year = '1990'
GROUP BY 1
ORDER BY 2 DESC;



SELECT f_90.region,
       f_90.forest_area_decrease_9016
       AS forest_perc_1990,
       f_16.forest_area_decrease_9016
       AS forest_perc_2016,
       f_16.forest_area_decrease_9016 -
       f_90.forest_area_decrease_9016 AS
       forest_perc_decrease
FROM   (SELECT region,
               Round(Cast(Sum(forest_area_sqkm) / Sum(l_total_sqkm) * 100 AS
                          NUMERIC
                     ), 2)
                                     forest_area_decrease_9016
        FROM   forestation
        WHERE  year = 1990
        GROUP  BY 1
        ORDER  BY 2 DESC) f_90
       JOIN (SELECT region,
                    Round(Cast(Sum(forest_area_sqkm) / Sum(l_total_sqkm) *
                               100 AS
                               NUMERIC
                          ), 2)
                                          forest_area_decrease_9016
             FROM   forestation
             WHERE  year = 2016
             GROUP  BY 1
             ORDER  BY 2 DESC) f_16
         ON f_90.region = f_16.region
ORDER  BY 2 desc;

WITH largest_amount_decr_9016
          AS(SELECT f_90.country_name,
                    f_90.region,
                    f_90.forest_area_sqkm AS f_90_forest_area,
                    f_16.forest_area_sqkm AS f_16_forest_area,
                    f_90.forest_area_sqkm - f_16.forest_area_sqkm AS forest_area_change
             FROM(SELECT country_name,region,
                  forest_area_sqkm
                  FROM forestation
                  WHERE year = 1990)  f_90
             JOIN( select country_name,region,
                          forest_area_sqkm
                  FROM forestation
                  WHERE year = 2016) f_16
             ON f_90.country_name = f_16.country_name
             AND f_90.region = f_16.region
             GROUP BY 1,2,3,4
             ORDER BY 5 DESC
             LIMIT 20)
      SELECT country_name,region,round(forest_area_change :: numeric,2)
      FROM largest_amount_decr_9016
      WHERE forest_area_change IS NOT NULL;


WITH largest_perc_change_9016
          AS(SELECT f_90.country_name,
                    f_90.region,
                    (f_90.forest_area_sqkm - f_16.forest_area_sqkm) / f_90.forest_area_sqkm *100 AS forest_percent
             FROM(SELECT country_name,region,
                  forest_area_sqkm
                  FROM forestation
                  WHERE year = 1990)  f_90
             JOIN( select country_name,region,
                          forest_area_sqkm
                  FROM forestation
                  WHERE year = 2016) f_16
             ON f_90.country_name = f_16.country_name
             AND f_90.region = f_16.region
             GROUP BY 1,2,3
             ORDER BY 3 DESC
             LIMIT 20)
      SELECT *,round(forest_percent::numeric,2)
      FROM largest_perc_change_9016
      WHERE forest_percent IS NOT NULL;



WITH T1 AS
(
SELECT f.country_name, f.percent_land,CASE
WHEN f.percent_land <= 0.25 THEN '1'
WHEN f.percent_land <= 0.50 THEN '2'
WHEN f.percent_land <= 0.75 THEN '3'
ELSE  '4'
END AS percent_forest_quartiles
FROM forestation f
WHERE f.percent_land IS NOT NULL
AND f.country_name != 'World'
AND f.year = 2016
)
SELECT DISTINCT(T1.percent_forest_quartiles),
COUNT(country_name) OVER(PARTITION BY T1.percent_forest_quartiles)
AS no_of_countries
FROM T1
ORDER BY 1;


WITH high_quartiles_2016
AS (SELECT country_name,
          region,
          percent_land,
          CASE
            WHEN percent_land > 0.75 THEN 4
            WHEN percent_land <= 0.75
                 AND percent_land > 0.5 THEN 3
            WHEN percent_land <= 0.5
                 AND percent_land > 0.25 THEN 2
            WHEN percent_land <= 0.25 THEN 1
          END AS level
   FROM   forestation
   WHERE  year = 2016)
SELECT country_name,
 region,
 percent_land
FROM   high_quartiles_2016
WHERE  level = 4;
