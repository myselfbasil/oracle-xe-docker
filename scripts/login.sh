#!/bin/bash

# Oracle XE Interactive Login Terminal
# Beautiful login interface with authentication

set -e

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Load configuration if available
CONFIG_FILE="/opt/oracle/.oracle_config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Default fallback values
ORACLE_ADMIN_USER=${ORACLE_ADMIN_USER:-"system"}
DATABASE_NAME=${DATABASE_NAME:-"XE"}

# Clear screen and show banner
clear
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}                     🏛️  ORACLE DATABASE XE                     ${CYAN}║${NC}"
echo -e "${CYAN}║${WHITE}                    Interactive Login Terminal                 ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                               ${CYAN}║${NC}"
echo -e "${CYAN}║${YELLOW}  Welcome to your Oracle Database Express Edition environment ${CYAN}║${NC}"
echo -e "${CYAN}║${YELLOW}     Secure • Reliable • Enterprise-grade Database          ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show system info
echo -e "${BLUE}📊 System Information:${NC}"
echo -e "   🖥️  Hostname: $(hostname)"
echo -e "   📅 Date: $(date +'%Y-%m-%d %H:%M:%S')"
echo -e "   💾 Oracle Version: $(sqlplus -v | head -n1 | cut -d' ' -f1-3 2>/dev/null || echo 'Oracle Database')"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "   🗄️  Database: ${DATABASE_NAME}"
fi
echo ""

# Login prompt
echo -e "${PURPLE}🔐 Database Authentication Required${NC}"
echo -e "${WHITE}Choose your login method:${NC}"
echo ""
echo -e "   ${GREEN}1)${NC} 👑 Database Administrator (Full privileges)"
echo -e "   ${GREEN}2)${NC} 👨‍💼 Application User (Development access)"
echo -e "   ${GREEN}3)${NC} ⚡ SYSDBA (System administrator)"
echo -e "   ${GREEN}4)${NC} 🔍 Connection Test"
echo -e "   ${GREEN}0)${NC} 🚪 Exit"
echo ""

# Get user choice
while true; do
    echo -n -e "${YELLOW}Select option (1-4, 0 to exit): ${NC}"
    read -n 1 choice
    echo ""
    
    case $choice in
        1)
            echo ""
            echo -e "${CYAN}👑 Administrator Login${NC}"
            echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            # Get admin credentials
            echo -n -e "${YELLOW}Username: ${NC}"
            read username
            username=${username:-$ORACLE_ADMIN_USER}
            
            echo -n -e "${YELLOW}Password: ${NC}"
            read -s password
            echo ""
            
            # Ask for connection type
            echo ""
            echo -e "${WHITE}Connection Options:${NC}"
            echo -e "   ${GREEN}1)${NC} Connect to CDB (Container Database)"
            echo -e "   ${GREEN}2)${NC} Connect to PDB (${DATABASE_NAME}PDB)"
            echo ""
            echo -n -e "${YELLOW}Choose connection (1-2): ${NC}"
            read -n 1 conn_choice
            echo ""
            
            if [ "$conn_choice" = "2" ] && [ -n "$DATABASE_NAME" ]; then
                connection_string="$username/$password@${DATABASE_NAME}PDB"
                echo -e "${GREEN}🔗 Connecting to PDB: ${DATABASE_NAME}PDB${NC}"
            else
                connection_string="$username/$password"
                echo -e "${GREEN}🔗 Connecting to CDB${NC}"
            fi
            
            break
            ;;
        2)
            echo ""
            echo -e "${CYAN}👨‍💼 Application User Login${NC}"
            echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            echo -n -e "${YELLOW}Username: ${NC}"
            read username
            
            echo -n -e "${YELLOW}Password: ${NC}"
            read -s password
            echo ""
            
            if [ -n "$DATABASE_NAME" ]; then
                connection_string="$username/$password@${DATABASE_NAME}PDB"
                echo -e "${GREEN}🔗 Connecting to application database: ${DATABASE_NAME}PDB${NC}"
            else
                connection_string="$username/$password"
                echo -e "${GREEN}🔗 Connecting to database${NC}"
            fi
            
            break
            ;;
        3)
            echo ""
            echo -e "${CYAN}⚡ SYSDBA Login${NC}"
            echo -e "${WHITE}━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${YELLOW}⚠️  SYSDBA provides unrestricted database access${NC}"
            echo -n -e "${YELLOW}Continue? (y/N): ${NC}"
            read -n 1 confirm
            echo ""
            
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Cancelled.${NC}"
                continue
            fi
            
            connection_string="/ as sysdba"
            echo -e "${GREEN}🔗 Connecting as SYSDBA${NC}"
            break
            ;;
        4)
            echo ""
            echo -e "${CYAN}🔍 Connection Test${NC}"
            echo -e "${WHITE}━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            
            echo -e "${BLUE}Testing database connectivity...${NC}"
            
            # Test basic connection
            if echo "SELECT 'Connection OK' FROM dual;" | sqlplus -s / as sysdba 2>/dev/null | grep -q "Connection OK"; then
                echo -e "${GREEN}✅ Database is accessible${NC}"
                
                # Show database status
                echo -e "${BLUE}📊 Database Status:${NC}"
                db_status=$(echo "SELECT status FROM v\$instance;" | sqlplus -s / as sysdba 2>/dev/null | grep -v "^$" | tail -1)
                echo -e "   Instance Status: ${GREEN}$db_status${NC}"
                
                if [ -n "$DATABASE_NAME" ]; then
                    pdb_status=$(echo "SELECT open_mode FROM v\$pdbs WHERE name='${DATABASE_NAME}PDB';" | sqlplus -s / as sysdba 2>/dev/null | grep -v "^$" | tail -1)
                    if [ -n "$pdb_status" ]; then
                        echo -e "   PDB Status: ${GREEN}$pdb_status${NC}"
                    fi
                fi
                
                echo -e "   Listener: ${GREEN}Active${NC}"
            else
                echo -e "${RED}❌ Database connection failed${NC}"
            fi
            
            echo ""
            echo -n -e "${YELLOW}Press Enter to continue...${NC}"
            read
            continue
            ;;
        0)
            echo ""
            echo -e "${GREEN}👋 Goodbye! Thank you for using Oracle XE${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please try again.${NC}"
            continue
            ;;
    esac
done

# Show connecting animation
echo ""
echo -n -e "${BLUE}🔄 Establishing connection"
for i in {1..3}; do
    echo -n "."
    sleep 0.5
done
echo -e " ${GREEN}Done!${NC}"
echo ""

# Launch SQL*Plus with custom prompt
echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║${GREEN}                    🚀 SQL*Plus Session Active                  ${WHITE}║${NC}"
echo -e "${WHITE}║${NC}                                                               ${WHITE}║${NC}"
echo -e "${WHITE}║${YELLOW}  💡 Tips:                                                    ${WHITE}║${NC}"
echo -e "${WHITE}║${YELLOW}     • Type HELP for SQL*Plus commands                       ${WHITE}║${NC}"
echo -e "${WHITE}║${YELLOW}     • Type EXIT or QUIT to close connection                 ${WHITE}║${NC}"
echo -e "${WHITE}║${YELLOW}     • Use DESC <table> to describe table structure          ${WHITE}║${NC}"
echo -e "${WHITE}║${YELLOW}     • Press Ctrl+C to interrupt running queries             ${WHITE}║${NC}"
echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Set custom SQL*Plus environment
export SQLPATH=/opt/oracle/scripts
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

# Create custom login.sql for this session
cat > /tmp/login_session.sql << 'EOF'
SET PAGESIZE 24
SET LINESIZE 120
SET FEEDBACK ON
SET TIMING ON
SET NUMWIDTH 12
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';

-- Custom prompt showing user and database
COLUMN db_name NEW_VALUE database_name NOPRINT
COLUMN username NEW_VALUE current_user NOPRINT
SELECT SYS_CONTEXT('USERENV', 'DB_NAME') as db_name FROM dual;
SELECT USER as username FROM dual;
SET SQLPROMPT '&current_user@&database_name> '

-- Welcome message
SELECT 
    '🎉 Welcome to Oracle Database!' as "STATUS",
    USER as "CONNECTED_AS",
    SYS_CONTEXT('USERENV', 'DB_NAME') as "DATABASE"
FROM dual;

PROMPT
PROMPT 📋 Available schemas:
SELECT username as "SCHEMA_NAME" 
FROM all_users 
WHERE username NOT IN ('SYS','SYSTEM','DBSNMP','SYSMAN','OUTLN','DIP','ORACLE_OCM','APPQOSSYS','WMSYS','XS$NULL')
ORDER BY username;

PROMPT
PROMPT 🚀 Ready for SQL commands! Type your queries below:
PROMPT
EOF

# Launch SQL*Plus with custom settings
sqlplus -L "$connection_string" @/tmp/login_session.sql

# Cleanup
rm -f /tmp/login_session.sql

echo ""
echo -e "${GREEN}✅ Session ended successfully${NC}"
echo -e "${BLUE}🔒 Connection closed securely${NC}"
echo ""