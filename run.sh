#!/bin/bash

# Oracle XE Docker - Run Script
# Cross-platform: Mac, Linux, Windows (WSL/Git Bash)
# Use this after installation to start and connect to Oracle

set -e

# Detect OS for cross-platform compatibility
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        ARCH=$(uname -m)
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux" ]]; then
        OS="linux"
        ARCH=$(uname -m)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        ARCH="x86_64"
    else
        OS="unknown"
        ARCH="unknown"
    fi
}

# Color codes for output
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

# Show banner
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║        Oracle XE Docker - Run Manager         ║"
    echo "║              Quick Access Menu                ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Platform: $(uname -s) $(uname -m)"
    echo ""
}

# Check Docker status
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if Oracle XE is installed
check_installation() {
    if ! docker image inspect oracle-xe-sqlplus:latest &> /dev/null && \
       ! docker image inspect container-registry.oracle.com/database/express:21.3.0-xe &> /dev/null; then
        print_error "Oracle XE Docker image not found!"
        echo ""
        echo "Please run the installation first:"
        echo "  ./install.sh    (Mac/Linux)"
        echo "  install.bat     (Windows)"
        echo ""
        exit 1
    fi
}

# Get container status
get_container_status() {
    if docker ps --format '{{.Names}}' | grep -q "^oracle-xe$"; then
        echo "running"
    elif docker ps -a --format '{{.Names}}' | grep -q "^oracle-xe$"; then
        echo "stopped"
    else
        echo "not_created"
    fi
}

# Start Oracle XE container
start_oracle() {
    local status=$(get_container_status)
    
    case "$status" in
        "running")
            print_success "Oracle XE is already running!"
            ;;
        "stopped")
            print_info "Starting Oracle XE container..."
            docker start oracle-xe
            wait_for_database
            print_success "Oracle XE started successfully!"
            ;;
        "not_created")
            print_info "Creating and starting Oracle XE container..."
            create_container
            wait_for_database
            print_success "Oracle XE created and started successfully!"
            ;;
    esac
}

# Create new container
create_container() {
    # Detect if we need ARM64 mode
    if [[ "$ARCH" == "arm64" ]] && [[ "$OS" == "mac" ]]; then
        print_info "Detected Apple Silicon - using compatibility mode"
        docker run -d \
            --name oracle-xe \
            -v oracle_data:/opt/oracle/oradata \
            oracle-xe-sqlplus:latest \
            sleep infinity
    else
        # Check if we have the official Oracle image
        if docker image inspect container-registry.oracle.com/database/express:21.3.0-xe &> /dev/null; then
            IMAGE="container-registry.oracle.com/database/express:21.3.0-xe"
        else
            IMAGE="oracle-xe-sqlplus:latest"
        fi
        
        docker run -d \
            --name oracle-xe \
            -p 1521:1521 \
            -p 5500:5500 \
            -e ORACLE_PWD="OracleXE123!" \
            -e ORACLE_CHARACTERSET="AL32UTF8" \
            -v oracle_data:/opt/oracle/oradata \
            --shm-size=2g \
            "$IMAGE"
    fi
}

# Wait for database to be ready
wait_for_database() {
    print_info "Waiting for database to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if [[ "$ARCH" == "arm64" ]] && [[ "$OS" == "mac" ]]; then
            # For ARM64, just check if container is running
            if docker ps --format '{{.Names}}' | grep -q "^oracle-xe$"; then
                break
            fi
        else
            # For x86_64, check if database is actually ready
            if docker exec oracle-xe sqlplus -s / as sysdba <<< "SELECT 'READY' FROM dual;" &>/dev/null 2>&1; then
                break
            fi
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    echo ""
}

# Stop Oracle XE
stop_oracle() {
    if docker ps --format '{{.Names}}' | grep -q "^oracle-xe$"; then
        print_info "Stopping Oracle XE..."
        docker stop oracle-xe
        print_success "Oracle XE stopped!"
    else
        print_warning "Oracle XE is not running"
    fi
}

# Restart Oracle XE
restart_oracle() {
    print_info "Restarting Oracle XE..."
    stop_oracle
    sleep 2
    start_oracle
}

# Connect to SQL*Plus
connect_sqlplus() {
    local status=$(get_container_status)
    
    if [ "$status" != "running" ]; then
        print_warning "Oracle XE is not running. Starting it first..."
        start_oracle
    fi
    
    echo ""
    print_info "Launching Interactive SQL*Plus Login..."
    
    if [[ "$ARCH" == "arm64" ]] && [[ "$OS" == "mac" ]]; then
        echo "🍎 Apple Silicon Mode - Oracle-compatible SQL interface"
    else
        echo "🏛️  Oracle Database - Interactive Login Terminal"
    fi
    
    echo ""
    docker exec -it oracle-xe bash -c "/opt/oracle/scripts/login.sh"
}

# Connect as SYSDBA
connect_sysdba() {
    local status=$(get_container_status)
    
    if [ "$status" != "running" ]; then
        print_warning "Oracle XE is not running. Starting it first..."
        start_oracle
    fi
    
    echo ""
    print_info "Connecting as SYSDBA..."
    docker exec -it oracle-xe sqlplus / as sysdba
}

# Show logs
show_logs() {
    print_info "Showing Oracle XE logs (Ctrl+C to exit)..."
    echo ""
    docker logs -f oracle-xe
}

# Show container info
show_info() {
    echo ""
    print_info "Oracle XE Container Information"
    echo "═══════════════════════════════════════"
    
    local status=$(get_container_status)
    echo "Status: $status"
    
    if [ "$status" == "running" ]; then
        echo ""
        echo "Connection Details:"
        echo "  Host: localhost"
        echo "  Port: 1521"
        echo "  Service: XE (CDB) or ${DATABASE_NAME:-XE}PDB (PDB)"
        echo "  👤 Admin User: ${ORACLE_ADMIN_USER:-system}"
        echo "  👨‍💼 App User: ${ORACLE_APP_USER:-appuser}"
        echo "  🗄️  Database: ${DATABASE_NAME:-XE}"
        echo ""
        echo "Web Console:"
        echo "  URL: https://localhost:5500/em"
        echo "  Login: ${ORACLE_ADMIN_USER:-system} / [password]"
        
        # Show resource usage
        echo ""
        echo "Resource Usage:"
        docker stats oracle-xe --no-stream --format "  CPU: {{.CPUPerc}}\n  Memory: {{.MemUsage}}"
    fi
    
    echo ""
}

# Execute custom SQL
execute_sql() {
    local status=$(get_container_status)
    
    if [ "$status" != "running" ]; then
        print_warning "Oracle XE is not running. Starting it first..."
        start_oracle
    fi
    
    echo ""
    print_info "Quick SQL Execution (or 'back' to return):"
    print_warning "For full interactive mode, use option 4"
    echo ""
    read -p "SQL> " sql_cmd
    
    if [[ "$sql_cmd" != "back" ]]; then
        echo ""
        print_info "Executing SQL command..."
        # Use interactive login for SQL execution
        echo "$sql_cmd" | docker exec -i oracle-xe bash -c "/opt/oracle/scripts/login.sh"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Main menu
show_menu() {
    echo "Select an option:"
    echo ""
    echo "  1) 🚀 Start Oracle XE"
    echo "  2) 🛑 Stop Oracle XE"
    echo "  3) 🔄 Restart Oracle XE"
    echo "  4) 💻 Connect to SQL*Plus"
    echo "  5) 👑 Connect as SYSDBA"
    echo "  6) 📋 Show Container Info"
    echo "  7) 📜 View Logs"
    echo "  8) 🔍 Execute SQL Command"
    echo "  9) 🌐 Open Web Console"
    echo "  0) 🚪 Exit"
    echo ""
}

# Open web console
open_web_console() {
    local url="https://localhost:5500/em"
    
    print_info "Opening Enterprise Manager Express..."
    echo "URL: $url"
    echo "Login: system / OracleXE123!"
    echo ""
    
    # Try to open in default browser
    if [[ "$OS" == "mac" ]]; then
        open "$url" 2>/dev/null || true
    elif [[ "$OS" == "linux" ]]; then
        xdg-open "$url" 2>/dev/null || true
    elif [[ "$OS" == "windows" ]]; then
        start "$url" 2>/dev/null || true
    fi
    
    read -p "Press Enter to continue..."
}

# Load configuration
load_config() {
    CONFIG_FILE=".oracle_config"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        print_info "Configuration loaded"
    else
        print_warning "No configuration found, using defaults"
        ORACLE_ADMIN_USER="system"
        ORACLE_APP_USER="appuser"
        DATABASE_NAME="XE"
    fi
}

# Main program
main() {
    detect_os
    check_docker
    check_installation
    load_config
    
    while true; do
        show_banner
        show_menu
        
        read -p "Enter your choice (0-9): " choice
        
        case $choice in
            1) start_oracle ;;
            2) stop_oracle ;;
            3) restart_oracle ;;
            4) connect_sqlplus ;;
            5) connect_sysdba ;;
            6) show_info ;;
            7) show_logs ;;
            8) execute_sql ;;
            9) open_web_console ;;
            0) 
                print_success "Thank you for using Oracle XE Docker!"
                exit 0 
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        if [[ "$choice" != "7" ]] && [[ "$choice" != "4" ]] && [[ "$choice" != "5" ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
}

# Run main program
main "$@"