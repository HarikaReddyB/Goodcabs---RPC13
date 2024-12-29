-- Request1: City level fare and trip summary report
-- Generate a report that displays the total trips, average fare per km, avearage fare per trip, and the percentage contribution 
-- of each city's trips to the overall trips. This report will help in assessing trip volume, pricing efficiency, and each city's 
-- contribution to the overall trip count. Fields: city_name, total_trips, avg_fare_per_km,avg_fare_per_trip, %_contribution_to_total_trips.
#Query:
SELECT c.city_name,
		COUNT(t.trip_id) AS total_trips,
        ROUND(SUM(t.fare_amount)/SUM(distance_travelled_km),2) AS avg_fare_per_km,
        ROUND(AVG(t.fare_amount),2) AS avg_fare_per_trip,
        CONCAT(ROUND(COUNT(t.trip_id)/(SELECT COUNT(*) FROM fact_trips)*100,2),"%") AS pct_contribution_to_total_trips
FROM dim_city c
JOIN fact_trips t 
ON c.city_id = t.city_id 
GROUP BY c.city_name
ORDER BY total_trips DESC

-- Request2: Monthly city-level trips target performance report.
--  Generate a report that evaluates the target performance for trips at the monthly and city level. For each city and month, compare the 
-- actual total trips with the target trips and categorise the performance as follows:
	-- if actual trips are greater than targets trips, mark it as "Above target".
    -- if actual trips are less than or equal to target trips, mark it as "Below target".
-- additionally, calculate the % difference b/w actual & target trips to quantify the performance gap.
-- Fields: city_name, month_name, actual_trips, target_trips, performance_status, %_difference.
 #Query:
SELECT c.city_name,
		d.month_name,
        COUNT(t.trip_id) AS actual_trips,
        mt.total_target_trips,
        CASE
			WHEN COUNT(t.trip_id) > mt.total_target_trips THEN "Above Target"
            ELSE "Below Target"
		END AS performance_status,
		CONCAT(ROUND(((COUNT(t.trip_id) - mt.total_target_trips) / NULLIF (mt.total_target_trips,0)) *100,2),"%") AS pct_difference
FROM dim_city c
JOIN fact_trips t
ON c.city_id = t.city_id
JOIN dim_date d
ON t.date = d.date
JOIN targets_db.monthly_target_trips mt
ON c.city_id = mt.city_id AND
DATE_FORMAT(mt.month, "%M") = d.month_name
GROUP BY c.city_name, d.month_name,mt.total_target_trips
ORDER BY c.city_name, d.month_name


 -- Request3: City level repeat passenger trip frequency report. 
 -- Generate a report that shows the percentage distribution of repeat passengers by the no.of trips they have taken in each city. 
 -- calcualte the percentage of repeat passengers who took 2trips, 3 trips, and so on, up to 10 trips. Each column should represent a trip 
 -- count category, displaying the percentage of repeat passengers who fall into that category out of the total repeat passengers for that 
 -- city. This report will help identify cities with high repeat trip frequency, which can indicate strong customer loyalty or frequent 
 -- usage patterns. Fields: city_name, 2-trips, 3-trips, 4-trips, 5-trips, 6-trips, 7-trips, 8-trips, 9-trips,10-trips. 
 #Query:
SELECT c.city_name,
	CONCAT(ROUND(SUM(CASE WHEN d.trip_count=2 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF (SUM(d.repeat_passenger_count),0)*100,2),"%") AS 2_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=3 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 3_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=4 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 4_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=5 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 5_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=6 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 6_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=7 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 7_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=8 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 8_trips,
    CONCAT(ROUND(SUM(CASE WHEN d.trip_count=9 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 9_trips,
	CONCAT(ROUND(SUM(CASE WHEN d.trip_count=10 THEN d.repeat_passenger_count ELSE 0 END) / NULLIF(SUM(d.repeat_passenger_count),0)*100,2),"%") AS 10_trips
FROM dim_city c
JOIN dim_repeat_trip_distribution d
ON c.city_id = d.city_id
GROUP BY c.city_name
ORDER BY c.city_name
 
 -- Request4: Identify cities with highest and lowest total new passengers
 -- Generate a report that calculates the total new passengers for each city and ranks them based on this value. identify the top 3 cities 
 -- with the highest no.of new passengers as well as the bottom 3 cities with the lowest no.of new passengers as categorising them as 
 -- "Top 3" or "Bottom 3" accordingly. Fields: city_name, total_new_passengers, city_category("Top 3" or "Bottom 3")
#Query:
WITH ranked_cities AS
(
    SELECT c.city_name,
			SUM(p.new_passengers) AS total_new_passengers,
            RANK() OVER(ORDER BY SUM(p.new_passengers) DESC) AS highest_rank,
            RANK() OVER(ORDER BY SUM(p.new_passengers) ASC) AS lowest_rank
	FROM dim_city c
	JOIN fact_passenger_summary p
	ON c.city_id = p.city_id
	GROUP BY c.city_name
),
categorized_city AS 
(
	SELECT city_name,
			total_new_passengers,
            CASE
				WHEN highest_rank <= 3 THEN "Top 3"
                WHEN lowest_rank <=3 THEN "Bottom 3"
			END AS city_category
    FROM ranked_cities
)
SELECT city_name,
		total_new_passengers,
        city_category
FROM categorized_city
WHERE city_category IS NOT NULL
ORDER BY city_category, total_new_passengers

 -- Request5: Identify month with highest revenue for each city. 
 -- Generate a report that identifies the month with the highest revenue for each city. For each city, display the month_name, the
 -- revenue amount for that month, and the percentage contribution of that month's revenue to the city's total revenue. 
 -- Fields: city_name, highest_revenue_month, revenue, percentage_contribution(%). 
 #Query:
WITH monthly_revenue AS
(
	SELECT c.city_name,
			d.month_name,
			SUM(t.fare_amount) AS revenue,
			SUM(SUM(t.fare_amount)) OVER(PARTITION BY c.city_name ) AS total_city_revenue,
			MAX(SUM(t.fare_amount)) OVER(PARTITION BY c.city_name ) AS highest_monthly_revenue
	FROM dim_city c
	JOIN fact_trips t
	ON c.city_id = t.city_id
	JOIN dim_date d
	ON t.date = d.date
	GROUP BY c.city_name, d.month_name
),
highest_revenue AS
(
	SELECT city_name,
			month_name,
            revenue,
            highest_monthly_revenue,
            ROUND((revenue/ NULLIF(total_city_revenue,0))*100,2) AS pct_contribution
	FROM monthly_revenue
    WHERE revenue = highest_monthly_revenue
)
SELECT city_name,
		month_name AS highest_revenue_month,
		revenue,
		CONCAT(pct_contribution,"%") AS pct_contribution
FROM highest_revenue
ORDER BY city_name
 
 -- Request6: Repeat passenger rate analysis
 -- Generate a report that calculates two metrics:
	-- 1. Monthly Repeat passenger rate: Calculate the repeat passenger rate for each city and month by comparing the no.of repeat 
		-- passenger to the total passengers. 
    -- 2. City-wide Repeat passenger rate: Calculate the overall repeat passenger rate for each city, considering all passengers 
    -- across months. 
    
    -- These metrics will provide insights into monthly repeat trends as well as the overall repeat behaviour for each city. 
   -- Fields: city_name, month, total_passengers, repeat_passengers, monthly_repeat_passenger_rate(%) :
   -- Repeat passenger rate at the city & month level.
   -- city_repeat_passenger_rate (%): overall repeat passenger rate for each city, aggregated across months.    
#Query:
WITH monthswise_passenger AS
(
	SELECT c.city_name,
			d.month_name,
			SUM(ps.total_passengers) AS total_passengers,
			SUM(ps.repeat_passengers) AS repeat_passengers
	FROM dim_city c
	JOIN fact_passenger_summary ps
	ON c.city_id = ps.city_id
	JOIN dim_date d
	ON ps.month = d.start_of_month
    GROUP BY c.city_name, d.month_name
),
citywise_passenger AS 
(
	SELECT c.city_name,
			SUM(ps.total_passengers) AS total_passengers_city,
			SUM(ps.repeat_passengers) AS repeat_passengers_city
	FROM dim_city c
	JOIN fact_passenger_summary ps
	ON c.city_id = ps.city_id
    GROUP BY c.city_name
)
SELECT mp.city_name,
		mp.month_name,
		mp.total_passengers,
		mp.repeat_passengers,
        CONCAT(ROUND((mp.repeat_passengers/NULLIF (mp.total_passengers,0))*100,2),"%") AS pct_monthly_repeat_passenger_rate,
        CONCAT(ROUND((cp.repeat_passengers_city/NULLIF (cp.total_passengers_city,0))*100,2),"%") AS pct_city_repeat_passenger_rate
FROM monthswise_passenger mp
JOIN citywise_passenger cp
ON mp.city_name = cp.city_name
GROUP BY cp.city_name, mp.month_name
	
    
    
    