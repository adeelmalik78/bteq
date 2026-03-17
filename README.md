# BTEQ Executor Demo

This directory contains demonstration materials for the Liquibase BTEQ Executor extension. The demos showcase key features that differentiate native BTEQ execution from standard JDBC connections.

## Overview

The BTEQ Executor enables Liquibase to capture complete output from Teradata operations that aren't fully supported through JDBC:

- **Macro Execution Output** - Capture complete result sets from `EXEC macro()` statements (PRIMARY feature not available via JDBC)
- **Query Result Streaming** - Unlimited row capture from SELECT queries and zero-row results from MINUS queries
- **Stored Procedure Output** - Capture result sets from CALL statements
- **Error Visibility** - Complete BTEQ error messages and diagnostic information
- **Native BTEQ Commands** - Support for `.IF`, `.LOGON`, `.QUIT` and other BTEQ-specific functionality

## Demo Contents

| File | Purpose | Status |
|------|---------|--------|
| [liquibase.properties](liquibase.properties) | Configuration template with all BTEQ executor properties | |
| [reset.sh](reset.sh) | Idempotent script to create fresh `bteq_demo` database | |
| [changelogs/scenario-1-macro-output.sql](changelogs/scenario-1-macro-output.sql) | Demonstrates macro execution output capture | Working |
| [changelogs/scenario-2-query-results.sql](changelogs/scenario-2-query-results.sql) | Demonstrates SELECT streaming and MINUS queries | Working |
| [changelogs/scenario-3-stored-procedures.sql](changelogs/scenario-3-stored-procedures.sql) | Demonstrates stored procedure creation, versioning, and `.COMPILE FILE` in rollback | Working |
| [changelogs/scenario-4-rollback.sql](changelogs/scenario-4-rollback.sql) | Demonstrates rollback functionality with tagged changesets | Working |
| [changelogs/scenario-5-audit-logging.sql](changelogs/scenario-5-audit-logging.sql) | Demonstrates audit-quality logging output (elapsed time, row counts, query results) | Working |
| [changelogs/scenario-6-lob-json-xml.sql](changelogs/scenario-6-lob-json-xml.sql) | Demonstrates CLOB, BLOB, JSON, and XML column support | Working |
| [changelogs/scenario-7-maxerror.sql](changelogs/scenario-7-maxerror.sql) | Demonstrates BTEQ error handling — exits on error, skips subsequent statements | Working |

Each scenario is **self-contained** and can be run independently in any order after running `reset.sh`.

### Known BTEQ Limitations

BTEQ parses semicolons as statement terminators at the client level. Objects with `BEGIN`/`END` blocks (stored procedures, functions, triggers) cannot be created inline. The executor automatically handles **stored procedures** by extracting them to `.spl` files and using `.COMPILE FILE`. Functions and triggers are **not supported** by `.COMPILE FILE` — use JDBC (remove `runWith:bteq`) for those object types.

## Prerequisites

Before running the demos, ensure you have:

- **BTEQ** - Teradata BTEQ command-line tool installed and in PATH
- **Teradata Admin Access** - A Teradata admin user (like `dbc`) to create demo database and user
- **Teradata JDBC Driver** - Download from [Teradata Downloads](https://downloads.teradata.com/download/connectivity/jdbc-driver)
  - Place the JAR file in a known location (e.g., `~/lib/terajdbc.jar`)
  - Add to Liquibase classpath (see below)
- **Java 17+** - Required for Liquibase 4.29.0
- **Maven** - To build the BTEQ executor extension
- **Liquibase 4.29.0+** - With the BTEQ executor extension jar

### Build the Extension

```bash
cd ..  # Return to project root
mvn clean package -DskipTests
```

### Configure Teradata JDBC Driver

**Option 1: Add to liquibase.properties** (recommended for demo):

Edit [liquibase.properties](liquibase.properties) and update the classpath to include the Teradata JDBC driver:

```properties
classpath=../target/bteq-executor-1.0.0-SNAPSHOT.jar:~/lib/terajdbc.jar
```

**Option 2: Add to Liquibase lib directory**:

```bash
cp ~/lib/terajdbc.jar $LIQUIBASE_HOME/lib/
```

**Option 3: Use command-line classpath**:

```bash
liquibase --classpath=../target/bteq-executor-1.0.0-SNAPSHOT.jar:~/lib/terajdbc.jar update
```

## Quick Start

Follow these two simple steps to run the demos:

### 1. Create Demo Environment

Run the reset script to automatically:
- Create a fresh `bteq_demo` database
- Create a `demo_user` with password `demo_pass`
- Grant necessary permissions
- Update [liquibase.properties](liquibase.properties) with the demo credentials

```bash
./reset.sh
```

**Environment variable overrides:**

You can customize connection details and credentials via environment variables:

```bash
# Customize Teradata connection (admin credentials to create demo environment)
TD_HOST=my-teradata-server TD_USER=myuser TD_PASSWORD=mypass ./reset.sh

# Customize demo user credentials (for running Liquibase)
DEMO_USER=my_demo_user DEMO_PASSWORD=my_demo_pass ./reset.sh

# Combine both
TD_HOST=my-server TD_USER=dbc TD_PASSWORD=dbc_pass \
DEMO_USER=demo_user DEMO_PASSWORD=demo_pass \
./reset.sh
```

**Default values:**
- Admin: `dbc/dbc` on `localhost:1025`
- Demo user: `demo_user/demo_pass`
- Database: `bteq_demo`

**Note**: You only need admin credentials (dbc) for the reset script. The demos will run as the `demo_user`, which has limited permissions on only the `bteq_demo` database.

### 2. Run Demo Scenarios

Each scenario can be run independently in any order (liquibase.properties is already configured):

```bash
# Scenario 1: Macro output capture
liquibase update --changelog-file=changelogs/scenario-1-macro-output.sql

# Scenario 2: Query result streaming
liquibase update --changelog-file=changelogs/scenario-2-query-results.sql

# Scenario 3: Stored procedure execution
liquibase update --changelog-file=changelogs/scenario-3-stored-procedures.sql

# Scenario 4: Rollback demonstration
liquibase update --changelog-file=changelogs/scenario-4-rollback.sql

# Scenario 5: Audit-quality logging
liquibase update --changelog-file=changelogs/scenario-5-audit-logging.sql

# Scenario 6: LOB, JSON, and XML support
liquibase update --changelog-file=changelogs/scenario-6-lob-json-xml.sql

# Scenario 7: BTEQ error handling (maxerror)
liquibase update --changelog-file=changelogs/scenario-7-maxerror.sql
```

## Demo Scenarios

### Scenario 1: Macro Execution Output Capture

**File**: [changelogs/scenario-1-macro-output.sql](changelogs/scenario-1-macro-output.sql)

**Demonstrates**: Capturing complete result sets from macro execution (PRIMARY feature)

**Key Feature**: JDBC cannot capture output from `EXEC macro()` statements. The BTEQ executor captures the complete result set.

**Run**:
```bash
liquibase update --changelog-file=changelogs/scenario-1-macro-output.sql
```

**Expected Output**:
```
[INFO] Executing changeset: demo:s1-exec-validation-macro
[INFO] Executing with the 'bteq' executor
[INFO] EXEC validate_deployment();
[INFO]
table_name     row_count
-------------  ---------
demo_products          4
demo_orders            0
```

**What It Does**:
1. Creates `demo_products` and `demo_orders` tables
2. Creates a validation macro that returns table row counts
3. Loads sample product data
4. Executes the macro and captures the complete result set
5. Cleans up all objects

### Scenario 2: Query Result Streaming

**File**: [changelogs/scenario-2-query-results.sql](changelogs/scenario-2-query-results.sql)

**Demonstrates**: SELECT query result capture and zero-row MINUS query handling

**Key Features**:
- Unlimited row streaming (no buffer limits)
- Zero-row result capture (critical for backup validation using MINUS queries)
- Multi-row aggregate results

**Run**:
```bash
liquibase update --changelog-file=changelogs/scenario-2-query-results.sql
```

**Expected Output**:
```
[INFO] Executing changeset: demo:s2-select-basic
[INFO] Executing with the 'bteq' executor
[INFO] SELECT item_id, item_name, quantity, category FROM demo_inventory ORDER BY item_id;
[INFO]
item_id  item_name          quantity  category
-------  -----------------  --------  ------------
      1  Laptop                   15  Electronics
      2  Mouse                    50  Electronics
      ...

[INFO] Executing changeset: demo:s2-select-minus-query
[INFO] Executing with the 'bteq' executor
[INFO] (Zero rows returned - backup validation pattern)
```

**What It Does**:
1. Creates `demo_inventory` table
2. Loads 10 sample inventory records
3. Executes basic SELECT with ORDER BY
4. Executes aggregate query with GROUP BY
5. Executes MINUS query (zero rows - demonstrates backup validation pattern)
6. Cleans up all objects

### Scenario 3: Stored Procedure Creation, Versioning, and Rollback

**File**: [changelogs/scenario-3-stored-procedures.sql](changelogs/scenario-3-stored-procedures.sql)

**Demonstrates**: Automatic `.COMPILE FILE` extraction for stored procedure DDL — both in forward deployment and rollback

**Key Feature**: The BTEQ executor automatically detects `CREATE/REPLACE PROCEDURE` DDL, extracts the procedure body into a temporary `.spl` file, and replaces the SQL with a `.COMPILE FILE` command. This happens transparently in both forward and rollback directions — changelog authors write standard procedure DDL and the executor handles the rest.

**Run**:
```bash
# Deploy all changesets (creates table, procedure v1, calls it, upgrades to v2, calls again)
liquibase update --changelog-file=changelogs/scenario-3-stored-procedures.sql

# Roll back the v2 upgrade — tests .COMPILE FILE in rollback (restores v1 procedure)
liquibase rollback-count 3 --changelog-file=changelogs/scenario-3-stored-procedures.sql
```

**Expected Output**:
```
[INFO] Executing changeset: demo:s3-call-procedure-1
[INFO] Executing with the 'bteq' executor
[INFO] CALL insert_order(101, 'Widget A', 5);
[INFO]
status           order_id  product_name  quantity
---------------  --------  ------------  --------
Order inserted        101  Widget A             5

[INFO] Executing changeset: demo:s3-call-procedure-2
[INFO] Executing with the 'bteq' executor
[INFO] CALL insert_order(102, 'Gadget X', 3);
[INFO]
status            order_id  product_name  quantity
----------------  --------  ------------  --------
Order confirmed        101  Widget A             5
Order confirmed        102  Gadget X             3
```

**What It Does**:
1. Creates `demo_orders` table
2. Creates `insert_order` stored procedure v1 (returns "Order inserted")
3. Calls v1 to insert first order — captures procedure output
4. Upgrades procedure to v2 (returns "Order confirmed") — rollback contains v1 DDL
5. Calls v2 to insert second order — captures updated output
6. Verifies all orders via SELECT query

### Scenario 4: Rollback Output Visibility

**File**: [changelogs/scenario-4-rollback.sql](changelogs/scenario-4-rollback.sql)

**Demonstrates**: BTEQ captures the same rich logging output during rollback as it does during forward deployment

**Key Features**:
- DDL rollback messages (`*** Table has been dropped.`, `*** Macro has been dropped.`)
- DML rollback row counts (`*** Delete completed. N rows removed.`, `*** Update completed. N rows changed.`)
- Elapsed time per rollback statement
- Contrast with JDBC, which only reports "Changeset rolled back successfully"

**Run**:
```bash
# Step 1: Deploy all changesets
liquibase update --changelog-file=changelogs/scenario-4-rollback.sql

# Step 2: Roll back last 3 changesets — watch the BTEQ output
liquibase rollback-count 3 --changelog-file=changelogs/scenario-4-rollback.sql

# Step 3: Re-apply and roll back everything
liquibase update --changelog-file=changelogs/scenario-4-rollback.sql
liquibase rollback-count 6 --changelog-file=changelogs/scenario-4-rollback.sql
```

**What It Does**:
1. Creates `demo_tracking` table (DDL)
2. Inserts 5 tracking event rows (DML)
3. Alters the table to add a column (DDL)
4. Updates rows with category values (DML)
5. Creates a summary table with aggregated data (DDL + DML)
6. Creates a reporting macro (DDL)

Each rollback exercises a different BTEQ output message type — DROP TABLE, DROP MACRO, DELETE, UPDATE, ALTER — proving that rollback output gets the same audit-quality logging as forward deployment.

**Note**: Unlike other scenarios, this one does NOT auto-cleanup so you can experiment with rollback. Run `./reset.sh` when done to clean up.

### Scenario 5: Audit-Quality Logging Output

**File**: [changelogs/scenario-5-audit-logging.sql](changelogs/scenario-5-audit-logging.sql)

**Demonstrates**: Rich logging output for audit/compliance requirements

**Key Features**:
- Elapsed time per statement (`*** Total elapsed time was N seconds.`)
- Row counts for DML (`*** Insert completed. 5 rows added.`)
- DDL success messages (`*** Table has been created.`)
- Query results with column headers and data

**Run**:
```bash
liquibase update --changelog-file=changelogs/scenario-5-audit-logging.sql
```

**Expected Output**:
```
*** Table has been created.
*** Total elapsed time was 1 second.

*** Insert completed. 5 rows added.
*** Total elapsed time was 1 second.

*** Update completed. 4 rows changed.
*** Total elapsed time was 1 second.

*** Query completed. 5 rows found. 4 columns returned.
Operation              Records Processed    Status         Date
--------------------  -------------------  ------------  ----------
CUSTOMER_LOAD                      150000  VERIFIED      2026-01-19
...

*** Table has been dropped.
```

**What It Does**:
1. Creates `demo_audit` table with audit columns
2. Inserts 5 audit records showing various operations
3. Updates records based on criteria (shows row counts)
4. Runs SELECT queries (shows results with headers and data)
5. Runs aggregate query with GROUP BY
6. Cleans up by dropping the table

**Customer Value**: This scenario proves the BTEQ executor captures all the logging detail that DBAs require for audit trails - execution time, success/failure status, row counts, and actual query data.

### Scenario 6: LOB, JSON, and XML Column Support

**File**: [changelogs/scenario-6-lob-json-xml.sql](changelogs/scenario-6-lob-json-xml.sql)

**Demonstrates**: Working with Teradata LOB types (CLOB, BLOB, JSON, XML) through BTEQ

**Key Features**:
- CLOB for large text documents
- JSON with NEW JSON() constructor (Teradata 16.20+)
- BLOB with hex literal format (`'hexstring'XB`)
- XML with string literal auto-parsing

**Run**:
```bash
liquibase update --changelog-file=changelogs/scenario-6-lob-json-xml.sql
```

**Expected Output**:
```
*** Table has been created.
*** Insert completed. 3 rows added.
...
doc_id  doc_name   content_preview
------  ---------  ------------------------------------------------
     1  README     This is a sample document stored as a CLOB...
     2  LICENSE    MIT License - Permission is hereby granted...
     3  CHANGELOG  Version 1.0.0 - Initial release with LOB...
```

**What It Does**:
1. Creates four tables with different LOB column types (CLOB, JSON, BLOB, XML)
2. Inserts sample documents into CLOB table
3. Inserts JSON configuration data using NEW JSON() constructor
4. Inserts binary data using BLOB hex literal format
5. Inserts XML metadata
6. Runs verification queries showing data was stored correctly
7. Cleans up all objects

**Teradata Syntax Notes**:
- **JSON**: Use `NEW JSON('{"key":"value"}')` constructor (Teradata 16.20+)
- **BLOB**: Use `'hexstring'XB` format (e.g., `'48656C6C6F'XB` = "Hello")
- **XML**: String literals are auto-parsed; query with `XMLSERIALIZE()` not `CAST()`
- **Size limit**: Inline string literals limited to 31,000 characters. For larger LOBs, use JDBC or external files.

### Scenario 7: BTEQ Error Handling (MAXERROR)

**File**: [changelogs/scenario-7-maxerror.sql](changelogs/scenario-7-maxerror.sql)

**Demonstrates**: BTEQ exits immediately on error, preventing subsequent statements from executing

**Key Feature**: The BTEQ executor injects `.SET MAXERROR 1` at the top of every generated script. When a SQL statement fails, BTEQ exits with return code 8 instead of continuing to the next statement. This is critical for safety — a failed CREATE TABLE should not be followed by INSERTs into a non-existent table.

**Run**:
```bash
liquibase update --changelog-file=changelogs/scenario-7-maxerror.sql
```

**Expected Output**:
```
*** Failure 3739 The user must give a data type for broken_name.
                Statement# 1, Info =100

 *** Exiting BTEQ...
 *** RC (return code) = 8
```

**What It Does**:
1. Creates `demo_maxerror_log` table and inserts a setup row (changeset 1 — succeeds)
2. Attempts to CREATE TABLE with a deliberate syntax error — missing data type on `broken_name` column (changeset 2 — fails)
3. BTEQ reports the error and exits immediately — the two INSERT statements after the failed CREATE never execute
4. Liquibase reports the failure with the complete BTEQ error output

**Customer Value**: This proves that the BTEQ executor fails safely. A syntax error or DDL failure stops execution immediately, preventing data corruption from subsequent statements that depend on the failed operation. The complete error message (Teradata error code 3739, statement number, column name) is captured in the Liquibase output for diagnosis.

**Note**: This scenario intentionally fails on changeset 2. Run `./reset.sh` to clean up before re-running.

## Configuration Options

All BTEQ executor properties use the `liquibase.bteq.*` namespace:

| Property | Default | Description |
|----------|---------|-------------|
| `liquibase.bteq.path` | `bteq` (from PATH) | Path to BTEQ executable |
| `liquibase.bteq.timeout` | `-1` (disabled) | Execution timeout in seconds |
| `liquibase.bteq.keep.temp` | `false` | Retain temp scripts for debugging (credentials redacted) |
| `liquibase.bteq.keep.temp.path` | System temp dir | Directory for retained scripts |
| `liquibase.bteq.keep.temp.name` | `bteq-debug` | Filename prefix for retained scripts |
| `liquibase.bteq.args` | (none) | Additional BTEQ command-line arguments |
| `liquibase.bteq.charset` | From JDBC URL | Character set override |
| `liquibase.bteq.logfile` | (none) | BTEQ session log file path |

Configure these in [liquibase.properties](liquibase.properties), via environment variables (`LIQUIBASE_BTEQ_PATH`), or command-line arguments.

## Troubleshooting

### BTEQ not found

**Error**: `ERROR: BTEQ executable not found in PATH`

**Solution**: Install BTEQ and ensure it's in your PATH, or configure `liquibase.bteq.path` in liquibase.properties:
```properties
liquibase.bteq.path=/opt/teradata/client/bin/bteq
```

### Connection errors

**Error**: `ERROR: Cannot connect to Teradata at localhost:1025`

**Solution**: Verify your connection details in liquibase.properties:
- Check hostname/IP address
- Verify DBS_PORT (default Teradata port is 1025)
- Test connectivity: `telnet hostname 1025`

### Authentication failures

**Error**: `*** Logon Failed ***`

**Solutions**:
- Verify username and password are correct
- Check user has necessary permissions (CREATE DATABASE, CREATE TABLE, etc.)

### Database doesn't exist

**Error**: Database `bteq_demo` doesn't exist when running scenarios

**Solution**: Run `./reset.sh` first to create the database and demo user. The scenarios expect an empty `bteq_demo` database with a properly configured demo user.

### Changesets already executed

**Error**: Changesets have already been executed

**Solutions**:
- Run `./reset.sh` to create a fresh database (drops and recreates `bteq_demo`)
- Or manually clear the DATABASECHANGELOG table:
  ```bash
  ./reset.sh  # Simplest approach
  ```

### Permissions errors

**Error**: User lacks necessary permissions

**Solution**: The demo user created by `reset.sh` should have all necessary permissions on the `bteq_demo` database. If you're using custom credentials, ensure the user has:
- CREATE TABLE
- CREATE MACRO
- CREATE PROCEDURE
- DROP TABLE/MACRO/PROCEDURE
- SELECT/INSERT/UPDATE/DELETE on tables in `bteq_demo`

The admin user (default: `dbc`) needs these permissions to run `reset.sh`:
- CREATE DATABASE
- CREATE USER
- GRANT privileges

## JDBC vs BTEQ Comparison

| Feature | JDBC Executor | BTEQ Executor |
|---------|---------------|---------------|
| Macro output capture | ❌ No | ✅ Yes |
| SELECT result capture | ⚠️ Limited (buffers) | ✅ Full (unlimited streaming) |
| MINUS query zero rows | ⚠️ May not capture | ✅ Captures |
| Stored procedure output | ⚠️ Limited | ✅ Full |
| BTEQ commands (`.IF`, `.QUIT`) | ❌ No | ✅ Yes |
| Error diagnostics | ⚠️ JDBC errors only | ✅ Complete BTEQ error messages |
| Authentication methods | ⚠️ Limited | ✅ TD2 (LDAP/Kerberos planned) |

**When to use BTEQ executor**:
- Macro execution (EXEC statements) - **REQUIRED** for output capture
- Backup validation using MINUS queries with zero rows
- Complex stored procedure result sets
- When you need complete BTEQ error messages
- Scripts with native BTEQ commands

**When JDBC is sufficient**:
- Simple DDL (CREATE, ALTER, DROP)
- Simple DML (INSERT, UPDATE, DELETE)
- When you don't need to capture query output

## Next Steps

### Customize for Your Environment

The `reset.sh` script automatically configures liquibase.properties with demo credentials. To customize:

1. **Use environment variables** with reset.sh (recommended):
   ```bash
   TD_HOST=my-server DEMO_USER=my_user DEMO_PASSWORD=my_pass ./reset.sh
   ```

2. **Manually edit liquibase.properties** after running reset.sh:
   - **Connection settings**: Update `url` for your Teradata server
   - **Debug mode**: Set `liquibase.bteq.keep.temp=true` to inspect generated scripts
   - **Timeout**: Set `liquibase.bteq.timeout=300` (5 minutes) if needed

### Create Your Own Scenarios

Use the demo scenarios as templates:

1. Copy a scenario file: `cp changelogs/scenario-1-macro-output.sql changelogs/my-scenario.sql`
2. Modify changesets for your use case
3. Keep the self-contained pattern (CREATE → USE → DROP)
4. Use unique changeset IDs (prefix with your scenario code)
5. Run independently: `liquibase update --changelog-file=changelogs/my-scenario.sql`

### Integration with CI/CD

The BTEQ executor works seamlessly in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Deploy to Teradata
  env:
    # Map secrets to Liquibase environment variables
    LIQUIBASE_COMMAND_URL: "jdbc:teradata://${{ secrets.TD_HOST }}/DATABASE=mydb,DBS_PORT=1025"
    LIQUIBASE_COMMAND_USERNAME: ${{ secrets.TD_USER }}
    LIQUIBASE_COMMAND_PASSWORD: ${{ secrets.TD_PASSWORD }}
  run: |
    liquibase update --changelog-file=db/changelog-master.sql
```

### Learn More

- [BTEQ Executor Documentation](../docs/README.md) - Complete reference
- [BTEQ Commands Reference](../docs/bteq/COMMANDS.md) - Native BTEQ command syntax
- [Error Handling Guide](../docs/bteq/ERROR_HANDLING.md) - Error codes and troubleshooting
- [Java Style Guide](../docs/JAVA_STYLE_GUIDE.md) - For contributing to the extension
