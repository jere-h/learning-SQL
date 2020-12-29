/* Count no. of tests completed on each day of the week
   Accounting for approx time zones, in each calendar year 
   Excludes dog_guids and user_guids with exclude=1
   Sorted by year (ASC) and by day of week (custom) */

SELECT YEAR(c.created), CASE DAYOFWEEK(c.created) WHEN 1 THEN 'Sun'
        WHEN 2 THEN 'Mon'
        WHEN 3 THEN 'Tue'
        WHEN 4 THEN 'Wed'
        WHEN 5 THEN 'Thu'
        WHEN 6 THEN 'Fri'
        WHEN 7 THEN 'Sat'
        END AS day_name, COUNT(c.created)
FROM (
    SELECT dog_guid, DATE_SUB(created_at, INTERVAL 6 HOUR) AS created
      FROM complete_tests
) AS c 
JOIN (
    SELECT DISTINCT dg.dog_guid AS dog_guid
    FROM dogs dg JOIN users u ON dg.user_guid = u.user_guid
    WHERE (dg.exclude = 0 OR dg.exclude IS NULL) 
    AND (u.exclude = 0 OR u.exclude IS NULL)
    AND (u.country = 'US') AND (u.state NOT IN ('HI', 'AK'))
) AS d ON c.dog_guid = d.dog_guid  
GROUP BY 1, 2
ORDER BY 1 ASC, FIELD(day_name, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');



/* Top 10 countries with most customers, 
   Removing dog_guids and user_guids with exclude = 1 */

SELECT d.country, COUNT(DISTINCT d.user_guid)
FROM (
    SELECT DISTINCT dg.dog_guid AS dog_guid, u.user_guid, u.state AS state
    FROM dogs dg JOIN users u ON dg.user_guid = u.user_guid
    WHERE (dg.exclude = 0 OR dg.exclude IS NULL) 
    AND (u.exclude = 0 OR u.exclude IS NULL) 
    ) AS d JOIN complete_tests c ON d.dog_guid = c.dog_guid
GROUP BY 1
ORDER BY 2 DESC 
LIMIT 10;