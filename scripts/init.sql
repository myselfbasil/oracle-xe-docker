-- Oracle XE Initialization Script
-- This script runs during container startup to set up the database

-- Connect as SYSDBA
CONNECT / AS SYSDBA

-- Start the database if not already started
STARTUP;

-- Create pluggable database if it doesn't exist
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM v$pdbs WHERE name = 'XEPDB1';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE XEPDB1 ADMIN USER pdbadmin IDENTIFIED BY "OracleXE123!"';
        EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE XEPDB1 OPEN';
    END IF;
END;
/

-- Save configuration
ALTER PLUGGABLE DATABASE XEPDB1 SAVE STATE;

-- Connect to PDB and create demo schema
ALTER SESSION SET CONTAINER = XEPDB1;

-- Create demo user if it doesn't exist
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'DEMO';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER demo IDENTIFIED BY "demo123"';
        EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO demo';
        EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO demo';
    END IF;
END;
/

-- Connect as demo user and create sample objects
CONNECT demo/demo123@XEPDB1;

-- Create demo table
CREATE TABLE demo_tutorial (
    id NUMBER PRIMARY KEY,
    message VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE
);

-- Insert sample data
INSERT INTO demo_tutorial (id, message) VALUES (1, 'Welcome to Oracle XE!');
INSERT INTO demo_tutorial (id, message) VALUES (2, 'SQL*Plus is ready for use');
INSERT INTO demo_tutorial (id, message) VALUES (3, 'Happy learning!');

COMMIT;

-- Create a simple view
CREATE OR REPLACE VIEW demo_view AS
SELECT id, message, TO_CHAR(created_date, 'YYYY-MM-DD HH24:MI:SS') as formatted_date
FROM demo_tutorial;

-- Show completion message
SELECT 'Database initialization completed successfully!' as status FROM dual;

EXIT;