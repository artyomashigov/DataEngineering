/* PART 2: Analytics plan

Using the stolen_vehicles dataset we can analyze:

What days of the week see the highest and lowest rates of vehicle theft?
Which vehicle types are most and least frequently stolen? Does this vary by region?
What is the percentage of stolen Luxury cars?
What is the average age of the stolen vehicles, and does it vary based on the vehicle type?
What is the number of thefts for different density levels?
Which regions experience the most and least number of stolen vehicles, and what are the characteristics of these regions? */

/*The analytical layer will be created using stored procedures and triggers. 
Data marts will help to find answers for police departments in different regions of New Zealand. 
*/


-- STEP 1
/* For convention, we will use 'stolen_vehicles' database because otherwise,
 we will need to use the 'stolen_vehicles.table_name' structure to access the tables. */

USE stolen_vehicles;

-- STEP 2: Check the contenct of database and tables
SHOW TABLES;
SELECT * FROM stolen_vehicles;
SELECT * FROM make_details;
SELECT * FROM locations;

-- STEP 3
/* Select all necessary fields for analytical data layer
We don't include country column because this dataset is only about stolen vehicles in New Zealand */

SELECT 
    vehicle_id,
    vehicle_type,
    model_year,
    vehicle_desc,
    color,
    date_stolen,
    make_name,
    make_type,
    region,
    population,
    density
FROM
    stolen_vehicles
        LEFT JOIN
    make_details USING (make_id)
        LEFT JOIN
    locations USING (location_id);

-- STEP 4
/* Changing the names of columns of appropriate datasets */

SELECT 
    vehicle_id,
    vehicle_type,
    model_year AS production_year,
    vehicle_desc AS description_,
    color,
    date_stolen AS date_of_theft,
    make_name AS manufacturer,
    make_type AS class,
    region,
    FORMAT(population, 0) AS population,
    ROUND(density) AS density,
    CASE
        WHEN density < 100 THEN 'LOW'
        ELSE 'HIGH'
    END AS density_level
FROM
    stolen_vehicles s
        LEFT JOIN
    make_details m USING (make_id)
        LEFT JOIN
    locations l USING (location_id);



-- PART 3: Creating an analytical data layer
-- STEP 1: Creating a stored procedure for analysis

DROP PROCEDURE IF EXISTS CreateStolenVehiclesRecords;

DELIMITER $$

CREATE PROCEDURE CreateStolenVehiclesRecords()
BEGIN

	DROP TABLE IF EXISTS stolen_vehicles_records;
    
    -- Creating analytical layer
	CREATE TABLE stolen_vehicles_records AS 
    SELECT vehicle_id,
    vehicle_type,
    model_year AS production_year,
    vehicle_desc AS description_,
    color,
    date_stolen AS date_of_theft,
    m.make_name AS manufacturer,
    m.make_type AS class,
    l.region,
    FORMAT(l.population, 0) AS population,
    ROUND(l.density) AS density,
    CASE
        WHEN density < 100 THEN 'LOW'
        ELSE 'HIGH'
    END AS density_level FROM
    stolen_vehicles s
        LEFT JOIN
    make_details m USING (make_id)
        LEFT JOIN
    locations l USING (location_id);

END $$
DELIMITER ;

/* Extraction: In this scenario, the extraction is taking place from the tables 'stolen_vehicles', 'make_details', and 'locations'.

Transformation: The transformation part involves several aspects:

Renaming certain columns using aliases (e.g., renaming 'model_year' as 'production_year', 'vehicle_desc' as 'description_', and 'm.make_name' as 'manufacturer').
Formatting the population using the 'FORMAT' function.
Rounding the density using the 'ROUND' function.
Creating a new column 'density_level' based on the value of the 'density' column.
Loading: The loading step occurs when the transformed data is being inserted into the 'stolen_vehicles_records' table, which is created using the 'CREATE TABLE' statement.*/


-- STEP 2: Executing the stored procedure
CALL CreateStolenVehiclesRecords();

-- Checking the result table
SELECT * FROM stolen_vehicles_records;

SELECT COUNT(*) as numberofrecords FROM stolen_vehicles_records;

-- STEP 3: Creating additional stored procedures that might be useful

DROP PROCEDURE IF EXISTS GetRecordsByRegion;

DELIMITER $$

CREATE PROCEDURE GetRecordsByRegion(
	IN regionName VARCHAR(255)
)
BEGIN
	SELECT * 
 		FROM stolen_vehicles_records
			WHERE region = regionName;
END $$
DELIMITER ;

-- Another stored procedure

DROP PROCEDURE IF EXISTS GetRecordsByManufacturer;

DELIMITER $$

CREATE PROCEDURE GetRecordsByManufacturer(
	IN manufacturerName VARCHAR(255)
)
BEGIN
	SELECT * 
 		FROM stolen_vehicles_records
			WHERE manufacturer LIKE CONCAT('%', manufacturerName, '%');
END $$
DELIMITER ;

-- Checking the created stored procedures
CALL GetRecordsByRegion('Auckland');
CALL GetRecordsByManufacturer('built');

-- PART 4: Triggers(ETL)
-- STEP 1: Creating log table for tracking new inserted records
DROP TABLE IF EXISTS logs_;
CREATE TABLE logs_ (date_time DATETIME NOT NULL, log VARCHAR(100) NOT NULL);

-- Checking the table
SELECT * FROM logs_;

-- STEP 2: Adding triggers to our analytical layer to have up to date table
/* Creating a trigger that activates when an insertion occurs in the 'stolen_vehicles' table.
 Once triggered, it will add a new record to our existing data table. */
 
DROP TRIGGER IF EXISTS after_record_insert; 

DELIMITER $$

CREATE TRIGGER after_record_insert
AFTER INSERT
ON stolen_vehicles FOR EACH ROW
BEGIN
	
	-- adding the vehicle_id and the time of new inserted record
	INSERT INTO logs_ SELECT NOW(), CONCAT('new vehicle_id: ', NEW.vehicle_id);

	-- inserting new records
  	INSERT INTO stolen_vehicles_records
	SELECT vehicle_id,
    vehicle_type,
    model_year AS production_year,
    vehicle_desc AS description_,
    color,
    date_stolen AS date_of_theft,
    m.make_name AS manufacturer,
    m.make_type AS class,
    l.region,
    FORMAT(l.population, 0) AS population,
    ROUND(l.density) AS density,
    CASE
        WHEN density < 100 THEN 'LOW'
        ELSE 'HIGH'
    END AS density_level FROM
    stolen_vehicles s
        LEFT JOIN
    make_details m USING (make_id)
        LEFT JOIN
    locations l USING (location_id)
    WHERE vehicle_id = NEW.vehicle_id;
        
END $$

DELIMITER ;

/* Extract: Our extract operation is joining the tables for analytical layer

Transform: We are transorming the density, population and adding new density level column. 

Load: Inserting the records into the stolen_vehicles_records is the load part of the ETL*/



-- STEP 3: Checking the current state of stolen_vehicles_records
SELECT * FROM stolen_vehicles_records;

-- STEP 4: Activating the trigger
INSERT INTO stolen_vehicles (vehicle_type, make_id, model_year, vehicle_desc, color, date_stolen, location_id) 
VALUES ('Hatchback', 540, 2017, 'FOCUS', 'Black', '2022-03-30', 105);
INSERT INTO stolen_vehicles (vehicle_type, make_id, model_year, vehicle_desc, color, date_stolen, location_id) 
VALUES('Saloon', 555, 2013,'SONATA','BLUE','2022-02-11',114);
INSERT INTO stolen_vehicles (vehicle_type, make_id, model_year, vehicle_desc, color, date_stolen, location_id)
VALUES('All Terrain Vehicle', 512, 2010,'X5','WHITE','2022-01-18',114);


-- STEP 5: Checking stolen_vehicles_records after inserting new values
SELECT * FROM stolen_vehicles_records;
-- Checking the logs_
SELECT * FROM logs_;
-- Checking the triggers
SHOW TRIGGERS;

-- STEP 6: Deleting added rows to keep the validity of data
DELETE FROM stolen_vehicles WHERE vehicle_id > 4553;
DELETE FROM stolen_vehicles_records WHERE vehicle_id > 4553;
TRUNCATE logs_;


-- PART 5: Creating Data marts
-- STEP 1: Creating view for different regions
-- Region = 'Auckland'
DROP VIEW IF EXISTS Auckland;

CREATE VIEW `Auckland` AS
SELECT * FROM stolen_vehicles_records WHERE region = 'Auckland';
-- To check the data mart
SELECT * FROM Auckland;

-- Region = 'Welington'
DROP VIEW IF EXISTS Wellington;

CREATE VIEW `Wellington` AS
SELECT * FROM stolen_vehicles_records WHERE region = 'Wellington';
-- To check the data mart
SELECT * FROM Wellington;

-- STEP 2: Creating a view for water vehicles
/*What if Maritime Unit (water police in New Zealand) wants to investigate water vehicles?
We can create a view for that purpose */

DROP VIEW IF EXISTS water_vehicles;

CREATE VIEW `water_vehicles` AS
SELECT * FROM stolen_vehicles WHERE vehicle_type LIKE '%boat%';

-- To check the data mart
SELECT * FROM water_vehicles;

-- Checking all views
SHOW FULL TABLES
WHERE Table_type = 'VIEW';


-- Answers to our questions from analytical plan
-- 1. What days of the week see the highest and lowest rates of vehicle theft?
-- Highest rates: Answer - Monday 767

SELECT DAYNAME(date_of_theft) as weekday, COUNT(*) as number_of_thefts
FROM stolen_vehicles_records
GROUP BY weekday
ORDER BY number_of_thefts DESC LIMIT 1;

-- Lowest rates: Answer - Saturday 577
SELECT DAYNAME(date_of_theft) as weekday, COUNT(*) as number_of_thefts
FROM stolen_vehicles_records
GROUP BY weekday
ORDER BY number_of_thefts ASC LIMIT 1;

-- 2. Which vehicle types are most and least frequently stolen? Does this vary by region?
-- Answer: Least frequently stolen are Special Purpose Vehicle and Articulated Truck both once. Most stolen Stationwagon 945 times
SELECT vehicle_type, COUNT(*) as number_of_thefts
FROM stolen_vehicles_records
GROUP BY vehicle_type
ORDER BY 2 DESC;
-- Answer it varies by region. For example in Auckland it's Saloon, in Canterbury is Stationwagon, in Hawke's Bay it's Trailer
SELECT vehicle_type, region, COUNT(*) as number_of_thefts
FROM stolen_vehicles_records
GROUP BY vehicle_type, region
ORDER BY 2,3 DESC;

-- 3. What is the percentage of stolen Luxury cars?
SELECT 
    (COUNT(CASE WHEN class = 'Luxury' THEN 1 END) / COUNT(*)) * 100 AS percentage
FROM 
    stolen_vehicles_records;

-- 4. What is the number of thefts for different density levels?
SELECT density_level, COUNT(*) as number_of_thefts
FROM stolen_vehicles_records
GROUP BY density_level;

-- 5. What is the average age of the stolen vehicles, and does it vary based on the vehicle type?
	
SELECT 
    vehicle_type,
    ROUND(AVG(YEAR(date_of_theft) - production_year)) AS average_age
FROM 
    stolen_vehicles_records
GROUP BY 
    vehicle_type;

-- 6. Which regions experience the most and least number of stolen vehicles, and what are the characteristics of these regions? 

SELECT region, COUNT(*) as number_of_thefts, population, density
FROM stolen_vehicles_records
GROUP BY region







 
