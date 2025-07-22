#!/bin/bash

# Oracle XE Health Check Script
# This script checks if Oracle Database XE is running and accessible

# Check if Oracle processes are running
if ! pgrep -f "oracle" > /dev/null 2>&1; then
    echo "Oracle processes not found"
    exit 1
fi

# Check if listener is running
if ! pgrep -f "tnslsnr" > /dev/null 2>&1; then
    echo "Oracle listener not running"
    exit 1
fi

# Check if we can connect to the database
if ! echo "SELECT 'HEALTH_OK' FROM dual;" | sqlplus -s / as sysdba | grep -q "HEALTH_OK"; then
    echo "Cannot connect to Oracle database"
    exit 1
fi

# Check if PDB is open (if using PDB)
PDB_STATUS=$(echo "SELECT open_mode FROM v\$pdbs WHERE name='XEPDB1';" | sqlplus -s / as sysdba | grep -o "READ WRITE\|MOUNTED\|READ ONLY")
if [[ "$PDB_STATUS" != "READ WRITE" ]]; then
    echo "PDB XEPDB1 is not in READ WRITE mode: $PDB_STATUS"
    exit 1
fi

echo "Oracle XE is healthy"
exit 0