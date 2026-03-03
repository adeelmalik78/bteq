#!/bin/bash
# Reset script for BTEQ demo environment
# Creates a fresh bteq_demo database and demo user for running demo scenarios

set -e  # Exit on error

# ============================================================================
# Configuration Loading
# ============================================================================
# Priority: 1) Environment variables, 2) demo/liquibase.properties, 3) Defaults

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROPS_FILE="${SCRIPT_DIR}/liquibase.properties"

# Function to extract property value from properties file
get_property() {
    local key="$1"
    local file="$2"
    grep "^${key}=" "$file" 2>/dev/null | cut -d'=' -f2-
}

# Function to parse JDBC URL and extract host
parse_jdbc_host() {
    local url="$1"
    # jdbc:teradata://HOST/... -> extract HOST
    echo "$url" | sed -n 's|jdbc:teradata://\([^/]*\)/.*|\1|p'
}

# Function to parse JDBC URL and extract DBS_PORT
parse_jdbc_port() {
    local url="$1"
    # Look for DBS_PORT=NNNN in the URL
    echo "$url" | sed -n 's|.*DBS_PORT=\([0-9]*\).*|\1|p'
}

# Load from demo properties file if it exists
if [ -f "$PROPS_FILE" ]; then
    echo "Loading configuration from: $PROPS_FILE"

    JDBC_URL=$(get_property "url" "$PROPS_FILE")
    PROPS_HOST=$(parse_jdbc_host "$JDBC_URL")
    PROPS_PORT=$(parse_jdbc_port "$JDBC_URL")
    PROPS_USER=$(get_property "username" "$PROPS_FILE")
    PROPS_PASSWORD=$(get_property "password" "$PROPS_FILE")
    PROPS_BTEQ_PATH=$(get_property "liquibase.bteq.path" "$PROPS_FILE")
else
    echo "No properties file found at: $PROPS_FILE"
    echo "Using environment variables or defaults"
fi

# Apply configuration with priority: env vars > properties file > defaults
TD_HOST="${TD_HOST:-${PROPS_HOST:-localhost}}"
TD_PORT="${TD_PORT:-${PROPS_PORT:-1025}}"
TD_USER="${TD_USER:-${PROPS_USER:-dbc}}"
TD_PASSWORD="${TD_PASSWORD:-${PROPS_PASSWORD:-dbc}}"
BTEQ_PATH="${BTEQ_PATH:-${PROPS_BTEQ_PATH:-/Library/Application Support/teradata/client/17.00/bin/bteq}}"

# Demo user credentials (will be created and used for demos)
DEMO_USER="${DEMO_USER:-demo_user}"
DEMO_PASSWORD="${DEMO_PASSWORD:-demo_pass}"
DB_NAME="bteq_demo"

echo "======================================"
echo "BTEQ Demo Database Reset"
echo "======================================"
echo "Host: ${TD_HOST}:${TD_PORT}"
echo "Admin User: ${TD_USER}"
echo "Demo User: ${DEMO_USER}"
echo "Database: ${DB_NAME}"
echo "======================================"

# ============================================================================
# Prerequisites Check
# ============================================================================
echo "Checking prerequisites..."

# Check if BTEQ is installed
if [ ! -x "$BTEQ_PATH" ]; then
    echo "ERROR: BTEQ executable not found at: $BTEQ_PATH"
    echo "Please install BTEQ or set BTEQ_PATH environment variable"
    exit 1
fi

echo "BTEQ found: $BTEQ_PATH"

# Test Teradata connection
echo "Testing Teradata connection..."
"$BTEQ_PATH" <<EOF
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
.IF ERRORCODE <> 0 THEN .QUIT 2
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Cannot connect to Teradata at ${TD_HOST}:${TD_PORT}"
    echo "Please check your connection details and credentials"
    exit 2
fi

echo "Connection successful"

# ============================================================================
# Drop existing database (idempotent)
# ============================================================================
echo "Dropping existing ${DB_NAME} database (if it exists)..."

"$BTEQ_PATH" <<EOF
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
DELETE DATABASE ${DB_NAME} ALL;
DROP DATABASE ${DB_NAME};
.IF ERRORCODE = 3802 THEN .GOTO skip_drop_error
.IF ERRORCODE <> 0 THEN .QUIT 3
.LABEL skip_drop_error
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to drop database ${DB_NAME}"
    exit 3
fi

# ============================================================================
# Drop existing demo user (idempotent)
# ============================================================================
echo "Dropping existing ${DEMO_USER} user (if exists)..."

"$BTEQ_PATH" <<EOF > /dev/null 2>&1
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
DROP USER ${DEMO_USER};
.IF ERRORCODE = 3802 THEN .GOTO skip_drop_user_error
.IF ERRORCODE <> 0 THEN .QUIT 3
.LABEL skip_drop_user_error
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to drop user ${DEMO_USER}"
    exit 3
fi

# ============================================================================
# Create demo user
# ============================================================================
echo "Creating demo user ${DEMO_USER}..."

"$BTEQ_PATH" <<EOF
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
CREATE USER ${DEMO_USER}
AS PERMANENT = 5e6,
   SPOOL = 5e6,
   PASSWORD = "${DEMO_PASSWORD}",
   DEFAULT DATABASE = ${DB_NAME};
.IF ERRORCODE <> 0 THEN .QUIT 3
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create user ${DEMO_USER}"
    exit 3
fi

# ============================================================================
# Create fresh database
# ============================================================================
echo "Creating fresh ${DB_NAME} database..."

"$BTEQ_PATH" <<EOF
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
CREATE DATABASE ${DB_NAME}
AS PERMANENT = 10e6,
   SPOOL = 10e6;
.IF ERRORCODE <> 0 THEN .QUIT 3
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create database ${DB_NAME}"
    exit 3
fi

# ============================================================================
# Grant permissions to demo user
# ============================================================================
echo "Granting permissions to ${DEMO_USER}..."

"$BTEQ_PATH" <<EOF
.LOGON ${TD_HOST}:${TD_PORT}/${TD_USER},${TD_PASSWORD}
GRANT ALL ON ${DB_NAME} TO ${DEMO_USER};
.IF ERRORCODE <> 0 THEN .QUIT 3
.LOGOFF
.QUIT 0
EOF

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to grant permissions to ${DEMO_USER}"
    exit 3
fi

# ============================================================================
# Success
# ============================================================================
echo "======================================"
echo "SUCCESS: ${DB_NAME} database ready"
echo "======================================"
echo ""
echo "Demo credentials:"
echo "  Host: ${TD_HOST}:${TD_PORT}"
echo "  Username: ${DEMO_USER}"
echo "  Password: ${DEMO_PASSWORD}"
echo "  Database: ${DB_NAME}"
echo ""
echo "You can now run any demo scenario:"
echo "  liquibase update --changelog-file=changelogs/scenario-1-macro-output.sql"
echo "  liquibase update --changelog-file=changelogs/scenario-2-query-results.sql"
echo "  liquibase update --changelog-file=changelogs/scenario-3-stored-procedures.sql"
echo "  liquibase update --changelog-file=changelogs/scenario-4-rollback.sql"
echo ""

exit 0
