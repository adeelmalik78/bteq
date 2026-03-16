--liquibase formatted sql
--
-- SCENARIO 4: Rollback Output Visibility
--
-- Demonstrates that BTEQ captures the same rich logging output during
-- rollback as it does during forward deployment: DDL messages, DML row
-- counts, elapsed times, and query results. This is the key differentiator
-- vs JDBC, which only reports "Changeset rolled back successfully."
--
-- Demo workflow:
--   1. liquibase update   (deploy all changesets)
--   2. liquibase rollback-count 3  (roll back last 3 -- watch the BTEQ output)
--

--changeset demo:s4-create-tracking-table runWith:bteq
--comment: Create tracking table -rollback shows "Table has been dropped"
CREATE TABLE demo_tracking (
    tracking_id INTEGER NOT NULL,
    event_name VARCHAR(100),
    event_count INTEGER,
    event_date DATE
) PRIMARY INDEX (tracking_id);
--rollback DROP TABLE demo_tracking;

--changeset demo:s4-load-data runWith:bteq
--comment: Insert rows -rollback shows "Delete completed. N rows removed"
INSERT INTO demo_tracking VALUES (1, 'USER_LOGIN', 4200, DATE '2026-03-01');
INSERT INTO demo_tracking VALUES (2, 'PAGE_VIEW', 18500, DATE '2026-03-01');
INSERT INTO demo_tracking VALUES (3, 'API_CALL', 9300, DATE '2026-03-01');
INSERT INTO demo_tracking VALUES (4, 'FILE_UPLOAD', 750, DATE '2026-03-01');
INSERT INTO demo_tracking VALUES (5, 'REPORT_GEN', 320, DATE '2026-03-01');
--rollback DELETE FROM demo_tracking WHERE tracking_id IN (1,2,3,4,5);

--changeset demo:s4-add-column runWith:bteq
--comment: Alter table -rollback shows column dropped
ALTER TABLE demo_tracking ADD category VARCHAR(50) DEFAULT 'GENERAL';
--rollback ALTER TABLE demo_tracking DROP category;

--changeset demo:s4-update-categories runWith:bteq
--comment: Update rows -rollback shows "Update completed. N rows changed"
UPDATE demo_tracking SET category = 'AUTH' WHERE event_name = 'USER_LOGIN';
UPDATE demo_tracking SET category = 'TRAFFIC' WHERE event_name IN ('PAGE_VIEW', 'API_CALL');
UPDATE demo_tracking SET category = 'IO' WHERE event_name = 'FILE_UPLOAD';
UPDATE demo_tracking SET category = 'REPORT' WHERE event_name = 'REPORT_GEN';
--rollback UPDATE demo_tracking SET category = 'GENERAL';

--changeset demo:s4-create-summary-table runWith:bteq
--comment: Create summary table -rollback shows "Table has been dropped"
CREATE TABLE demo_tracking_summary (
    category VARCHAR(50),
    total_events INTEGER,
    last_updated DATE
) PRIMARY INDEX (category);

INSERT INTO demo_tracking_summary
SELECT category, SUM(event_count), MAX(event_date)
FROM demo_tracking
GROUP BY category;
--rollback DROP TABLE demo_tracking_summary;

--changeset demo:s4-create-macro runWith:bteq
--comment: Create reporting macro -rollback shows "Macro has been dropped"
CREATE MACRO demo_tracking_report AS (
    SELECT t.event_name, t.event_count, t.category,
           s.total_events AS category_total
    FROM demo_tracking t
    JOIN demo_tracking_summary s ON t.category = s.category
    ORDER BY t.event_count DESC;
);
--rollback DROP MACRO demo_tracking_report;
