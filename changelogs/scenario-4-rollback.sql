--liquibase formatted sql

--changeset demo:s4-create-customer-table runWith:bteq
--comment: Create customers table for rollback demonstration
CREATE TABLE demo_customers (
    customer_id INTEGER,
    customer_name VARCHAR(100)
);
--rollback DROP TABLE demo_customers;

--changeset demo:s4-insert-customer-1 runWith:bteq
--comment: Insert first customer (baseline tag)
INSERT INTO demo_customers VALUES (1, 'Alice');
--rollback DELETE FROM demo_customers WHERE customer_id = 1;
--liquibase tagDatabase:baseline

--changeset demo:s4-insert-customer-2 runWith:bteq
--comment: Insert second customer
INSERT INTO demo_customers VALUES (2, 'Bob');
--rollback DELETE FROM demo_customers WHERE customer_id = 2;

--changeset demo:s4-insert-customer-3 runWith:bteq
--comment: Insert third customer (three-customers tag)
INSERT INTO demo_customers VALUES (3, 'Charlie');
--rollback DELETE FROM demo_customers WHERE customer_id = 3;
--liquibase tagDatabase:three-customers

--changeset demo:s4-insert-customer-4 runWith:bteq
--comment: Insert fourth customer
INSERT INTO demo_customers VALUES (4, 'Diana');
--rollback DELETE FROM demo_customers WHERE customer_id = 4;

--changeset demo:s4-insert-customer-5 runWith:bteq
--comment: Insert fifth customer
INSERT INTO demo_customers VALUES (5, 'Eve');
--rollback DELETE FROM demo_customers WHERE customer_id = 5;

--changeset demo:s4-verify-count runWith:bteq
--comment: Verify all five customers are present
SELECT COUNT(*) AS customer_count FROM demo_customers;
SELECT customer_id, customer_name FROM demo_customers ORDER BY customer_id;
--rollback SELECT 'Verification query - no data rollback needed' AS info;
