-- Demo SQL Script for Oracle XE Tutorial
-- This script demonstrates basic Oracle SQL*Plus functionality

-- Set output formatting
SET PAGESIZE 20
SET LINESIZE 100
SET ECHO ON

-- Show current user and database
PROMPT =====================================================
PROMPT Oracle XE Demo Script
PROMPT =====================================================

SELECT USER as "Current User" FROM dual;
SELECT SYS_CONTEXT('USERENV','DB_NAME') as "Database Name" FROM dual;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') as "Current Time" FROM dual;

PROMPT
PROMPT =====================================================
PROMPT Creating Demo Tables
PROMPT =====================================================

-- Create employees table
CREATE TABLE employees (
    emp_id NUMBER(6) PRIMARY KEY,
    first_name VARCHAR2(20),
    last_name VARCHAR2(25) NOT NULL,
    email VARCHAR2(25) UNIQUE,
    phone_number VARCHAR2(20),
    hire_date DATE DEFAULT SYSDATE,
    job_id VARCHAR2(10),
    salary NUMBER(8,2),
    manager_id NUMBER(6),
    department_id NUMBER(4)
);

-- Create departments table
CREATE TABLE departments (
    dept_id NUMBER(4) PRIMARY KEY,
    dept_name VARCHAR2(30) NOT NULL,
    manager_id NUMBER(6),
    location_id NUMBER(4)
);

PROMPT Tables created successfully!

PROMPT
PROMPT =====================================================
PROMPT Inserting Sample Data
PROMPT =====================================================

-- Insert departments
INSERT INTO departments VALUES (10, 'Administration', 200, 1700);
INSERT INTO departments VALUES (20, 'Marketing', 201, 1800);
INSERT INTO departments VALUES (50, 'Shipping', 124, 1500);
INSERT INTO departments VALUES (60, 'IT', 103, 1400);
INSERT INTO departments VALUES (80, 'Sales', 145, 2500);
INSERT INTO departments VALUES (90, 'Executive', 100, 1700);

-- Insert employees
INSERT INTO employees VALUES (100, 'Steven', 'King', 'SKING', '515.123.4567', DATE '2003-06-17', 'AD_PRES', 24000, NULL, 90);
INSERT INTO employees VALUES (101, 'Neena', 'Kochhar', 'NKOCHHAR', '515.123.4568', DATE '2005-09-21', 'AD_VP', 17000, 100, 90);
INSERT INTO employees VALUES (102, 'Lex', 'De Haan', 'LDEHAAN', '515.123.4569', DATE '2001-01-13', 'AD_VP', 17000, 100, 90);
INSERT INTO employees VALUES (103, 'Alexander', 'Hunold', 'AHUNOLD', '590.423.4567', DATE '2006-01-03', 'IT_PROG', 9000, 102, 60);
INSERT INTO employees VALUES (104, 'Bruce', 'Ernst', 'BERNST', '590.423.4568', DATE '2007-05-21', 'IT_PROG', 6000, 103, 60);
INSERT INTO employees VALUES (124, 'Kevin', 'Mourgos', 'KMOURGOS', '650.123.5234', DATE '2007-11-16', 'ST_MAN', 5800, 100, 50);
INSERT INTO employees VALUES (145, 'John', 'Russell', 'JRUSSELL', '011.44.1344.429268', DATE '2004-10-01', 'SA_MAN', 14000, 100, 80);
INSERT INTO employees VALUES (200, 'Jennifer', 'Whalen', 'JWHALEN', '515.123.4444', DATE '2003-09-17', 'AD_ASST', 4400, 101, 10);
INSERT INTO employees VALUES (201, 'Michael', 'Hartstein', 'MHARTSTE', '515.123.5555', DATE '2004-02-17', 'MK_MAN', 13000, 100, 20);

COMMIT;

PROMPT Sample data inserted successfully!

PROMPT
PROMPT =====================================================
PROMPT Sample Queries
PROMPT =====================================================

PROMPT
PROMPT 1. List all employees:
SELECT emp_id, first_name, last_name, job_id, salary 
FROM employees 
ORDER BY emp_id;

PROMPT
PROMPT 2. List all departments:
SELECT dept_id, dept_name, manager_id 
FROM departments 
ORDER BY dept_id;

PROMPT
PROMPT 3. Employees with their department names:
SELECT e.first_name, e.last_name, e.salary, d.dept_name
FROM employees e 
JOIN departments d ON e.department_id = d.dept_id
ORDER BY e.salary DESC;

PROMPT
PROMPT 4. Average salary by department:
SELECT d.dept_name, 
       COUNT(e.emp_id) as "Number of Employees",
       ROUND(AVG(e.salary), 2) as "Average Salary"
FROM employees e 
JOIN departments d ON e.department_id = d.dept_id
GROUP BY d.dept_name
ORDER BY AVG(e.salary) DESC;

PROMPT
PROMPT 5. Highest paid employees:
SELECT first_name, last_name, salary
FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);

PROMPT
PROMPT =====================================================
PROMPT Demo Completed Successfully!
PROMPT =====================================================

PROMPT
PROMPT You can now experiment with:
PROMPT - SELECT statements to query data
PROMPT - INSERT statements to add new records  
PROMPT - UPDATE statements to modify data
PROMPT - DELETE statements to remove records
PROMPT - CREATE statements to make new objects
PROMPT
PROMPT Type 'EXIT;' when you're done exploring.
PROMPT