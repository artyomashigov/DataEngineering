/*INNER join orders,orderdetails,products and customers. Return back:
orderNumber
priceEach
quantityOrdered
productName
productLine
city
country
orderDate */

USE classicmodels;

-- To check the tables content
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM orderdetails;

-- Solution
SELECT 
    orderNumber,
    priceEach,
    quantityOrdered,
    productName,
    productLine,
    city,
    country,
    orderDate
FROM
    customers c
        INNER JOIN
    orders o USING (customerNumber)
        INNER JOIN
    orderdetails od USING (orderNumber)
        INNER JOIN
    products p USING (productCode);


