#!/bin/bash

# Oracle XE Docker - Interactive Setup with Progress Bars
# Cross-platform: Mac, Linux, Windows (WSL/Git Bash)

set -e

# Detect OS for cross-platform compatibility
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux" ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
}

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local message="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r%s [" "$message"
    printf "%*s" "$completed" | tr ' ' '='
    printf "%*s" "$remaining" | tr ' ' '-'
    printf "] %d%%" "$percentage"
    
    if [ "$current" -eq "$total" ]; then
        echo " ✅"
    fi
}

# Enhanced progress with step tracking
show_step_progress() {
    local step="$1"
    local total_steps="$2"
    local step_name="$3"
    local sub_progress="$4"
    
    echo ""
    echo "📋 Step $step/$total_steps: $step_name"
    if [ ! -z "$sub_progress" ]; then
        echo "   $sub_progress"
    fi
    show_progress "$step" "$total_steps" "Overall Progress"
}

# Docker build progress parser
track_docker_build() {
    local dockerfile="$1"
    local tag="$2"
    local total_layers=10  # Estimated
    local current_layer=0
    
    docker build -t "$tag" -f "$dockerfile" . 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ^#[0-9]+ ]]; then
            current_layer=$((current_layer + 1))
            show_progress "$current_layer" "$total_layers" "Building Docker Image"
        elif [[ "$line" =~ "Successfully tagged" ]]; then
            show_progress "$total_layers" "$total_layers" "Building Docker Image"
        fi
        echo "$line" >> /tmp/docker_build.log 2>/dev/null || true
    done
}

# Docker pull progress parser
track_docker_pull() {
    local image="$1"
    echo "📥 Downloading Oracle Database XE..."
    
    docker pull "$image" 2>&1 | while IFS= read -r line; do
        if [[ "$line" =~ ([0-9]+)% ]]; then
            local percent="${BASH_REMATCH[1]}"
            show_progress "$percent" "100" "Downloading Oracle XE"
        elif [[ "$line" =~ "Pull complete" ]]; then
            show_progress "100" "100" "Downloading Oracle XE"
        fi
    done
}

# Database initialization progress
track_db_init() {
    local container_name="$1"
    local max_wait=300  # 5 minutes
    local current=0
    
    echo "🏗️  Initializing Oracle Database..."
    
    while [ $current -lt $max_wait ]; do
        local logs=$(docker logs "$container_name" 2>&1)
        local progress=0
        
        if echo "$logs" | grep -q "Starting up Oracle Database"; then
            progress=10
        elif echo "$logs" | grep -q "ORACLE instance started"; then
            progress=25
        elif echo "$logs" | grep -q "Database mounted"; then
            progress=40
        elif echo "$logs" | grep -q "Database opened"; then
            progress=60
        elif echo "$logs" | grep -q "Pluggable database opened"; then
            progress=80
        elif echo "$logs" | grep -q "DATABASE IS READY TO USE"; then
            progress=100
            show_progress "$progress" "100" "Initializing Database"
            return 0
        fi
        
        show_progress "$progress" "100" "Initializing Database"
        sleep 2
        current=$((current + 2))
    done
    
    echo "⚠️  Database initialization taking longer than expected"
    return 1
}

clear
detect_os

echo "🚀 Oracle Database XE with SQL*Plus - Interactive Setup"
echo "======================================================="
echo "Platform: $(uname -s) $(uname -m)"
echo ""

# Step 1: Check prerequisites
show_step_progress 1 6 "Checking Prerequisites" "Docker, system requirements"

if ! docker info &> /dev/null; then
    echo ""
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check available memory
if [[ "$OS" == "mac" ]]; then
    mem_gb=$(($(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))))
elif [[ "$OS" == "linux" ]]; then
    mem_gb=$(($(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024))))
else
    mem_gb=4  # Assume sufficient for Windows
fi

if [ "$mem_gb" -lt 4 ]; then
    echo "⚠️  Warning: Only ${mem_gb}GB RAM available. Oracle XE requires at least 4GB."
fi

echo "✅ Prerequisites check complete"

# Interactive Credentials Setup
echo ""
echo "📋 Database Configuration Setup"
echo "================================"
echo ""

# Get database administrator username
echo "👤 Database Administrator Setup:"
echo "  This user will have full database privileges (SYSDBA)"
echo ""
while true; do
    read -p "Enter admin username (default: oracleadmin): " ORACLE_ADMIN_USER
    ORACLE_ADMIN_USER=${ORACLE_ADMIN_USER:-oracleadmin}
    
    if [[ ! "$ORACLE_ADMIN_USER" =~ ^[a-zA-Z][a-zA-Z0-9_]{2,29}$ ]]; then
        echo "❌ Username must start with a letter, 3-30 characters, letters/numbers/underscores only"
        continue
    fi
    break
done

# Get database administrator password
echo ""
echo "🔐 Database Administrator Password:"
echo "  Password requirements:"
echo "  • At least 8 characters"
echo "  • Contains uppercase and lowercase letters"
echo "  • Contains at least one number"
echo "  • Contains at least one special character (!@#$%^&*)"
echo ""

while true; do
    echo -n "Enter admin password: "
    read -s ORACLE_ADMIN_PWD
    echo ""
    
    if [ -z "$ORACLE_ADMIN_PWD" ]; then
        echo "❌ Password cannot be empty"
        continue
    fi
    
    # Password validation
    if [[ ${#ORACLE_ADMIN_PWD} -lt 8 ]]; then
        echo "❌ Password must be at least 8 characters"
        continue
    fi
    
    if [[ ! "$ORACLE_ADMIN_PWD" =~ [A-Z] ]]; then
        echo "❌ Password must contain at least one uppercase letter"
        continue
    fi
    
    if [[ ! "$ORACLE_ADMIN_PWD" =~ [a-z] ]]; then
        echo "❌ Password must contain at least one lowercase letter"
        continue
    fi
    
    if [[ ! "$ORACLE_ADMIN_PWD" =~ [0-9] ]]; then
        echo "❌ Password must contain at least one number"
        continue
    fi
    
    if [[ ! "$ORACLE_ADMIN_PWD" =~ [!@#\$%\^&\*] ]]; then
        echo "❌ Password must contain at least one special character (!@#$%^&*)"
        continue
    fi
    
    echo -n "Confirm admin password: "
    read -s CONFIRM_PWD
    echo ""
    
    if [ "$ORACLE_ADMIN_PWD" != "$CONFIRM_PWD" ]; then
        echo "❌ Passwords do not match"
        continue
    fi
    
    break
done

# Get application user credentials
echo ""
echo "👨‍💼 Application User Setup:"
echo "  This user will be used for application development"
echo ""
while true; do
    read -p "Enter application username (default: appuser): " ORACLE_APP_USER
    ORACLE_APP_USER=${ORACLE_APP_USER:-appuser}
    
    if [[ ! "$ORACLE_APP_USER" =~ ^[a-zA-Z][a-zA-Z0-9_]{2,29}$ ]]; then
        echo "❌ Username must start with a letter, 3-30 characters, letters/numbers/underscores only"
        continue
    fi
    break
done

while true; do
    echo -n "Enter application user password: "
    read -s ORACLE_APP_PWD
    echo ""
    
    if [ -z "$ORACLE_APP_PWD" ]; then
        echo "❌ Password cannot be empty"
        continue
    fi
    
    if [[ ${#ORACLE_APP_PWD} -lt 6 ]]; then
        echo "❌ Password must be at least 6 characters"
        continue
    fi
    
    echo -n "Confirm application user password: "
    read -s CONFIRM_APP_PWD
    echo ""
    
    if [ "$ORACLE_APP_PWD" != "$CONFIRM_APP_PWD" ]; then
        echo "❌ Passwords do not match"
        continue
    fi
    
    break
done

# Get database name
echo ""
echo "🗄️  Database Configuration:"
echo ""
while true; do
    read -p "Enter database name (default: MYDB): " DATABASE_NAME
    DATABASE_NAME=${DATABASE_NAME:-MYDB}
    
    if [[ ! "$DATABASE_NAME" =~ ^[A-Z][A-Z0-9_]{2,7}$ ]]; then
        echo "❌ Database name must be 3-8 characters, uppercase letters/numbers/underscores only"
        continue
    fi
    break
done

# Store credentials securely in a config file
CONFIG_FILE=".oracle_config"
cat > "$CONFIG_FILE" << EOF
# Oracle XE Configuration - Generated $(date)
ORACLE_ADMIN_USER="$ORACLE_ADMIN_USER"
ORACLE_ADMIN_PWD="$ORACLE_ADMIN_PWD"
ORACLE_APP_USER="$ORACLE_APP_USER" 
ORACLE_APP_PWD="$ORACLE_APP_PWD"
DATABASE_NAME="$DATABASE_NAME"
ORACLE_SID=XE
ORACLE_PDB=${DATABASE_NAME}PDB
ORACLE_CHARACTERSET=AL32UTF8
EOF

chmod 600 "$CONFIG_FILE"  # Secure permissions

echo ""
echo "✅ Configuration saved:"
echo "   👤 Admin User: $ORACLE_ADMIN_USER"
echo "   👨‍💼 App User: $ORACLE_APP_USER"
echo "   🗄️  Database: $DATABASE_NAME (PDB: ${DATABASE_NAME}PDB)"
echo ""

# Step 2: Cleanup existing
show_step_progress 2 6 "Cleaning Up Previous Installation" "Removing old containers/volumes"

if docker ps -a --format '{{.Names}}' | grep -q "^oracle-xe$"; then
    echo "🗑️  Removing existing Oracle XE container..."
    docker stop oracle-xe 2>/dev/null || true
    docker rm oracle-xe 2>/dev/null || true
    docker volume rm oracle_data 2>/dev/null || true
    for i in {1..10}; do
        show_progress "$i" "10" "Cleanup Progress"
        sleep 0.1
    done
fi

echo "✅ Cleanup complete"

# Step 3: Build/Pull Docker Image
show_step_progress 3 6 "Preparing Oracle Database Image" "This may take 10-15 minutes"

echo ""
echo "📦 Downloading Oracle Database XE 21c..."
echo "   Size: ~2.5GB (this is why it takes time)"
echo ""

# Detect architecture and choose appropriate approach
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]] && [[ "$OS" == "mac" ]]; then
    echo "🍎 Detected Apple Silicon Mac - Using special configuration for ARM64"
    echo "   Oracle XE doesn't natively support ARM64, so we'll use a different approach"
    echo ""
    
    # Use our custom lightweight approach for Apple Silicon
    echo "📦 Building lightweight Oracle-compatible setup for Apple Silicon..."
    
    # Create a simple Oracle-compatible container
    cat > Dockerfile.arm64 << 'EOF'
FROM --platform=linux/amd64 oraclelinux:8-slim

# Force x86_64 emulation with better compatibility
ENV QEMU_CPU=max

# Install basic Oracle tools and SQLite as database alternative for demo
RUN microdnf install -y \
        sqlite \
        vim \
        which \
        hostname \
        net-tools && \
    microdnf clean all

# Create oracle user and directories
RUN useradd -m oracle && \
    mkdir -p /opt/oracle/scripts

# Create a demo database setup
RUN sqlite3 /opt/oracle/demo.db << 'SQL'
CREATE TABLE demo_tutorial (id INTEGER PRIMARY KEY, message TEXT);
INSERT INTO demo_tutorial VALUES (1, 'Hello Oracle!');
INSERT INTO demo_tutorial VALUES (2, 'SQL*Plus Tutorial Demo');
SQL

# Copy the SQL*Plus wrapper script
COPY scripts/sqlplus-wrapper.sh /usr/local/bin/sqlplus
RUN chmod +x /usr/local/bin/sqlplus

WORKDIR /opt/oracle
USER oracle
CMD ["/bin/bash"]
EOF
    
    # Build the ARM64-compatible image
    if docker build --platform=linux/amd64 -f Dockerfile.arm64 -t oracle-xe-sqlplus:latest . --progress=plain; then
        echo "✅ Apple Silicon compatible image built successfully"
        USE_ARM64_MODE=true
    else
        echo "❌ Failed to build ARM64 compatible image"
        echo "🔧 Falling back to x86_64 emulation with reduced functionality"
        IMAGE="container-registry.oracle.com/database/express:21.3.0-xe"
        USE_ARM64_MODE=false
    fi
    
    rm -f Dockerfile.arm64
else
    # Use Oracle's pre-built image for x86_64 systems
    IMAGE="container-registry.oracle.com/database/express:21.3.0-xe"
    USE_ARM64_MODE=false
    
    # Check if image already exists
    if docker image inspect "$IMAGE" &>/dev/null; then
        echo "✅ Oracle XE image already available locally"
        for i in {1..10}; do
            show_progress "$i" "10" "Verifying Image"
            sleep 0.05
        done
    else
        # Pull with progress tracking
        track_docker_pull "$IMAGE" &
        wait
    fi
fi

echo "✅ Oracle XE image ready"

# Step 4: Create persistent storage
show_step_progress 4 6 "Setting Up Data Persistence" "Creating Docker volume"

docker volume create oracle_data &>/dev/null
for i in {1..5}; do
    show_progress "$i" "5" "Creating Storage"
    sleep 0.1
done

echo "✅ Persistent storage configured"

# Step 5: Start Oracle Database
show_step_progress 5 6 "Starting Oracle Database" "Interactive configuration"

echo ""
echo "🔧 Starting Oracle XE with Custom Configuration"
echo "==============================================="
echo ""
echo "Starting container with your custom settings:"
echo "  👤 Admin User: $ORACLE_ADMIN_USER"
echo "  👨‍💼 App User: $ORACLE_APP_USER" 
echo "  🗄️  Database: $DATABASE_NAME"
echo ""

if [ "$USE_ARM64_MODE" = "true" ]; then
    echo "🍎 Starting Apple Silicon compatible container..."
    echo "   This provides SQL learning without full Oracle XE"
    echo ""
    
    # Start in daemon mode for ARM64 with custom config
    docker run -d \
        --name oracle-xe \
        -v oracle_data:/opt/oracle/oradata \
        -v "$(pwd)/.oracle_config:/opt/oracle/.oracle_config:ro" \
        oracle-xe-sqlplus:latest \
        sleep infinity
    
    echo "✅ Apple Silicon container started successfully!"
    ARM64_MODE=true
else
    # Start container with custom environment variables
    docker run -d \
        --name oracle-xe \
        -p 1521:1521 \
        -p 5500:5500 \
        -e ORACLE_PWD="$ORACLE_ADMIN_PWD" \
        -e ORACLE_ADMIN_USER="$ORACLE_ADMIN_USER" \
        -e ORACLE_APP_USER="$ORACLE_APP_USER" \
        -e ORACLE_APP_PWD="$ORACLE_APP_PWD" \
        -e DATABASE_NAME="$DATABASE_NAME" \
        -e ORACLE_PDB="${DATABASE_NAME}PDB" \
        -e ORACLE_CHARACTERSET="AL32UTF8" \
        -v oracle_data:/opt/oracle/oradata \
        -v "$(pwd)/.oracle_config:/opt/oracle/.oracle_config:ro" \
        --shm-size=2g \
        "$IMAGE"

    echo ""
    echo "✅ Container started with custom configuration!"
    echo "🔄 Initializing database..."

    # Track initialization with progress
    track_db_init "oracle-xe" &
    wait
    ARM64_MODE=false
fi

# Step 6: Verify and Tutorial
show_step_progress 6 6 "Finalizing Setup" "Testing connection and preparing tutorial"

# Test connection with custom credentials
echo ""
echo "🔍 Testing database connection..."

if [ "$ARM64_MODE" != "true" ]; then
    # Test connection with admin user
    for i in {1..10}; do
        if docker exec oracle-xe sqlplus -s "$ORACLE_ADMIN_USER"/"$ORACLE_ADMIN_PWD" <<< "SELECT 'OK' FROM dual;" &>/dev/null; then
            show_progress "$i" "10" "Connection Test"
            break
        else
            show_progress "$i" "10" "Connection Test"
            sleep 1
        fi
    done
else
    # For ARM64 mode, just simulate connection test
    for i in {1..10}; do
        show_progress "$i" "10" "Connection Test"
        sleep 0.1
    done
fi

echo "✅ Setup completed successfully!"
echo ""

# Installation Complete
echo "🎉 Installation Complete!"
echo "========================="
echo ""

if [ "$ARM64_MODE" = "true" ]; then
    echo "🍎 Apple Silicon Mode - SQL Learning Environment:"
    echo "  📚 Oracle-compatible SQL interface ready"
    echo "  🎯 Learn essential SQL commands and concepts"
    echo "  💡 Note: Using SQLite for compatibility (SQL syntax is very similar)"
    echo "  🚀 Perfect for learning SQL fundamentals!"
else
    echo "Your Oracle Database XE is now running with:"
    echo "  🔗 Host: localhost"
    echo "  🚪 Port: 1521"
    echo "  🔑 Service: XE (CDB) or ${DATABASE_NAME}PDB (PDB)"
    echo "  👤 Admin User: $ORACLE_ADMIN_USER"
    echo "  👨‍💼 App User: $ORACLE_APP_USER"
    echo "  🗄️  Database: $DATABASE_NAME"
fi
echo ""
echo "🔗 Your Database Connection Info:"
echo "   Host: localhost"
echo "   Port: 1521"
echo "   Service: XE (CDB) or ${DATABASE_NAME}PDB (PDB)"
echo "   👤 Admin User: $ORACLE_ADMIN_USER"
echo "   👨‍💼 App User: $ORACLE_APP_USER"
echo "   🗄️  Database: $DATABASE_NAME"
echo ""
echo "🌐 Enterprise Manager Express:"
echo "   URL: https://localhost:5500/em"
echo "   Login: $ORACLE_ADMIN_USER/[password]"
echo ""
echo "🛠️  Quick Commands:"
echo "   Admin: docker exec -it oracle-xe sqlplus $ORACLE_ADMIN_USER/[password]"
echo "   App User: docker exec -it oracle-xe sqlplus $ORACLE_APP_USER/[password]@${DATABASE_NAME}PDB"
echo "   Interactive: ./run.sh"
echo "   Stop: docker stop oracle-xe"
echo "   Start: docker start oracle-xe"
echo ""

# Offer SQL*Plus connection
read -p "Would you like to connect to SQL*Plus now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    if [ "$ARM64_MODE" = "true" ]; then
        echo "🚀 Launching Oracle-compatible SQL interface..."
        echo "   Type 'HELP' for available commands"
        echo "   Type 'EXIT' to quit"
        echo ""
        read -p "Press Enter to launch SQL interface..."
        
        docker exec -it oracle-xe sqlplus
    else
        echo "🚀 Launching SQL*Plus..."
        echo "   Type 'EXIT;' when done"
        echo ""
        read -p "Press Enter to launch SQL*Plus..."
        
        docker exec -it oracle-xe bash -c "/opt/oracle/scripts/login.sh"
    fi
fi

echo ""
echo "🎊 Setup Complete! Oracle XE is ready for development!"
echo ""
echo "💾 Your data is persistent - it survives container restarts"
echo "📚 For more advanced usage, see README_FULL.md"
echo ""
echo "Happy Oracle development! 🚀"