-- Example
USE birdstrikes;
SELECT aircraft, airline, cost, 
    CASE 
        WHEN cost  = 0
            THEN 'NO COST'
        WHEN  cost >0 AND cost < 100000
            THEN 'MEDIUM COST'
        ELSE 
            'HIGH COST'
    END
    AS cost_category   
FROM  birdstrikes
ORDER BY cost_category;

-- Exercise 1: Do the same with speed. If speed is NULL or speed < 100 create a “LOW SPEED” category, otherwise, mark as “HIGH SPEED”. Use IF instead of CASE!

SELECT 
    aircraft,
    airline,
    speed,
    CASE
        WHEN speed IS NULL OR speed < 100 THEN 'LOW SPEED'
        ELSE 'HIGH SPEED'
    END AS speed_category
FROM
    birdstrikes
ORDER BY speed_category;

-- Exercise 2: How many distinct ‘aircraft’ we have in the database?
SELECT 
    COUNT(DISTINCT aircraft) AS aircraft_dis
FROM
    birdstrikes
WHERE
    aircraft != '';
-- Answer: 2 . 'Airplane' and 'Helicopter'

-- Exercise 3: What was the lowest speed of aircrafts starting with ‘H’
SELECT 
    MIN(speed) as lowest_speed
FROM
    birdstrikes
WHERE
    aircraft LIKE 'H%';
-- Answer: 9

-- Exercise 4: Which phase_of_flight has the least of incidents?
SELECT 
    phase_of_flight, COUNT(*) AS incidents_number
FROM
    birdstrikes
WHERE
    phase_of_flight != ''
GROUP BY phase_of_flight
ORDER BY incidents_number
LIMIT 1;
-- Answer: 'Taxi'

-- Exercise 5: What is the rounded highest average cost by phase_of_flight?
SELECT 
    phase_of_flight, ROUND(AVG(cost)) AS highest_average_cost
FROM
    birdstrikes
WHERE
    phase_of_flight != ''
GROUP BY phase_of_flight
ORDER BY highest_average_cost DESC
LIMIT 1;
-- Answer: 54673. Phase of flight is Climb

-- Exercise 6: What is the highest AVG speed of the states with names less than 5 characters?
SELECT state, AVG(speed) as average_speed
FROM birdstrikes
WHERE LENGTH(state) < 5 and state != ''
GROUP BY state
ORDER BY average_speed DESC
LIMIT 1;
-- Answer: 'Iowa'. 2862.5
