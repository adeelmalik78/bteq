--liquibase formatted sql

--changeset demo:s7-maxerror-setup runWith:bteq
--comment: Create a valid table first so we can verify inserts did NOT run after the error
CREATE TABLE demo_maxerror_log (
    log_id INTEGER NOT NULL,
    message VARCHAR(200)
);

INSERT INTO demo_maxerror_log VALUES (1, 'Setup complete');

--rollback DROP TABLE demo_maxerror_log;

--changeset demo:s7-maxerror-fail runWith:bteq
--comment: Demonstrates BTEQ error handling - a syntax error stops execution before inserts run
--comment: The CREATE TABLE has a deliberate syntax error (missing column type).
--comment: BTEQ will report the error and exit, so the INSERT statements below never execute.
--comment: After running, query demo_maxerror_log to confirm only the setup row exists.
CREATE TABLE demo_maxerror_broken (
    broken_id INTEGER,
    broken_name,
    broken_date DATE
);

INSERT INTO demo_maxerror_log VALUES (2, 'This should NOT appear - ran after failed CREATE');
INSERT INTO demo_maxerror_log VALUES (3, 'This should NOT appear either');

--rollback DROP TABLE IF EXISTS demo_maxerror_broken;
--rollback DELETE FROM demo_maxerror_log WHERE log_id IN (2, 3);
