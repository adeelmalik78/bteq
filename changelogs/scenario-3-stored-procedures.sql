--liquibase formatted sql
--
-- SCENARIO 3: Stored Procedure Creation and Execution
--
-- Demonstrates creating and calling stored procedures via BTEQ.
-- BTEQ cannot handle BEGIN/END blocks inline because it parses semicolons as
-- statement terminators. To work around this, the BTEQ executor automatically
-- detects stored procedure DDL (CREATE/REPLACE PROCEDURE) in runWith:bteq,
-- extracts the procedure body into a dynamically generated .spl
-- file, and replaces the original SQL with a .COMPILE FILE command pointing
-- at the extracted .spl file. This happens transparently; the changelog
-- author writes standard procedure DDL and the executor handles the rest.
--
-- This scenario also tests that rollback blocks containing stored procedure
-- DDL are handled the same way (auto-extracted to .spl with .COMPILE FILE).
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

--changeset demo:s3-create-order-procedure-v1 runWith:bteq
--comment: Create stored procedure v1 (executor auto-extracts to .spl and uses .COMPILE FILE)
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
--comment: Execute stored procedure v1 (first order)
CALL insert_order(101, 'Widget A', 5);
--rollback DELETE FROM demo_orders WHERE order_id = 101;

--changeset demo:s3-update-procedure-v2 runWith:bteq
--comment: Update procedure to v2 - rollback restores v1 (tests .COMPILE FILE in rollback)
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

    SET sql_result = 'SELECT ''Order confirmed'' AS status, order_id, product_name, quantity FROM demo_orders ORDER BY order_id';
    PREPARE s1 FROM sql_result;
    OPEN c1;
END;

--rollback REPLACE PROCEDURE insert_order(
--rollback     IN p_order_id INTEGER,
--rollback     IN p_product_name VARCHAR(100),
--rollback     IN p_quantity INTEGER
--rollback )
--rollback DYNAMIC RESULT SETS 1
--rollback BEGIN
--rollback     DECLARE sql_result VARCHAR(500);
--rollback     DECLARE c1 CURSOR WITH RETURN FOR s1;
--rollback
--rollback     INSERT INTO demo_orders (order_id, product_name, quantity)
--rollback     VALUES (:p_order_id, :p_product_name, :p_quantity);
--rollback
--rollback     SET sql_result = 'SELECT ''Order inserted'' AS status, order_id, product_name, quantity FROM demo_orders ORDER BY order_id';
--rollback     PREPARE s1 FROM sql_result;
--rollback     OPEN c1;
--rollback END;

--changeset demo:s3-call-procedure-2 runWith:bteq
--comment: Execute stored procedure v2 (second order - should show "Order confirmed")
CALL insert_order(102, 'Gadget X', 3);
--rollback DELETE FROM demo_orders WHERE order_id = 102;

--changeset demo:s3-verify-orders runWith:bteq
--comment: Verify all orders were inserted
SELECT order_id, product_name, quantity
FROM demo_orders
ORDER BY order_id;
--rollback SELECT 'No rollback needed for SELECT query' AS info;
