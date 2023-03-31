
		WITH Hotel AS (
		SELECT * FROM dbo.['2018']
		UNION
		SELECT * FROM dbo.['2019']
		UNION
		SELECT * FROM dbo.['2020'] )
		SELECT arrival_date_year,
		(stays_in_weekend_nights + stays_in_week_nights) AS Total_week_nights,
		(stays_in_weekend_nights + stays_in_week_nights)*adr AS Revnue  
		FROM hotel ORDER BY 1;

--Standaraizing the days nights into "total_week_nights".
--Creating Revnue column using the number of nights multiplied by adr (Average Daily Rate).
--Revnue that shows 0 while total week nights shows more than 0 means that the reservation is cancelled and there is no deposit.

-- Let's compare the three years -- 
		WITH Hotel AS (
		SELECT * FROM dbo.['2018']
		UNION
		SELECT * FROM dbo.['2019']
		UNION
		SELECT * FROM dbo.['2020'] )
		SELECT arrival_date_year,
		SUM(	stays_in_weekend_nights + stays_in_week_nights) 
		AS Total_week_nights,
		ROUND(	SUM(	(stays_in_weekend_nights + stays_in_week_nights)*adr),2) 
		AS Revnue  FROM hotel
		GROUP BY arrival_date_year ORDER BY 1;

		
-- 313.23%  INCREASE in Revnue FROM 2018 TO 2019 and about 295.926% or 149,197 more nights compared to 2018.
-- 29.24% decrease in Revnue FROM 2019 TO 2020 and about -40.93% or -81,702 nights compared to 2019.(2020 data may not be complete )
-- 192.38% INCREASE in Revnue FROM 2018 TO 2020 and about 133.873%  or 67,495 more nights compared to 2018.

-- we can also dig deeper into hotel type--
		WITH Hotel AS (
		SELECT * FROM dbo.['2018']
		UNION
		SELECT * FROM dbo.['2019']
		UNION
		SELECT * FROM dbo.['2020'] )
		SELECT arrival_date_year,
		hotel,
		SUM(	stays_in_weekend_nights + stays_in_week_nights) 
		AS Total_week_nights,
		ROUND(	SUM(	(stays_in_weekend_nights + stays_in_week_nights)*adr),2) 
		AS Revnue  FROM hotel
		GROUP BY arrival_date_year,Hotel ORDER BY 2,1
-----------------------------------------------------------------------------------------------			
		WITH Hotel AS (
		SELECT * FROM dbo.['2018']
		UNION
		SELECT * FROM dbo.['2019']
		UNION
		SELECT * FROM dbo.['2020'] )
		SELECT hotel,
		SUM(	stays_in_weekend_nights + stays_in_week_nights) 
		AS Total_week_nights,
		ROUND(	SUM(	(stays_in_weekend_nights + stays_in_week_nights)*adr),2) 
		AS Revnue from hotel
		GROUP BY Hotel 
-- city hotel has slightly higher total revenue compared to restort hotel (about 9.14%)
-----------------------------------------------------------------------------------------------	
-- let's join the other two tables  ,market_segments and meal_coast.and calculate the revenue using total_nights ,adr, and discount.
-- we can also create view..

		CREATE VIEW hotel_data AS
		WITH Hotel AS (
		SELECT * FROM dbo.['2018']
		UNION
		SELECT * FROM dbo.['2019']
		UNION
		SELECT * FROM dbo.['2020'] )
		SELECT ((stays_in_week_nights+stays_in_weekend_nights)* adr * (1 - discount)) as total_revenue,
		ht.*, ms.market_segment AS ms_market_seg_2, ms.Discount, mc.Cost
		FROM Hotel as ht
		LEFT JOIN dbo.market_segment as ms
		ON  ht.market_segment = ms.market_segment
		LEFT JOIN dbo.meal_cost AS mc
		ON ht.meal = mc.meal;

-- "This is the query used to export data after performing cleaning and standardization:"
		SELECT 
			   round( [total_revenue],2)AS total_revenue -- "We can use 'round' to specify precision and limit decimal points to only two."
			  ,[hotel]
			  ,CASE is_canceled
			   WHEN 0 THEN 'No'
		 	   WHEN 1 THEN 'Yes'
		 	   END AS is_canceled --"To enhance the data's clarity, we will replace 0 with 'NO' and 1 with 'YES'."
			  ,[lead_time]
			  ,[arrival_date_year]
			  ,[arrival_date_month]
			  ,[arrival_date_week_number]
			  ,[arrival_date_day_of_month]
			  ,[stays_in_weekend_nights]
			  ,[stays_in_week_nights]
			  ,[adults]
			  ,[children]
			  ,[babies]
			  ,[country]
			  ,[market_segment]
			  ,[distribution_channel]
			  ,[is_repeated_guest]
			  ,[previous_cancellations]
			  ,[previous_bookings_not_canceled]
			  ,[reserved_room_type]
			  ,[assigned_room_type]
			  ,[booking_changes]
			  ,[deposit_type]
			  ,[agent]
			  ,[company]
			  ,[days_in_waiting_list]
			  ,[customer_type]
			  ,round([adr],2)Adr --"We can use 'round' to specify precision and limit decimal points to only two."
			  ,round([Discount],2)Discount --"We can use 'round' to specify precision and limit decimal points to only two."
			  ,[required_car_parking_spaces]
			  ,[total_of_special_requests]
			  ,[reservation_status]
			  ,FORMAT(reservation_status_date,'yyyy-MM-dd') as reservation_status_date --"We will remove the time information since it is not accurate."
			  ,[ms_market_seg_2]
			  ,[meal]
			  ,round([Cost],2) as Meal_coast --"We can use 'round' to specify precision and limit decimal points to only two."
		  FROM [Hotel_Revenue].[dbo].[hotel_data]



