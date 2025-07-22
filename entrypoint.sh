#!/bin/bash

# Oracle XE Docker Entrypoint Script
# Handles database initialization and startup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Banner
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║        Oracle Database XE 21c Setup          ║"
echo "║           Interactive Configuration           ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check if this is the first run
FIRST_RUN=false
if [ ! -f /opt/oracle/oradata/.initialized ]; then
    FIRST_RUN=true
fi

if [ "$FIRST_RUN" = "true" ]; then
    print_info "First time setup detected"
    echo ""
    
    # Load custom configuration if available
    CONFIG_FILE="/opt/oracle/.oracle_config"
    if [ -f "$CONFIG_FILE" ]; then
        print_info "Loading custom configuration..."
        source "$CONFIG_FILE" 2>/dev/null || true
        print_success "Configuration loaded"
    else
        print_warning "No configuration file found, using environment variables"
    fi
    
    # Set default values if not provided
    ORACLE_ADMIN_USER=${ORACLE_ADMIN_USER:-"system"}
    ORACLE_APP_USER=${ORACLE_APP_USER:-"appuser"}  
    DATABASE_NAME=${DATABASE_NAME:-"XE"}
    
    print_info "Database Configuration"
    echo "=============================================="
    echo ""
    echo "🔧 Configuration Details:"
    echo "   👤 Admin User: $ORACLE_ADMIN_USER"
    echo "   👨‍💼 App User: $ORACLE_APP_USER"
    echo "   🗄️  Database: $DATABASE_NAME"
    echo "   🔗 PDB: ${ORACLE_PDB:-${DATABASE_NAME}PDB}"
    echo ""
    
    # Character set configuration
    print_info "Database Character Set Configuration"
    echo "=============================================="
    echo ""
    echo "Available character sets:"
    echo "  1) AL32UTF8 (Default - Recommended for most applications)"
    echo "  2) UTF8     (Legacy UTF-8 support)"
    echo "  3) WE8ISO8859P1 (Western European)"
    echo "  4) US7ASCII (Basic ASCII)"
    echo ""
    
    if [ -z "$ORACLE_CHARACTERSET" ]; then
        echo -n "Choose character set (1-4, default: 1): "
        read CHARSET_CHOICE
        
        case "$CHARSET_CHOICE" in
            1|"") ORACLE_CHARACTERSET="AL32UTF8" ;;
            2) ORACLE_CHARACTERSET="UTF8" ;;
            3) ORACLE_CHARACTERSET="WE8ISO8859P1" ;;
            4) ORACLE_CHARACTERSET="US7ASCII" ;;
            *) 
                print_warning "Invalid choice, using AL32UTF8"
                ORACLE_CHARACTERSET="AL32UTF8"
                ;;
        esac
    fi
    
    export ORACLE_CHARACTERSET
    print_success "Character set: $ORACLE_CHARACTERSET"
    echo ""
    
    # Memory configuration
    print_info "Memory Configuration"
    echo "=============================================="
    echo ""
    
    # Get available memory
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
    
    echo "Available system memory: ${TOTAL_MEM_GB}GB"
    
    if [ $TOTAL_MEM_GB -lt 4 ]; then
        print_warning "Less than 4GB RAM available. Oracle XE may perform poorly."
        print_info "Consider increasing Docker memory allocation"
    else
        print_success "Sufficient memory available"
    fi
    echo ""
    
    print_info "Starting Oracle Database XE configuration..."
    echo ""
fi

# Set default values if not provided
export ORACLE_SID=${ORACLE_SID:-XE}
export ORACLE_PDB=${ORACLE_PDB:-XEPDB1}
export ORACLE_CHARACTERSET=${ORACLE_CHARACTERSET:-AL32UTF8}
export ORACLE_EDITION=${ORACLE_EDITION:-xe}

# Oracle environment setup
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib

# Ensure Oracle user owns the data directory
chown -R oracle:oinstall /opt/oracle/oradata

# Function to check if database is running
check_database() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if su - oracle -c "echo 'SELECT 1 FROM dual;' | sqlplus -s / as sysdba" | grep -q "^1$"; then
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    return 1
}

# Switch to oracle user for database operations
su - oracle << 'ORACLE_SCRIPT'

# Source Oracle environment
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export ORACLE_SID=XE
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib

echo ""
echo "🔧 Starting Oracle Database configuration as oracle user..."
echo ""

# Check if database is already configured
if [ ! -f /opt/oracle/oradata/.initialized ]; then
    echo "📋 Configuring Oracle Database XE for first time..."
    
    # Run Oracle XE configuration
    /etc/init.d/oracle-xe-21c configure << EOF
$ORACLE_PWD
$ORACLE_PWD
EOF

    if [ $? -eq 0 ]; then
        echo "✅ Oracle XE configured successfully"
        
        # Connect and set up custom PDB and users
        sqlplus / as sysdba << SQL_SETUP
-- Ensure CDB is open
ALTER DATABASE OPEN;

-- Create custom PDB if it doesn't exist
DECLARE
    v_count NUMBER;
    v_pdb_name VARCHAR2(30) := '${ORACLE_PDB:-${DATABASE_NAME}PDB}';
BEGIN
    SELECT COUNT(*) INTO v_count FROM v\$pdbs WHERE name = v_pdb_name;
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE PLUGGABLE DATABASE ' || v_pdb_name || ' ADMIN USER pdbadmin IDENTIFIED BY "${ORACLE_ADMIN_PWD}"';
    END IF;
END;
/

-- Open custom PDB
ALTER PLUGGABLE DATABASE ${ORACLE_PDB:-${DATABASE_NAME}PDB} OPEN;

-- Save PDB state
ALTER PLUGGABLE DATABASE ${ORACLE_PDB:-${DATABASE_NAME}PDB} SAVE STATE;

-- Create custom admin user
CREATE USER ${ORACLE_ADMIN_USER} IDENTIFIED BY "${ORACLE_ADMIN_PWD}";
GRANT DBA TO ${ORACLE_ADMIN_USER};
GRANT SYSDBA TO ${ORACLE_ADMIN_USER};

-- Connect to custom PDB and create application user
ALTER SESSION SET CONTAINER = ${ORACLE_PDB:-${DATABASE_NAME}PDB};

CREATE USER ${ORACLE_APP_USER} IDENTIFIED BY "${ORACLE_APP_PWD}";
GRANT CONNECT, RESOURCE TO ${ORACLE_APP_USER};
GRANT UNLIMITED TABLESPACE TO ${ORACLE_APP_USER};

-- Create demo objects for app user
GRANT CREATE SESSION TO ${ORACLE_APP_USER};
GRANT CREATE TABLE TO ${ORACLE_APP_USER};
GRANT CREATE VIEW TO ${ORACLE_APP_USER};

-- Switch back to CDB
ALTER SESSION SET CONTAINER = CDB\$ROOT;

-- Show database status
SELECT name, open_mode FROM v\$database;
SELECT name, open_mode FROM v\$pdbs;

-- Create initialization marker
HOST touch /opt/oracle/oradata/.initialized

EXIT;
SQL_SETUP

        echo "✅ Custom database configured successfully"
        
    else
        echo "❌ Oracle XE configuration failed"
        exit 1
    fi
else
    echo "📋 Oracle Database already initialized, starting..."
    
    # Load configuration for existing database
    CONFIG_FILE="/opt/oracle/.oracle_config"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
    
    # Start existing database
    sqlplus / as sysdba << SQL_START
STARTUP;
ALTER PLUGGABLE DATABASE ${ORACLE_PDB:-XEPDB1} OPEN;
EXIT;
SQL_START
fi

# Start listener
echo "🔌 Starting Oracle Listener..."
lsnrctl start

# Run custom initialization scripts if they exist
if [ -d /opt/oracle/scripts ]; then
    echo "📜 Running custom initialization scripts..."
    for script in /opt/oracle/scripts/*.sql; do
        if [ -f "$script" ]; then
            echo "Executing: $script"
            sqlplus / as sysdba @"$script"
        fi
    done
fi

echo ""
echo "✅ Oracle Database XE is ready!"
echo ""
echo "Connection Details:"
echo "  🔗 Host: localhost"
echo "  🚪 Port: 1521"
echo "  🗄️  SID: XE"
echo "  🗄️  PDB: ${ORACLE_PDB:-${DATABASE_NAME}PDB}"
echo "  👤 Admin User: ${ORACLE_ADMIN_USER:-system}"
echo "  👨‍💼 App User: ${ORACLE_APP_USER:-appuser}"
echo "  🏛️  Database: ${DATABASE_NAME:-XE}"
echo ""
echo "🌐 Enterprise Manager Express:"
echo "  📱 URL: https://localhost:5500/em"
echo "  🔑 Login: ${ORACLE_ADMIN_USER:-system}/[password]"
echo ""

ORACLE_SCRIPT

# Mark as initialized
touch /opt/oracle/oradata/.initialized

# Keep container running
print_info "Oracle XE startup complete. Container will remain running."
print_info "Use 'docker exec -it oracle-xe bash -c \"/opt/oracle/scripts/login.sh\"' for interactive login"

echo ""
echo "DATABASE IS READY TO USE!"
echo ""

# Keep the container running by tailing a log file
exec tail -f /opt/oracle/diag/rdbms/xe/XE/trace/alert_XE.log