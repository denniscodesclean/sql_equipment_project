-- Data Preparation: Convert 4 colums type to DATE
ALTER TABLE comeq_data
MODIFY COLUMN scheduled_start_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN actual_start_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN scheduled_return_date DATE;
ALTER TABLE comeq_data
MODIFY COLUMN actual_return_date DATE;

-- 1. Users who have overdue history in 2022.
SELECT user_id, COUNT(DISTINCT res_id) as overdue_times
FROM comeq_data
WHERE overdue = 'TRUE' AND EXTRACT(YEAR FROM actual_start_date) = 2022
GROUP BY user_id
ORDER BY overdue_times DESC;

-- 2. Users who have high (>=5) overdue history.
SELECT user_id, COUNT(DISTINCT res_id) as overdue_times
FROM comeq_data
WHERE overdue = 'TRUE'
GROUP BY user_id
HAVING overdue_times >= 5 
ORDER BY overdue_times DESC;

-- 3. The most and least popualr item.
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

-- 4. Continued, item with their number of reservation, overdue_rate, and last time reserved.
WITH number_of_res_list AS(
	(SELECT Kit_name as Kit, COUNT(*) as number_of_res, MAX(actual_start_date) as most_recent_res
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) = 0 
	GROUP BY 1)
	UNION
	(SELECT SUBSTRING(Kit_name,1,(POSITION('#' IN Kit_Name)-1)) as Kit, COUNT(*) as number_of_res, MAX(actual_start_date) as most_recent_res
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) != 0
	GROUP BY 1)), #cte1(number_of_res_list) return items names and numebr of reservation 
    number_of_overdue AS(
	(SELECT Kit_name as Kit, COUNT(*) as overdue_times
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) = 0 AND overdue = 'TRUE'
	GROUP BY 1)
	UNION
	(SELECT SUBSTRING(Kit_name,1,(POSITION('#' IN Kit_Name)-1)) as Kit, COUNT(*) as overdue_times
	FROM comeq_data
	WHERE POSITION('#' IN Kit_Name) != 0 AND overdue = 'TRUE'
	GROUP BY 1))#cte2(number_of_overdue) return items names and numebr of overdue
    SELECT r.Kit, r.number_of_res, COALESCE(ROUND(o.overdue_times/r.number_of_res ,2),0) AS overdue_rate, r.most_recent_res as last_time_rented #replace null (items with no overdue) with 0
    FROM number_of_res_list AS r
    LEFT JOIN number_of_overdue as o
    USING (Kit)
    ORDER BY 3 DESC, 2 DESC;

-- 5. Reservations with comments during either check in or check out.
SELECT res_id, GROUP_CONCAT(Kit_name, ',') AS kits, MAX(check_in_notes), MAX(check_out_notes), max(actual_start_date)
#put all kit_names in the same reservation to one column and get their comments.
FROM comeq_data
WHERE check_out_notes != ' ' OR check_in_notes != ' '
GROUP BY 1
ORDER BY 5 ASC;

-- 6. Overdue rate trends, equipmeent usage trends, interval: month
WITH res_number AS(
	SELECT DATE_FORMAT(actual_start_date,"%Y-%m") AS MONTH,COUNT(DISTINCT res_id) as reservations, count(res_id) as items
	FROM comeq_data
	GROUP BY 1
	ORDER BY 1 ASC), #usage measured by reservation number, and items number
    overdue_number AS(
    SELECT DATE_FORMAT(actual_start_date,"%Y-%m") AS MONTH, COUNT(distinct res_id) as overdues
	FROM comeq_data
	WHERE overdue = 'TRUE'
	GROUP BY 1
	ORDER BY 1 ASC)
SELECT r.MONTH, ROUND(overdues / reservations,2) as overdue_rate, reservations, items
FROM res_number AS r
INNER JOIN overdue_number as o
USING (MONTH)
ORDER BY r.MONTH ASC;














