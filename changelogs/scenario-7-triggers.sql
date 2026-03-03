--liquibase formatted sql
--
-- SCENARIO 7: Triggers with BEGIN/END Blocks
-- STATUS: KNOWN LIMITATION - This demo documents a BTEQ limitation, not a working feature
--
-- BTEQ cannot execute triggers with BEGIN/END blocks inline because it parses
-- semicolons as statement terminators at the client level. Unlike stored procedures,
-- there is NO .COMPILE FILE workaround for triggers.
--
-- RECOMMENDATION: Remove runWith:bteq to use JDBC for triggers with BEGIN/END blocks.
--
-- See: Issue #17 (https://github.com/recampbell/bteq-executor/issues/17)
-- Docs: docs/bteq-docs/06-bteq-commands.md - ".COMPILE FILE only works for stored procedures"
--

--changeset demo:s7-create-tables runWith:bteq
--comment: Create tables for trigger testing
CREATE TABLE demo_accounts (
    account_id INTEGER,
    account_name VARCHAR(100),
    balance DECIMAL(15,2),
    account_type VARCHAR(20),
    is_active INTEGER DEFAULT 1,
    last_modified TIMESTAMP
);

CREATE TABLE demo_audit_log (
    log_id INTEGER GENERATED ALWAYS AS IDENTITY,
    table_name VARCHAR(100),
    operation VARCHAR(20),
    account_id INTEGER,
    old_balance DECIMAL(15,2),
    new_balance DECIMAL(15,2),
    change_amount DECIMAL(15,2),
    change_category VARCHAR(50),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logged_by VARCHAR(100)
);

CREATE TABLE demo_alerts (
    alert_id INTEGER GENERATED ALWAYS AS IDENTITY,
    alert_type VARCHAR(50),
    account_id INTEGER,
    message VARCHAR(500),
    severity INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--rollback DROP TABLE demo_alerts;
--rollback DROP TABLE demo_audit_log;
--rollback DROP TABLE demo_accounts;

--changeset demo:s7-load-sample-data runWith:bteq
--comment: Load sample account data
INSERT INTO demo_accounts (account_id, account_name, balance, account_type, last_modified)
VALUES (1001, 'Operating Account', 50000.00, 'CHECKING', CURRENT_TIMESTAMP);
INSERT INTO demo_accounts (account_id, account_name, balance, account_type, last_modified)
VALUES (1002, 'Savings Reserve', 150000.00, 'SAVINGS', CURRENT_TIMESTAMP);
INSERT INTO demo_accounts (account_id, account_name, balance, account_type, last_modified)
VALUES (1003, 'Investment Fund', 500000.00, 'INVESTMENT', CURRENT_TIMESTAMP);
--rollback DELETE FROM demo_accounts;

--changeset demo:s7-create-complex-trigger runWith:bteq
--comment: CRITICAL TEST - Multi-line trigger with branches, loops, error handling
REPLACE TRIGGER trg_account_balance_audit
AFTER UPDATE OF balance ON demo_accounts
REFERENCING OLD AS old_row NEW AS new_row
FOR EACH ROW
BEGIN
    DECLARE v_change_amount DECIMAL(15,2);
    DECLARE v_change_category VARCHAR(50);
    DECLARE v_alert_severity INTEGER;
    DECLARE v_alert_message VARCHAR(500);
    DECLARE v_threshold_pct DECIMAL(5,2);
    DECLARE v_large_change_threshold DECIMAL(15,2);

    -- Calculate the change amount
    SET v_change_amount = new_row.balance - old_row.balance;

    -- Determine change category based on amount and direction
    IF v_change_amount > 0 THEN
        IF v_change_amount >= 100000.00 THEN
            SET v_change_category = 'LARGE_DEPOSIT';
        ELSEIF v_change_amount >= 10000.00 THEN
            SET v_change_category = 'MEDIUM_DEPOSIT';
        ELSE
            SET v_change_category = 'SMALL_DEPOSIT';
        END IF;
    ELSEIF v_change_amount < 0 THEN
        IF v_change_amount <= -100000.00 THEN
            SET v_change_category = 'LARGE_WITHDRAWAL';
        ELSEIF v_change_amount <= -10000.00 THEN
            SET v_change_category = 'MEDIUM_WITHDRAWAL';
        ELSE
            SET v_change_category = 'SMALL_WITHDRAWAL';
        END IF;
    ELSE
        SET v_change_category = 'NO_CHANGE';
    END IF;

    -- Insert audit log entry
    INSERT INTO demo_audit_log (
        table_name, operation, account_id,
        old_balance, new_balance, change_amount,
        change_category, logged_by
    ) VALUES (
        'demo_accounts', 'UPDATE', new_row.account_id,
        old_row.balance, new_row.balance, v_change_amount,
        v_change_category, USER
    );

    -- Generate alerts based on thresholds using CASE
    CASE
        WHEN ABS(v_change_amount) >= 100000.00 THEN
            SET v_alert_severity = 1;
            SET v_alert_message = 'CRITICAL: Large balance change of ' ||
                CAST(v_change_amount AS VARCHAR(20)) || ' detected on account ' ||
                CAST(new_row.account_id AS VARCHAR(10));
        WHEN ABS(v_change_amount) >= 50000.00 THEN
            SET v_alert_severity = 2;
            SET v_alert_message = 'WARNING: Significant balance change detected on account ' ||
                CAST(new_row.account_id AS VARCHAR(10));
        WHEN new_row.balance < 1000.00 AND old_row.balance >= 1000.00 THEN
            SET v_alert_severity = 2;
            SET v_alert_message = 'WARNING: Account ' ||
                CAST(new_row.account_id AS VARCHAR(10)) || ' balance dropped below minimum threshold';
        ELSE
            SET v_alert_severity = 0;
            SET v_alert_message = NULL;
    END CASE;

    -- Insert alert if severity > 0
    IF v_alert_severity > 0 THEN
        INSERT INTO demo_alerts (alert_type, account_id, message, severity)
        VALUES (v_change_category, new_row.account_id, v_alert_message, v_alert_severity);
    END IF;

    -- Check for suspicious pattern: multiple large withdrawals
    IF v_change_category = 'LARGE_WITHDRAWAL' THEN
        SET v_threshold_pct = (ABS(v_change_amount) / old_row.balance) * 100;
        IF v_threshold_pct > 50.00 THEN
            INSERT INTO demo_alerts (alert_type, account_id, message, severity)
            VALUES ('SUSPICIOUS_ACTIVITY', new_row.account_id,
                'ALERT: Withdrawal exceeds 50% of previous balance', 1);
        END IF;
    END IF;
END;
--rollback DROP TRIGGER trg_account_balance_audit;

--changeset demo:s7-test-trigger-small-deposit runWith:bteq
--comment: Test trigger with small deposit
UPDATE demo_accounts SET balance = balance + 5000.00, last_modified = CURRENT_TIMESTAMP
WHERE account_id = 1001;
--rollback UPDATE demo_accounts SET balance = 50000.00 WHERE account_id = 1001;

--changeset demo:s7-test-trigger-large-withdrawal runWith:bteq
--comment: Test trigger with large withdrawal (should generate alerts)
UPDATE demo_accounts SET balance = balance - 120000.00, last_modified = CURRENT_TIMESTAMP
WHERE account_id = 1003;
--rollback UPDATE demo_accounts SET balance = 500000.00 WHERE account_id = 1003;

--changeset demo:s7-verify-audit-log runWith:bteq
--comment: Verify audit log entries were created
SELECT log_id, operation, account_id, old_balance, new_balance,
       change_amount, change_category, logged_at
FROM demo_audit_log
ORDER BY log_id;
--rollback SELECT 'No rollback needed' AS info;

--changeset demo:s7-verify-alerts runWith:bteq
--comment: Verify alerts were generated for large transactions
SELECT alert_id, alert_type, account_id, message, severity, created_at
FROM demo_alerts
ORDER BY alert_id;
--rollback SELECT 'No rollback needed' AS info;

--changeset demo:s7-cleanup runWith:bteq
--comment: Clean up demo objects
DROP TRIGGER trg_account_balance_audit;
DROP TABLE demo_alerts;
DROP TABLE demo_audit_log;
DROP TABLE demo_accounts;
--rollback SELECT 'No rollback for cleanup' AS info;
