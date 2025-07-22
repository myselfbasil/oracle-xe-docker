#!/bin/bash

# Test SQL*Plus wrapper for ARM64
echo "Testing SQL*Plus wrapper for ARM64..."
echo ""

# Run the wrapper directly to test
echo "Testing common SQL*Plus commands:"
echo "=================================="

test_command() {
    local cmd="$1"
    echo ""
    echo "SQL> $cmd"
    echo "$cmd" | ./scripts/sqlplus-wrapper.sh 2>&1 | head -20
}

# Test various commands
test_command "SHOW USER;"
test_command "SELECT USER FROM DUAL;"
test_command "SELECT SYSDATE FROM DUAL;"
test_command "DESC demo_tutorial;"
test_command "SELECT * FROM demo_tutorial;"
test_command "SHOW TABLES;"

echo ""
echo "✅ Test complete!"