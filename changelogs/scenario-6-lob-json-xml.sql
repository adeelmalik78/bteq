--liquibase formatted sql

--changeset demo:s6-create-lob-tables runWith:bteq
--comment: Create tables with CLOB, BLOB, JSON, and XML columns
CREATE TABLE demo_documents (
    doc_id INTEGER,
    doc_name VARCHAR(100),
    content CLOB
) NO PRIMARY INDEX;

CREATE TABLE demo_config (
    config_id INTEGER,
    config_name VARCHAR(100),
    settings JSON
) NO PRIMARY INDEX;

CREATE TABLE demo_attachments (
    attachment_id INTEGER,
    file_name VARCHAR(100),
    file_data BLOB
) NO PRIMARY INDEX;

CREATE TABLE demo_metadata (
    meta_id INTEGER,
    meta_name VARCHAR(100),
    meta_xml XML
) NO PRIMARY INDEX;
--rollback DROP TABLE demo_metadata;
--rollback DROP TABLE demo_attachments;
--rollback DROP TABLE demo_config;
--rollback DROP TABLE demo_documents;

--changeset demo:s6-insert-clob-data runWith:bteq
--comment: Insert CLOB document data
INSERT INTO demo_documents VALUES (1, 'README', 'This is a sample document stored as a CLOB. CLOBs can store large text content up to 2GB.');
INSERT INTO demo_documents VALUES (2, 'LICENSE', 'MIT License - Permission is hereby granted, free of charge, to any person obtaining a copy of this software...');
INSERT INTO demo_documents VALUES (3, 'CHANGELOG', 'Version 1.0.0 - Initial release with LOB support demonstration.');
--rollback DELETE FROM demo_documents WHERE doc_id IN (1, 2, 3);

--changeset demo:s6-insert-json-data runWith:bteq
--comment: Insert JSON configuration data using NEW JSON() constructor (Teradata 16.20+)
INSERT INTO demo_config VALUES (1, 'app_settings', NEW JSON('{"theme":"dark","language":"en","notifications":true}'));
INSERT INTO demo_config VALUES (2, 'user_prefs', NEW JSON('{"dashboard":{"widgets":["sales","inventory","alerts"]},"refresh_interval":30}'));
INSERT INTO demo_config VALUES (3, 'api_config', NEW JSON('{"endpoints":{"prod":"https://api.example.com","dev":"https://dev.api.example.com"},"timeout":5000}'));
--rollback DELETE FROM demo_config WHERE config_id IN (1, 2, 3);

--changeset demo:s6-insert-blob-data runWith:bteq
--comment: Insert BLOB data using hex literal format ('hexstring'XB)
INSERT INTO demo_attachments VALUES (1, 'hello.txt', '48656C6C6F20576F726C6421'XB);
INSERT INTO demo_attachments VALUES (2, 'binary.dat', 'DEADBEEF01020304'XB);
INSERT INTO demo_attachments VALUES (3, 'empty.bin', ''XB);
--rollback DELETE FROM demo_attachments WHERE attachment_id IN (1, 2, 3);

--changeset demo:s6-insert-xml-data runWith:bteq
--comment: Insert XML metadata
INSERT INTO demo_metadata VALUES (1, 'product_info', '<product><name>Widget</name><price>29.99</price><stock>150</stock></product>');
INSERT INTO demo_metadata VALUES (2, 'user_profile', '<user id="123"><name>John Doe</name><role>admin</role><active>true</active></user>');
INSERT INTO demo_metadata VALUES (3, 'config', '<config version="1.0"><setting name="debug">false</setting><setting name="log_level">INFO</setting></config>');
--rollback DELETE FROM demo_metadata WHERE meta_id IN (1, 2, 3);

--changeset demo:s6-query-verification runWith:bteq
--comment: Verify inserted data with SELECT queries
SELECT doc_id, doc_name, SUBSTR(content, 1, 50) AS content_preview FROM demo_documents ORDER BY doc_id;
SELECT config_id, config_name, CAST(settings AS VARCHAR(200)) AS settings_json FROM demo_config ORDER BY config_id;
SELECT attachment_id, file_name, BYTES(file_data) AS file_size FROM demo_attachments ORDER BY attachment_id;
SELECT meta_id, meta_name FROM demo_metadata ORDER BY meta_id;
--rollback SELECT 'No rollback needed for SELECT queries' AS info;

--changeset demo:s6-largedatamode runWith:bteq
--comment: Demonstrate .SET largedatamode ON for large CLOB handling
.SET largedatamode ON
INSERT INTO demo_documents VALUES (4, 'LARGE_DOC', 'Content loaded with largedatamode enabled - required for LOB data over 64KB');
--rollback DELETE FROM demo_documents WHERE doc_id = 4;

--changeset demo:s6-export-sample runWith:bteq
--comment: Export sample rows to a file using BTEQ EXPORT with SAMPLE clause
.EXPORT REPORT FILE=/tmp/bteq_lob_demo_export.txt
SELECT doc_id, doc_name, SUBSTR(content, 1, 50) AS preview FROM demo_documents SAMPLE 3;
.EXPORT RESET
--rollback SELECT 'no rollback needed for EXPORT' AS info;

--changeset demo:s6-cleanup runWith:bteq
--comment: Clean up demo objects
DROP TABLE demo_metadata;
DROP TABLE demo_attachments;
DROP TABLE demo_config;
DROP TABLE demo_documents;
--rollback CREATE TABLE demo_documents (doc_id INTEGER, doc_name VARCHAR(100), content CLOB) NO PRIMARY INDEX;
--rollback CREATE TABLE demo_config (config_id INTEGER, config_name VARCHAR(100), settings JSON) NO PRIMARY INDEX;
--rollback CREATE TABLE demo_attachments (attachment_id INTEGER, file_name VARCHAR(100), file_data BLOB) NO PRIMARY INDEX;
--rollback CREATE TABLE demo_metadata (meta_id INTEGER, meta_name VARCHAR(100), meta_xml XML) NO PRIMARY INDEX;
