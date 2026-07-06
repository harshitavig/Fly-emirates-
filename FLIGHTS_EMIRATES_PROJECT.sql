-- Database: flight_analysis

-- DROP DATABASE IF EXISTS flight_analysis;

CREATE DATABASE flight_analysis
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

	CREATE TABLE airlines (
    iata_code VARCHAR(5) PRIMARY KEY,
    airline VARCHAR(100)
     );
	 SELECT * FROM airlines;

	CREATE TABLE airports (
    iata_code VARCHAR(5) PRIMARY KEY,
    airport VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6)
     );
	 SELECT * FROM airports;

   CREATE TABLE flights(
   id INT,
   year INT,
   month INT,
   day INT,
   day_of_week INT,
   airline VARCHAR(10),
   flight_number INT,
   tail_number VARCHAR(20),
   origin_airport VARCHAR(10),
   destination_airport VARCHAR(10),

   scheduled_departure DOUBLE PRECISION,
   departure_time DOUBLE PRECISION,
   departure_delay DOUBLE PRECISION,
   taxi_out DOUBLE PRECISION,
   wheels_off DOUBLE PRECISION,
   scheduled_time DOUBLE PRECISION,
   elapsed_time DOUBLE PRECISION,
   air_time DOUBLE PRECISION,

   distance INT,

   wheels_on DOUBLE PRECISION,
   taxi_in DOUBLE PRECISION,
   scheduled_arrival DOUBLE PRECISION,
   arrival_time DOUBLE PRECISION,
   arrival_delay DOUBLE PRECISION,

   diverted INT,
   cancelled INT,

   cancellation_reason VARCHAR(5),

   air_system_delay DOUBLE PRECISION,
   security_delay DOUBLE PRECISION,
   airline_delay DOUBLE PRECISION,
   late_aircraft_delay DOUBLE PRECISION,
   weather_delay DOUBLE PRECISION
   );
   
   COPY flights
   FROM 'D:/flights_cleaned.csv'
   WITH (
    FORMAT csv,
    HEADER true
   );
  
  SELECT * FROM flights;

 # CREATING DATE COLUMN
  ALTER TABLE flights
  ADD COLUMN flight_date DATE;

  UPDATE flights
  SET flight_date = MAKE_DATE(year, month, day);

 # CONVERTING SCHEDULED DEPARTURE TIME TO PROPER TIME  
 SELECT
 LPAD(CAST(scheduled_departure AS INTEGER)::TEXT, 4, '0')
 FROM flights
 LIMIT 10;

 SELECT *,
       TO_TIMESTAMP(
          year || '-' ||
          LPAD(month::TEXT,2,'0') || '-' ||
          LPAD(day::TEXT,2,'0') || ' ' ||
          LPAD(CAST(scheduled_departure AS INTEGER)::TEXT,4,'0'),
          'YYYY-MM-DD HH24MI'
       ) AS scheduled_departure_datetime
FROM flights;

# CREATING COLUMN CANCELLATION_REASON_DESC
ALTER TABLE flights
ADD COLUMN cancellation_reason_desc VARCHAR(50);

UPDATE flights
SET cancellation_reason_desc =
CASE cancellation_reason
    WHEN 'A' THEN 'Airline/Carrier'
    WHEN 'B' THEN 'Weather'
    WHEN 'C' THEN 'National Air System'
    WHEN 'D' THEN 'Security'
    ELSE 'Not Cancelled'
END;

# INTEGRATION
CREATE VIEW flight_analysis_view AS
SELECT
    f.*,

    a.airline AS airline_name,

    oa.airport AS origin_airport_name,
    oa.city AS origin_city,
    oa.state AS origin_state,

    da.airport AS destination_airport_name,
    da.city AS destination_city,
    da.state AS destination_state

FROM flights f

LEFT JOIN airlines a
    ON f.airline = a.iata_code

LEFT JOIN airports oa
    ON f.origin_airport = oa.iata_code

LEFT JOIN airports da
    ON f.destination_airport = da.iata_code;


SELECT *
FROM flight_analysis_view
LIMIT 10;


# EXPLORATORY DATA ANALYSIS

1. Overall Flight Volume
    SELECT COUNT(*) AS total_flights
    FROM flight_analysis_view;

2. Total Cancelled Flights
     SELECT COUNT(*) AS total_cancelled
     FROM flight_analysis_view
     WHERE cancelled = 1;

3. Cancellation Rate
    SELECT ROUND(
    100.0 * SUM(cancelled) / COUNT(*),
    2
    ) AS cancellation_rate
    FROM flight_analysis_view;
	
4. Cancellations by Reason
   SELECT
    cancellation_reason_desc,
    COUNT(*) AS total_cancellations 
    FROM flight_analysis_view
    WHERE cancelled = 1
    GROUP BY cancellation_reason_desc
    ORDER BY total_cancellations DESC;
	
5. Total Diverted Flights
   SELECT COUNT(*) AS diverted_flights
   FROM flight_analysis_view
   WHERE diverted = 1;
   
6. Diversion Rate
   SELECT ROUND(
    100.0 * SUM(diverted) / COUNT(*),
    2
   ) AS diversion_rate
   FROM flight_analysis_view;
   
7. Average Departure Delay
   SELECT 
    AVG(departure_delay)
    AS avg_departure_delay
    FROM flight_analysis_view
    WHERE departure_delay IS NOT NULL;
	
8. Average Arrival Delay
    SELECT 
    AVG(arrival_delay)
    AS avg_arrival_delay
    FROM flight_analysis_view
    WHERE arrival_delay IS NOT NULL;
	
9. Min & Max Departure Delay
   SELECT
    MIN(departure_delay) AS min_departure_delay,
    MAX(departure_delay) AS max_departure_delay
    FROM flight_analysis_view;
	
10. Min & Max Arrival Delay
   SELECT
    MIN(arrival_delay) AS min_arrival_delay,
    MAX(arrival_delay) AS max_arrival_delay
    FROM flight_analysis_view;
	
11. Median Departure Delay
    SELECT
    PERCENTILE_CONT(0.5)
     WITHIN GROUP
     (ORDER BY departure_delay)
     AS median_departure_delay
     FROM flight_analysis_view
     WHERE departure_delay IS NOT NULL;
	 
12. Median Arrival Delay
    SELECT
    PERCENTILE_CONT(0.5)
    WITHIN GROUP
    (ORDER BY arrival_delay)
    AS median_arrival_delay
    FROM flight_analysis_view
    WHERE arrival_delay IS NOT NULL;
	
13. Distribution of Delay Types
   SELECT
   AVG(airline_delay) AS airline_delay,
   AVG(weather_delay) AS weather_delay,
   AVG(air_system_delay) AS nas_delay,
   AVG(security_delay) AS security_delay,
   AVG(late_aircraft_delay) AS late_aircraft_delay
   FROM flight_analysis_view;
   
14. Total Delay Minutes by Delay Type
   SELECT
   SUM(airline_delay) AS airline_delay,
   SUM(weather_delay) AS weather_delay,
   SUM(air_system_delay) AS nas_delay,
   SUM(security_delay) AS security_delay,
   SUM(late_aircraft_delay) AS late_aircraft_delay
   FROM flight_analysis_view;

15. Most Common Delay Type
    SELECT
    'Airline Delay' AS delay_type,
    SUM(airline_delay) AS total_delay
    FROM flight_analysis_view

UNION ALL

   SELECT
   'Weather Delay',
   SUM(weather_delay)
   FROM flight_analysis_view

UNION ALL

   SELECT
   'NAS Delay',
   SUM(air_system_delay)
   FROM flight_analysis_view

UNION ALL

   SELECT
   'Security Delay',
   SUM(security_delay)
   FROM flight_analysis_view

UNION ALL

   SELECT
   'Late Aircraft Delay',
   SUM(late_aircraft_delay)
   FROM flight_analysis_view

ORDER BY total_delay DESC;

#KPI

1. OTP Rate
SELECT
ROUND(
(
COUNT(*) FILTER (WHERE arrival_delay <= 15) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS otp_rate
FROM flight_analysis_view
WHERE cancelled = 0;

2. Average Arrival Delay
SELECT
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_arrival_delay
FROM flight_analysis_view
WHERE arrival_delay IS NOT NULL;

3. Average Departure Delay
SELECT
ROUND(
AVG(departure_delay)::NUMERIC,
2
) AS avg_departure_delay
FROM flight_analysis_view
WHERE departure_delay IS NOT NULL;

4. Cancellation Rate
SELECT
ROUND(
(
SUM(cancelled) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS cancellation_rate
FROM flight_analysis_view;

#KPI by Airline
1.OTP by Airline
SELECT
airline_name,
ROUND(
(
COUNT(*) FILTER (WHERE arrival_delay <= 15) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS otp_rate
FROM flight_analysis_view
WHERE cancelled = 0
GROUP BY airline_name
ORDER BY otp_rate DESC;

2.Avg Arrival Delay by Airline
SELECT
airline_name,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_arrival_delay
FROM flight_analysis_view
GROUP BY airline_name
ORDER BY avg_arrival_delay;

3.Cancellation Rate by Airline
SELECT
airline_name,
ROUND(
(
SUM(cancelled) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS cancellation_rate
FROM flight_analysis_view
GROUP BY airline_name
ORDER BY cancellation_rate DESC;

4.KPI by Origin Airport
SELECT
origin_airport_name,
COUNT(*) AS total_flights,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_delay,
ROUND(
(
SUM(cancelled) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS cancellation_rate
FROM flight_analysis_view
GROUP BY origin_airport_name
ORDER BY total_flights DESC;

5.KPI by Destination Airport
SELECT
destination_airport_name,
COUNT(*) AS total_flights,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_delay
FROM flight_analysis_view
GROUP BY destination_airport_name
ORDER BY total_flights DESC;

6.KPI by Month
SELECT
month,
COUNT(*) AS total_flights,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_delay,
ROUND(
(
SUM(cancelled) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS cancellation_rate
FROM flight_analysis_view
GROUP BY month
ORDER BY month;

7.KPI by Day of Week
SELECT
day_of_week,
COUNT(*) AS total_flights,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_delay
FROM flight_analysis_view
GROUP BY day_of_week
ORDER BY day_of_week;

8.KPI by Time of Day
SELECT
CASE
WHEN scheduled_departure BETWEEN 0 AND 559 THEN 'Night'
WHEN scheduled_departure BETWEEN 600 AND 1159 THEN 'Morning'
WHEN scheduled_departure BETWEEN 1200 AND 1759 THEN 'Afternoon'
ELSE 'Evening'
END AS time_of_day,
COUNT(*) AS total_flights,
ROUND(
AVG(arrival_delay)::NUMERIC,
2
) AS avg_delay,

ROUND(
(
SUM(cancelled) * 100.0
/
COUNT(*)
)::NUMERIC,
2
) AS cancellation_rate
FROM flight_analysis_view
GROUP BY time_of_day
ORDER BY total_flights DESC;