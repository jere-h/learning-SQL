/* Average daily revenue for each store/month/year combination
   Expect to see later years and december being consistently higher */

SELECT t.store, EXTRACT(MONTH from t.saledate) AS mth, EXTRACT(YEAR from t.saledate) AS yr,
              SUM(t.amt)/COUNT(DISTINCT t.saledate) AS avg_daily_rev
FROM trnsact t
WHERE t.stype='P' 
AND t.store||EXTRACT(YEAR from t.saledate)||EXTRACT(MONTH from t.saledate) IN (
    SELECT store||EXTRACT(YEAR from saledate)||EXTRACT(MONTH from saledate) 
    FROM trnsact 
    GROUP BY store, EXTRACT(YEAR from saledate), EXTRACT(MONTH from saledate) 
    HAVING COUNT(DISTINCT saledate)>= 20) 
GROUP BY 1, 2, 3



/* City and state of the stores with top 10 greatest 
   increase in average daily revenue from Nov to Dec */

SELECT TOP 10 T.store, city, state,
       SUM(CASE WHEN dm = 12 THEN avg_daily_rev END) - SUM(CASE WHEN dm = 11 THEN avg_daily_rev END) AS change
FROM strinfo JOIN (
     SELECT store, EXTRACT(MONTH from saledate) AS dm, EXTRACT(YEAR from saledate) AS dy,
            dm||dy AS dmy, COUNT(DISTINCT saledate) AS numtrans, SUM(amt) AS rev,
            rev/numtrans AS avg_daily_rev
     FROM trnsact
     WHERE stype = 'p'
     HAVING dmy <> '2005 8' AND numtrans >= 20
     GROUP BY 1, 2, 3
) AS T ON strinfo.store = T.store
GROUP BY 1, 2, 3
ORDER BY 4 DESC;



/* For each month of the year, shows the number of distinct stores 
   that had their HIGHEST avg monthly revenue in that month
   Expectation is for Dec to have the most */

SELECT T.mthdate, COUNT(DISTINCT T.store)

   FROM (
                SELECT store, 
                 EXTRACT(MONTH from saledate) as mthdate, 
                 EXTRACT(YEAR from saledate) as yrdate, 
                 EXTRACT(MONTH from saledate)||EXTRACT(YEAR from saledate) AS mthyear,
                 COUNT(DISTINCT saledate) AS numdays, 
                 SUM(amt) AS rev, 
                 rev/numdays AS avg_rev,
                 ROW_NUMBER() OVER (PARTITION BY store ORDER BY avg_rev DESC) AS rev_rank
       		FROM trnsact
                WHERE stype = 'P'
                HAVING numdays >= 20
                AND mthyear <> '2005 8'
        	GROUP BY 1, 2, 3
) AS T
WHERE rev_rank = 1
GROUP BY 1;



/* Average daily revenue for each month of the year 
   Expecting December to have the highest amt */

SELECT EXTRACT(MONTH from trnsact.saledate)||EXTRACT(YEAR from trnsact.saledate) AS m_y,
       	SUM(trnsact.amt)/COUNT(DISTINCT trnsact.saledate) AS avg_daily_rev 
FROM trnsact
WHERE stype = 'p'
AND m_y IN (SELECT EXTRACT(MONTH from saledate)||EXTRACT(YEAR from saledate) AS mthyear 
        		FROM trnsact
        		HAVING COUNT(DISTINCT saledate) >= 20
        		GROUP BY 1
) AND NOT(EXTRACT(MONTH from saledate)=8 AND EXTRACT(YEAR from saledate)=2005)
GROUP BY 1
ORDER BY 2 DESC;



/* Average daily revenue from stores in areas of high, medium, 
   or low levels of high school education. Testing relationships
   Expecting high education to correspond to lower daily revenues */

SELECT edu_lvl, SUM(salesamt)/SUM(numdays) AS avg_daily_rev
FROM ( SELECT trnsact.store, CASE WHEN msa_high BETWEEN 50 AND 60 THEN 'low'
                  WHEN msa_high BETWEEN 60.01 AND 70 THEN 'med'
                  WHEN msa_high BETWEEN 70 AND 100 THEN 'high' END AS edu_lvl, 
        EXTRACT(MONTH from trnsact.saledate)||EXTRACT(YEAR from trnsact.saledate) AS m_y,
       	SUM(trnsact.amt) AS salesamt, COUNT(DISTINCT trnsact.saledate) AS numdays
FROM trnsact JOIN store_msa ON trnsact.store = store_msa.store
WHERE stype = 'p'
AND store IN (SELECT store||EXTRACT(MONTH from saledate)||EXTRACT(YEAR from saledate) AS mthyear, 
COUNT(DISTINCT saledate) AS snum
        		FROM trnsact
        		HAVING snum >= 20 
        		GROUP BY 1
) AND NOT(EXTRACT(MONTH from saledate)=8 AND EXTRACT(YEAR from saledate)=2005)
GROUP BY 1, 2, 3
) AS subq
GROUP BY 1;
