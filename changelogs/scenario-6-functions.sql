--liquibase formatted sql
--
-- SCENARIO 6: SQL Functions with BEGIN/END Blocks
-- STATUS: KNOWN LIMITATION - This demo documents a BTEQ limitation, not a working feature
--
-- BTEQ cannot execute SQL functions with BEGIN/END blocks inline because it parses
-- semicolons as statement terminators at the client level. Unlike stored procedures,
-- there is NO .COMPILE FILE workaround for functions.
--
-- RECOMMENDATION: Remove runWith:bteq to use JDBC for functions with BEGIN/END blocks.
--
-- See: Issue #17 (https://github.com/recampbell/bteq-executor/issues/17)
-- Docs: docs/bteq-docs/06-bteq-commands.md - ".COMPILE FILE only works for stored procedures"
--

--changeset demo:s6-create-test-table runWith:bteq
--comment: Create table for function testing
CREATE TABLE demo_employees (
    emp_id INTEGER,
    emp_name VARCHAR(100),
    salary DECIMAL(10,2),
    dept_code VARCHAR(10),
    hire_date DATE
);
--rollback DROP TABLE demo_employees;

--changeset demo:s6-load-sample-data runWith:bteq
--comment: Load sample employee data
INSERT INTO demo_employees VALUES (1, 'Alice Smith', 75000.00, 'ENG', DATE '2020-01-15');
INSERT INTO demo_employees VALUES (2, 'Bob Johnson', 85000.00, 'ENG', DATE '2019-06-01');
INSERT INTO demo_employees VALUES (3, 'Carol White', 65000.00, 'SALES', DATE '2021-03-20');
INSERT INTO demo_employees VALUES (4, 'David Brown', 95000.00, 'MGMT', DATE '2018-11-10');
INSERT INTO demo_employees VALUES (5, 'Eve Davis', 55000.00, 'SALES', DATE '2022-08-05');
--rollback DELETE FROM demo_employees;

--changeset demo:s6-create-complex-function runWith:bteq
--comment: CRITICAL TEST - Multi-line function with branches, loops, and complex logic
REPLACE FUNCTION calculate_bonus(
    p_emp_id INTEGER,
    p_performance_rating INTEGER
)
RETURNS DECIMAL(10,2)
LANGUAGE SQL
DETERMINISTIC
CONTAINS SQL
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_dept VARCHAR(10);
    DECLARE v_years_employed INTEGER;
    DECLARE v_bonus_pct DECIMAL(5,2);
    DECLARE v_base_bonus DECIMAL(10,2);
    DECLARE v_final_bonus DECIMAL(10,2);

    -- Get employee details
    SELECT salary, dept_code,
           EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM hire_date)
    INTO v_salary, v_dept, v_years_employed
    FROM demo_employees
    WHERE emp_id = p_emp_id;

    -- Determine base bonus percentage based on department
    IF v_dept = 'MGMT' THEN
        SET v_bonus_pct = 0.20;
    ELSEIF v_dept = 'ENG' THEN
        SET v_bonus_pct = 0.15;
    ELSEIF v_dept = 'SALES' THEN
        SET v_bonus_pct = 0.10;
    ELSE
        SET v_bonus_pct = 0.05;
    END IF;

    -- Calculate base bonus
    SET v_base_bonus = v_salary * v_bonus_pct;

    -- Apply performance multiplier using CASE
    CASE p_performance_rating
        WHEN 5 THEN SET v_final_bonus = v_base_bonus * 1.50;
        WHEN 4 THEN SET v_final_bonus = v_base_bonus * 1.25;
        WHEN 3 THEN SET v_final_bonus = v_base_bonus * 1.00;
        WHEN 2 THEN SET v_final_bonus = v_base_bonus * 0.75;
        ELSE SET v_final_bonus = v_base_bonus * 0.50;
    END CASE;

    -- Add tenure bonus (loop simulation with conditional)
    WHILE v_years_employed > 0 DO
        SET v_final_bonus = v_final_bonus + 500.00;
        SET v_years_employed = v_years_employed - 1;
    END WHILE;

    RETURN v_final_bonus;
END;
--rollback DROP FUNCTION calculate_bonus;

--changeset demo:s6-test-function runWith:bteq
--comment: Test the function with various inputs
SELECT emp_id, emp_name, salary, dept_code,
       calculate_bonus(emp_id, 5) AS bonus_excellent,
       calculate_bonus(emp_id, 3) AS bonus_average,
       calculate_bonus(emp_id, 1) AS bonus_poor
FROM demo_employees
ORDER BY emp_id;
--rollback SELECT 'No rollback needed for SELECT' AS info;

--changeset demo:s6-cleanup runWith:bteq
--comment: Clean up demo objects
DROP FUNCTION calculate_bonus;
DROP TABLE demo_employees;
--rollback SELECT 'No rollback for cleanup' AS info;
