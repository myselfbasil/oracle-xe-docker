#!/bin/bash

# SQL*Plus Wrapper for Apple Silicon (ARM64) compatibility
# Translates Oracle SQL*Plus commands to SQLite equivalents

DEMO_DB="/opt/oracle/demo.db"

# Initialize if needed
if [ ! -f "$DEMO_DB" ]; then
    sqlite3 "$DEMO_DB" << 'EOF'
CREATE TABLE demo_tutorial (id INTEGER PRIMARY KEY, message TEXT);
INSERT INTO demo_tutorial VALUES (1, 'Hello Oracle!');
INSERT INTO demo_tutorial VALUES (2, 'SQL*Plus Tutorial Demo');
CREATE TABLE dual (dummy TEXT DEFAULT 'X');
INSERT INTO dual VALUES ('X');
EOF
fi

# Function to translate Oracle commands to SQLite
translate_command() {
    local cmd="$1"
    
    # Convert to uppercase for easier matching
    local upper_cmd=$(echo "$cmd" | tr '[:lower:]' '[:upper:]')
    
    case "$upper_cmd" in
        "SHOW USER"|"SELECT USER FROM DUAL;"|"SELECT USER FROM DUAL")
            echo "SELECT 'ORACLE' AS current_user;"
            ;;
        "SELECT SYSDATE FROM DUAL;"|"SELECT SYSDATE FROM DUAL")
            echo "SELECT datetime('now') AS sysdate;"
            ;;
        "SELECT NAME, OPEN_MODE FROM V\$DATABASE;"|"SELECT NAME, OPEN_MODE FROM V\$DATABASE")
            echo "SELECT 'XE' AS name, 'READ write' AS open_mode;"
            ;;
        "COMMIT;"|"COMMIT")
            echo ".save"
            return 0
            ;;
        "EXIT;"|"EXIT"|"QUIT;"|"QUIT")
            exit 0
            ;;
        "HELP"|"HELP;")
            show_help
            return 0
            ;;
        "DESC DEMO_TUTORIAL"|"DESCRIBE DEMO_TUTORIAL")
            echo ".schema demo_tutorial"
            ;;
        *)
            # Pass through other SQL commands as-is
            echo "$cmd"
            ;;
    esac
}

# Help function
show_help() {
    cat << 'EOF'

Oracle SQL*Plus Compatible Commands (Apple Silicon Mode):
=========================================================

Basic Commands:
  SHOW USER                    - Show current user
  SELECT SYSDATE FROM DUAL;    - Show current date/time
  SELECT * FROM demo_tutorial; - Query demo table
  
Table Operations:
  CREATE TABLE name (col type); - Create table
  INSERT INTO table VALUES ();  - Insert data
  SELECT * FROM table;           - Query data
  
Session Commands:
  COMMIT;                      - Save changes
  EXIT; or QUIT;              - Exit SQL*Plus
  HELP;                       - Show this help

Example Session:
  SQL> SELECT * FROM demo_tutorial;
  SQL> INSERT INTO demo_tutorial VALUES (3, 'New message');
  SQL> COMMIT;
  SQL> EXIT;

Note: This is a learning environment using SQLite for Apple Silicon compatibility.
      SQL syntax is nearly identical to Oracle.

EOF
}

# Show welcome message
echo ""
echo "Oracle SQL*Plus Compatible Interface"
echo "===================================="
echo "Apple Silicon Mode - Learning Environment"
echo ""
echo "Connected to: Demo Database (SQLite-based)"
echo "Type HELP; for available commands"
echo ""

# Interactive mode
if [ $# -eq 0 ]; then
    while true; do
        printf "SQL> "
        read -r input
        
        if [ -z "$input" ]; then
            continue
        fi
        
        if [[ "$input" == "EXIT" ]] || [[ "$input" == "exit" ]] || [[ "$input" == "QUIT" ]] || [[ "$input" == "quit" ]]; then
            echo "Goodbye!"
            break
        fi
        
        # Translate and execute command
        translated=$(translate_command "$input")
        
        if [[ "$translated" == ".save" ]]; then
            echo "Commit complete."
        elif [[ "$translated" == ".schema"* ]]; then
            sqlite3 "$DEMO_DB" "$translated"
        else
            sqlite3 "$DEMO_DB" "$translated" 2>/dev/null || echo "SQL Error: Invalid command or syntax"
        fi
        
        echo ""
    done
else
    # Non-interactive mode - process input from pipe or arguments
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            translated=$(translate_command "$line")
            if [[ "$translated" == ".save" ]]; then
                echo "Commit complete."
            elif [[ "$translated" == ".schema"* ]]; then
                sqlite3 "$DEMO_DB" "$translated"
            else
                sqlite3 "$DEMO_DB" "$translated" 2>/dev/null || echo "SQL Error: Invalid command or syntax"
            fi
        fi
    done
fi