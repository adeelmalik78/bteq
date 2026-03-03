# Customer Demo Guide: BTEQ Native Executor Logging

**Date**: 2026-01-19
**Audience**: Customer (Ram's team - Wells Fargo Teradata DBAs)
**Purpose**: Demonstrate that BTEQ executor captures the rich logging output required for audit/compliance

---

## Executive Summary

The customer provided log files showing what they need from BTEQ execution:
- Elapsed time for each statement
- Row counts for DML operations (INSERT/UPDATE/DELETE)
- Success messages for DDL operations (CREATE/DROP/ALTER)
- Query results with column headers and data
- Warning messages

**Good news**: The BTEQ executor already captures all of this. We just need to show them.

---

## Demo Materials

### 1. Demo Changelog: `scenario-5-audit-logging.sql`

Located at: [changelogs/scenario-5-audit-logging.sql](changelogs/scenario-5-audit-logging.sql)

This single changeset demonstrates all the logging features they showed in their log files:

**What it does:**
1. Creates a test table → Shows `*** Table has been created.`
2. Inserts 5 rows → Shows `*** Insert completed. 5 rows added.`
3. Updates multiple rows → Shows `*** Update completed. N rows changed.`
4. Runs SELECT queries → Shows column headers, data, and row counts
5. Drops the test table → Shows `*** Table has been dropped.`
6. Each operation shows → `*** Total elapsed time was N seconds.`

**Key feature:** Uses `runWith:bteq` and `splitStatements:false` so it runs through the BTEQ executor.

### 2. Main Demo README

See [README.md](README.md) for the complete demo guide covering all 5 scenarios, including:
- Prerequisites and setup
- How to run each scenario
- Expected output
- Configuration options
- Troubleshooting

---

## Running the Demo

### Prerequisites

1. **Teradata Access:**
   - Server accessible
   - DBA_SANDBOX database available
   - Valid credentials

2. **BTEQ Installed:**
   - Teradata Tools and Utilities (TTU) installed
   - `bteq` command in PATH or configured via `liquibase.bteq.path`

3. **Configuration File:**
   Create `src/test/resources/liquibase.test.local.properties`:
   ```properties
   url=jdbc:teradata://your-server/DATABASE=dba_sandbox
   username=your-user
   password=your-password
   liquibase.bteq.path=/opt/teradata/client/BTEQ_01.00.00.00/bin/bteq
   ```

### Execute Demo

From the `demo/` directory:
```bash
cd /Users/recampbell/workspace/bteq-executor/demo
liquibase update --changelog-file=changelogs/scenario-5-audit-logging.sql
```

Or with explicit credentials:
```bash
liquibase update \
  --changelog-file=changelogs/scenario-5-audit-logging.sql \
  --url=jdbc:teradata://your-server/DATABASE=bteq_demo \
  --username=demo_user \
  --password=demo_pass
```

### Expected Output

The logs will show:

```
[INFO] Executing with the 'bteq' executor
[INFO] BTEQ 17.10.00.09 (64-bit) ...

[INFO] *** Table has been created.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] *** Insert completed. 5 rows added.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] *** Update completed. 4 rows changed.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] *** Query completed. 5 rows found. 4 columns returned.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] Operation              Records Processed    Status         Date
[INFO] --------------------  -------------------  ------------  ----------
[INFO] CUSTOMER_LOAD                      150000  VERIFIED      2026-01-19
[INFO] ORDER_PROCESSING                    45000  VERIFIED      2026-01-19
[INFO] INVENTORY_UPDATE                     8500  SUCCESS       2026-01-19
[INFO] PAYMENT_VALIDATION                  12000  VERIFIED      2026-01-19
[INFO] SHIPMENT_TRACKING                    6200  SUCCESS       2026-01-19
[INFO]
[INFO] *** Query completed. 2 rows found. 3 columns returned.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] Status         Operation Count    Total Records
[INFO] ------------  ----------------  ---------------
[INFO] SUCCESS                      2           14700
[INFO] VERIFIED                     3          207000
[INFO]
[INFO] *** Table has been dropped.
[INFO] *** Total elapsed time was 1 second.
[INFO]
[INFO] BTEQ execution completed successfully
```

---

## What This Proves

### Comparison: Customer Requirements vs Demo Output

| Customer Requirement | Demo Shows | Status |
|---------------------|------------|--------|
| **Execution Time/Elapsed Time** | `*** Total elapsed time was N seconds.` after each statement | ✅ Captured |
| **Status of Execution** | `*** Table has been created.`<br>`*** Insert completed.`<br>etc. | ✅ Captured |
| **Outcome of DML/DDL** | `5 rows added`<br>`4 rows changed`<br>`Table has been dropped` | ✅ Captured |
| **Rows with Columns and Data** | Full query results with headers and data | ✅ Captured |

### Key Differentiators: BTEQ vs JDBC

**JDBC Executor (what they use now without BTEQ):**
```
[INFO] Changeset ran successfully in 5ms
```

**BTEQ Executor (what they get with our feature):**
- ✅ Elapsed time per SQL statement (not just changeset)
- ✅ Row counts for DML operations
- ✅ Success/failure messages for DDL
- ✅ Actual query results in logs
- ✅ Warning messages
- ✅ Macro execution output (not shown in demo but supported)

---

## Next Steps

### For Customer Demo

1. **Schedule demo call** with Ram's team
2. **Screen share** running the demo script
3. **Walk through the output** highlighting each required feature
4. **Compare side-by-side** with their existing BTEQ logs
5. **Show them** how to add `runWith:bteq` to their changesets

### For Customer Adoption

After they see the demo and approve:

1. **Document their changesets** - identify which ones need `runWith:bteq`
2. **Add the attribute** - `runWith:bteq splitStatements:false`
3. **Configure BTEQ path** - in their Liquibase properties
4. **Run a pilot** - one deployment with BTEQ executor
5. **Validate logs** - confirm they see all required output
6. **Roll out** - to all Teradata deployments

### Follow-up Items

If they want additional tests to verify specific BTEQ messages:
- Add test for elapsed time messages
- Add test for row count messages
- Add test for DDL success messages
- Add test for warning messages

See [analysis-customer-logging-requirements.md](analysis-customer-logging-requirements.md) for specific test code.

---

## Contact & Support

- Implementation: Ryan Campbell
- Customer: Ram (Wells Fargo - 26 Teradata DBAs)
- Target Delivery: January 15, 2026
- Customer ARR: ~$1M
- Strategic Value: Enterprise standard adoption, retire homegrown tooling

---

## Appendix: Quick Reference

### Demo Files
- Demo changelog: `demo/changelogs/scenario-5-audit-logging.sql`
- Main demo guide: `demo/README.md`
- This guide: `demo/customer-demo-guide.md`
- Analysis: `specs/001-bteq-native-executor/analysis-customer-logging-requirements.md`

### Commands
```bash
# Run the audit logging demo (from demo/ directory)
cd demo
liquibase update --changelog-file=changelogs/scenario-5-audit-logging.sql

# Check BTEQ version
bteq < /dev/null

# Run tests
mvn test -Pintegration-tests-only
```
