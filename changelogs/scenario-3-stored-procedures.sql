--liquibase formatted sql
--
-- SCENARIO 3: Stored Procedure Creation and Execution
--
-- Demonstrates that multi-line stored procedures with BEGIN/END blocks work
-- correctly via JDBC (without runWith:bteq). BTEQ cannot handle these inline
-- because it parses semicolons as statement terminators at the client level.
--
-- The procedure changeset uses JDBC (no runWith:bteq), while CALL statements
-- use runWith:bteq to capture output.
--
-- NOTE: This demo uses a regular table. Creating volatile tables inside
-- stored procedures requires EXECUTE IMMEDIATE or DBC.SYSEXECSQL which may
-- require additional permissions not available to all users.
--

--changeset demo:s3-create-table runWith:bteq
--comment: Create orders table for procedure demo
CREATE TABLE demo_orders (
    order_id INTEGER NOT NULL,
    product_name VARCHAR(100),
    quantity INTEGER
) PRIMARY INDEX (order_id);
--rollback DROP TABLE demo_orders;

--changeset demo:s3-create-order-procedure splitStatements:false
--comment: Create stored procedure with multiple statements (uses JDBC, not BTEQ)
REPLACE PROCEDURE insert_order(
    IN p_order_id INTEGER,
    IN p_product_name VARCHAR(100),
    IN p_quantity INTEGER
)
DYNAMIC RESULT SETS 1
BEGIN
    DECLARE sql_result VARCHAR(500);
    DECLARE c1 CURSOR WITH RETURN FOR s1;

    INSERT INTO demo_orders (order_id, product_name, quantity)
    VALUES (:p_order_id, :p_product_name, :p_quantity);

    SET sql_result = 'SELECT ''Order inserted'' AS status, order_id, product_name, quantity FROM demo_orders ORDER BY order_id';
    PREPARE s1 FROM sql_result;
    OPEN c1;
END;
--rollback DROP PROCEDURE insert_order;

--changeset demo:s3-call-procedure-1 runWith:bteq
--comment: Execute stored procedure (first order)
CALL insert_order(101, 'Widget A', 5);
--rollback DELETE FROM demo_orders WHERE order_id = 101;

--changeset demo:s3-call-procedure-2 runWith:bteq
--comment: Execute stored procedure (second order)
CALL insert_order(102, 'Gadget X', 3);
--rollback DELETE FROM demo_orders WHERE order_id = 102;

--changeset demo:s3-verify-orders runWith:bteq
--comment: Verify all orders were inserted
SELECT order_id, product_name, quantity
FROM demo_orders
ORDER BY order_id;
--rollback SELECT 'No rollback needed for SELECT query' AS info;

--changeset demo:s3-cleanup runWith:bteq
--comment: Clean up demo objects
DROP PROCEDURE insert_order;
DROP TABLE demo_orders;
--rollback SELECT 'Manual recreation required' AS info;
