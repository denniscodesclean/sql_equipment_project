-- Convert 4 colums type to DATE
ALTER TABLE comeq_data
MODIFY COLUMN scheduled_start_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN actual_start_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN scheduled_return_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN actual_return_date DATE;

-- Users who have overdue history in 2022.
SELECT user_id, COUNT(DISTINCT res_id) as overdue_times
FROM comeq_data
WHERE overdue = 'TRUE' AND EXTRACT(YEAR FROM actual_start_date) = 2022
GROUP BY user_id
ORDER BY overdue_times DESC;

-- Users who have high (>=5) overdue history.
SELECT user_id, COUNT(DISTINCT res_id) as overdue_times
FROM comeq_data
WHERE overdue = 'TRUE'
GROUP BY user_id
HAVING overdue_times >= 5 
ORDER BY overdue_times DESC;

-- Users' avg missing due days (目前这code有问题）
WITH table1 AS(
SELECT user_id, res_id, avg(overdue_by) as overdue_day
FROM comeq_data
WHERE overdue = 'TRUE'
GROUP BY user_id, res_id)
SELECT CONCAT(user_id, ' ', res_id) as user_res_id, avg(overdue_day) as avg_overdue_day
FROM table1
GROUP BY 1
ORDER BY 2 DESC;

-- The most and least popualr item.
SELECT Kit_name, COUNT(*) as number_of_res
FROM comeq_data
GROUP BY 1
ORDER BY 2 DESC;
		#Problem: cannot recognize cannon #1 and #2 as same item.

SELECT SUBSTRING(Kit_name,1,(POSITION('#' IN Kit_Name)-1)) as Kit, COUNT(*) as number_of_res #get rid of "#" after kit name
FROM comeq_data
GROUP BY 1
ORDER BY 2 DESC;
		#Problem: if kitname does not contain #, will return null. all nulls are taken as a same item in this case.
        
#Solution:
WITH cte AS(
	(SELECT Kit_name as Kit, COUNT(*) as number_of_res 
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) = 0 #gives all items without # in the name.
	GROUP BY 1)
	UNION
	(SELECT SUBSTRING(Kit_name,1,(POSITION('#' IN Kit_Name)-1)) as Kit, COUNT(*) as number_of_res 
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) != 0
	GROUP BY 1))
	
Select Kit, number_of_res
FROM cte
ORDER BY 2 DESC;

-- Items with their last rented date.
WITH cte1 AS(
	(SELECT Kit_name as Kit, COUNT(*) as number_of_res, MAX(actual_start_date) as most_recent_res
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) = 0 #gives all items without # in the name.
	GROUP BY 1)
	UNION
	(SELECT SUBSTRING(Kit_name,1,(POSITION('#' IN Kit_Name)-1)) as Kit, COUNT(*) as number_of_res, MAX(actual_start_date) as most_recent_res
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) != 0
	GROUP BY 1))
SELECT Kit, number_of_res, most_recent_res
FROM cte1
ORDER BY 3 ASC;









