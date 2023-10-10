/* The file contains exercises on birdstrikes table and answers on them.

/* Exercise 1
Based on the previous chapter, create a table called “employee” with two columns: “id” and “employee_name”. NULL values should not be accepted for these 2 columns.*/
USE birdstrikes;
DROP TABLE IF EXISTS employee;
CREATE TABLE employee 
(id INT NOT NULL,
employee_name VARCHAR(64) NOT NULL,
PRIMARY KEY(id));
-- Answer: It's an empty table with 2 columns: id and employee_name

/* Exercise 2
What state figures in the 145th line of our database? */
SELECT state FROM birdstrikes LIMIT 144,1;
-- Answer: 'Tennessee'

/* Exercise 3
What is flight_date of the latest birstrike in this database? */
SELECT flight_date FROM birdstrikes ORDER BY flight_date DESC LIMIT 1;
-- Answer: '2000-04-18'

/* Exercise 4
What was the cost of the 50th most expensive damage? */
SELECT cost FROM birdstrikes
ORDER BY cost DESC LIMIT 49, 1;
-- Answer: 5345

/* Exercise 5
What state figures in the 2nd record, if you filter out all records which have no state and no bird_size specified? */
SELECT state FROM birdstrikes
WHERE state !='' AND bird_size != '' LIMIT 1,1;
-- Answer: 'Colorado'

/* Exercise 6
How many days elapsed between the current date and the flights happening in week 52, for incidents from Colorado? (Hint: use NOW, DATEDIFF, WEEKOFYEAR) */
SELECT DATEDIFF(NOW(),flight_date) as elapsed_time FROM birdstrikes
WHERE WEEKOFYEAR(flight_date) = 52 AND state = 'Colorado';
-- Answer: 8684. Answer will be changed depending on the code execution date because of NOW() function
