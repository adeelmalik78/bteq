--liquibase formatted sql

--changeset demo:s2-create-inventory-table runWith:bteq
--comment: Create inventory table for query result streaming demonstration
CREATE TABLE demo_inventory (
    item_id INTEGER,
    item_name VARCHAR(100),
    quantity INTEGER,
    category VARCHAR(50)
);
--rollback DROP TABLE demo_inventory;

--changeset demo:s2-load-inventory-data runWith:bteq
--comment: Load sample inventory data
INSERT INTO demo_inventory VALUES (1, 'Laptop', 15, 'Electronics');
INSERT INTO demo_inventory VALUES (2, 'Mouse', 50, 'Electronics');
INSERT INTO demo_inventory VALUES (3, 'Keyboard', 35, 'Electronics');
INSERT INTO demo_inventory VALUES (4, 'Desk Chair', 20, 'Furniture');
INSERT INTO demo_inventory VALUES (5, 'Standing Desk', 10, 'Furniture');
INSERT INTO demo_inventory VALUES (6, 'Monitor', 25, 'Electronics');
INSERT INTO demo_inventory VALUES (7, 'Webcam', 30, 'Electronics');
INSERT INTO demo_inventory VALUES (8, 'Bookshelf', 12, 'Furniture');
INSERT INTO demo_inventory VALUES (9, 'Desk Lamp', 40, 'Furniture');
INSERT INTO demo_inventory VALUES (10, 'Cable Organizer', 100, 'Accessories');
--rollback DELETE FROM demo_inventory WHERE item_id BETWEEN 1 AND 10;

--changeset demo:s2-select-basic runWith:bteq
--comment: Basic SELECT query demonstrating result capture
SELECT item_id, item_name, quantity, category
FROM demo_inventory
ORDER BY item_id;
--rollback SELECT 'No rollback needed for SELECT query' AS info;

--changeset demo:s2-select-aggregates runWith:bteq
--comment: Aggregate query demonstrating multi-row streaming
SELECT category, COUNT(*) AS item_count, SUM(quantity) AS total_quantity
FROM demo_inventory
GROUP BY category
ORDER BY category;
--rollback SELECT 'No rollback needed for SELECT query' AS info;

--changeset demo:s2-select-minus-query runWith:bteq
--comment: MINUS query demonstrating zero-row result handling (backup validation pattern)
SELECT item_id, item_name FROM demo_inventory
MINUS
SELECT item_id, item_name FROM demo_inventory;
--rollback SELECT 'No rollback needed for SELECT query' AS info;

--changeset demo:s2-cleanup runWith:bteq
--comment: Clean up demo objects
DROP TABLE demo_inventory;
--rollback CREATE TABLE demo_inventory (item_id INTEGER, item_name VARCHAR(100), quantity INTEGER, category VARCHAR(50));
