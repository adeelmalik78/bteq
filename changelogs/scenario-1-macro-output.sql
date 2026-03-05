--liquibase formatted sql

--changeset demo:s1-create-demo-tables runWith:bteq
--comment: Create tables for macro execution demonstration
-- .SET ERRORLEVEL 3807 SEVERITY 0

CREATE TABLE demo_products (
    product_id INTEGER,
    product_name VARCHAR(100)
);

CREATE TABLE demo_orders (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER
);
--rollback DROP TABLE demo_orders;
--rollback DROP TABLE demo_products;

--changeset demo:s1-create-validation-macro runWith:bteq splitStatements:false
--comment: Create macro that returns table row counts
REPLACE MACRO validate_deployment AS (
    SELECT 'demo_products' AS table_name, COUNT(*) AS row_count
    FROM demo_products
    UNION ALL
    SELECT 'demo_orders' AS table_name, COUNT(*) AS row_count
    FROM demo_orders;
);
--rollback DROP MACRO validate_deployment;

--changeset demo:s1-load-sample-data runWith:bteq
--comment: Insert sample product data
INSERT INTO demo_products VALUES (1, 'Widget A');
INSERT INTO demo_products VALUES (2, 'Widget B');
INSERT INTO demo_products VALUES (3, 'Gadget X');
INSERT INTO demo_products VALUES (4, 'Gadget Y');
--rollback DELETE FROM demo_products WHERE product_id IN (1, 2, 3, 4);

--changeset demo:s1-exec-validation-macro runWith:bteq
--comment: Execute validation macro to demonstrate output capture
EXEC validate_deployment;
--rollback SELECT 'No rollback needed for SELECT query' AS info;

--changeset demo:s1-cleanup runWith:bteq
--comment: Clean up demo objects
DROP MACRO validate_deployment;
DROP TABLE demo_orders;
DROP TABLE demo_products;
--rollback CREATE TABLE demo_products (product_id INTEGER, product_name VARCHAR(100));
--rollback CREATE TABLE demo_orders (order_id INTEGER, product_id INTEGER, quantity INTEGER);
--rollback REPLACE MACRO validate_deployment AS (SELECT 'demo_products' AS table_name, COUNT(*) AS row_count FROM demo_products UNION ALL SELECT 'demo_orders' AS table_name, COUNT(*) AS row_count FROM demo_orders;);
