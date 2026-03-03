--liquibase formatted sql

--changeset demo:s5-audit-logging runWith:bteq
--comment: Demonstrates BTEQ native executor capturing rich logging output for audit/compliance
--comment: This changeset showcases the key logging features the customer requires:
--comment: 1. Execution time/elapsed time
--comment: 2. Status of execution (Statement Completed/Failed)
--comment: 3. Outcome of DML/DDL operations
--comment: 4. Rows with columns and data for queries

-- Step 1: Create a test table (shows "Table has been created" message)
CREATE TABLE demo_audit (
    audit_id INTEGER NOT NULL,
    operation_name VARCHAR(100),
    record_count INTEGER,
    execution_date DATE,
    status_code VARCHAR(20)
);

-- Step 2: Insert multiple rows (shows "Insert completed. N rows added" message)
INSERT INTO demo_audit VALUES
    (1, 'CUSTOMER_LOAD', 150000, DATE '2026-01-19', 'SUCCESS'),
    (2, 'ORDER_PROCESSING', 45000, DATE '2026-01-19', 'SUCCESS'),
    (3, 'INVENTORY_UPDATE', 8500, DATE '2026-01-19', 'SUCCESS'),
    (4, 'PAYMENT_VALIDATION', 12000, DATE '2026-01-19', 'SUCCESS'),
    (5, 'SHIPMENT_TRACKING', 6200, DATE '2026-01-19', 'SUCCESS');

-- Step 3: Update records (shows "Update completed. N rows changed" message)
UPDATE demo_audit
SET status_code = 'VERIFIED'
WHERE record_count > 10000;

-- Step 4: Query with results (shows row count, columns, and data)
SELECT
    operation_name AS "Operation",
    record_count AS "Records Processed",
    status_code AS "Status",
    execution_date AS "Date"
FROM demo_audit
ORDER BY record_count DESC;

-- Step 5: Aggregate query (shows elapsed time for complex query)
SELECT
    status_code AS "Status",
    COUNT(*) AS "Operation Count",
    SUM(record_count) AS "Total Records"
FROM demo_audit
GROUP BY status_code
ORDER BY 1;

-- Step 6: Cleanup - Drop the test table (shows "Table has been dropped" message)
DROP TABLE demo_audit;

--rollback DROP TABLE IF EXISTS demo_audit;
