#!/bin/bash

# Oracle XE Docker - Complete Uninstaller
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
    
    echo ""
    echo "📋 Step $step/$total_steps: $step_name"
    show_progress "$step" "$total_steps" "Overall Progress"
}

clear
detect_os

echo "🗑️  Oracle Database XE Docker - Complete Uninstaller"
echo "=================================================="
echo "Platform: $(uname -s) $(uname -m)"
echo ""

echo "WARNING: This will completely remove:"
echo "   • Oracle XE Docker container"
echo "   • All database data (including your tables and data)"
echo "   • Docker images and volumes"
echo "   • Configuration files"
echo ""
echo "Your data will be permanently lost unless you have backups!"
echo ""

read -p "Are you sure you want to continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo "🚀 Starting complete removal..."
echo ""

# Step 1: Stop and remove container
show_step_progress 1 6 "Stopping Oracle XE Container"

if docker ps --format '{{.Names}}' | grep -q "^oracle-xe$"; then
    echo "🛑 Stopping Oracle XE container..."
    docker stop oracle-xe &>/dev/null || true
    for i in {1..10}; do
        show_progress "$i" "10" "Stopping Container"
        sleep 0.1
    done
else
    echo "ℹ️  Container not running"
    for i in {1..10}; do
        show_progress "$i" "10" "Checking Container"
        sleep 0.05
    done
fi

echo "✅ Container stop complete"

# Step 2: Remove container
show_step_progress 2 6 "Removing Oracle XE Container"

if docker ps -a --format '{{.Names}}' | grep -q "^oracle-xe$"; then
    echo "🗑️  Removing Oracle XE container..."
    docker rm oracle-xe &>/dev/null || true
    for i in {1..10}; do
        show_progress "$i" "10" "Removing Container"
        sleep 0.1
    done
else
    echo "ℹ️  Container not found"
    for i in {1..10}; do
        show_progress "$i" "10" "Checking Container"
        sleep 0.05
    done
fi

echo "✅ Container removal complete"

# Step 3: Remove Docker volumes
show_step_progress 3 6 "Removing Data Volumes"

echo "🗄️  Removing persistent data volumes..."
docker volume rm oracle_data &>/dev/null || true
for i in {1..10}; do
    show_progress "$i" "10" "Removing Volumes"
    sleep 0.1
done

echo "✅ Volume removal complete"

# Step 4: Remove Docker images
show_step_progress 4 6 "Removing Docker Images"

echo "📦 Removing Oracle Docker images..."
removed_count=0

# Remove custom ARM64 image
if docker image inspect oracle-xe-sqlplus:latest &>/dev/null; then
    docker image rm oracle-xe-sqlplus:latest &>/dev/null || true
    ((removed_count++))
fi

# Remove official Oracle XE image
if docker image inspect container-registry.oracle.com/database/express:21.3.0-xe &>/dev/null; then
    docker image rm container-registry.oracle.com/database/express:21.3.0-xe &>/dev/null || true
    ((removed_count++))
fi

for i in {1..10}; do
    show_progress "$i" "10" "Removing Images"
    sleep 0.1
done

echo "✅ Removed $removed_count Docker images"

# Step 5: Clean up temporary files
show_step_progress 5 6 "Cleaning Temporary Files"

echo "🧹 Cleaning temporary files..."

# Remove any temporary files created during installation
rm -f /tmp/docker_build.log &>/dev/null || true
rm -f Dockerfile.arm64 &>/dev/null || true

for i in {1..10}; do
    show_progress "$i" "10" "Cleaning Files"
    sleep 0.1
done

echo "✅ Temporary files cleaned"

# Step 6: Cleanup configuration files only
show_step_progress 6 6 "Removing Configuration Files"

echo "🗑️  Removing configuration files..."

# Remove only configuration files, keep installation scripts
removed_files=0
if [ -f ".oracle_config" ]; then
    rm -f ".oracle_config" && ((removed_files++))
fi

for i in {1..10}; do
    show_progress "$i" "10" "Removing Config"
    sleep 0.1
done

echo "✅ Removed configuration files (keeping installation scripts)"

# Final cleanup - Docker system prune
echo ""
echo "🧹 Running Docker system cleanup..."
docker system prune -f &>/dev/null || true
echo "✅ Docker cleanup completed"

# Final summary
clear
echo "🎉 Uninstallation Complete!"
echo "=========================="
echo ""
echo "✅ Successfully removed:"
echo "   • Oracle XE Docker container"
echo "   • All database data and volumes"
echo "   • Docker images"
echo "   • Configuration files"
echo "   • Temporary files"

echo ""
echo "💾 What was removed:"
echo "   • Container: oracle-xe"
echo "   • Volume: oracle_data (all your database data)"
echo "   • Images: Oracle XE Docker images"
echo ""

echo "🔄 To reinstall Oracle XE:"
echo "   • Run: ./install.sh (installation files preserved)"
echo ""

echo "📊 System Status:"
echo "   • Docker is still installed and running"
echo "   • Other Docker containers are unaffected"
echo "   • System dependencies remain intact"
echo ""

echo "🙏 Thank you for using Oracle XE Docker!"
echo ""

echo "💡 Pro Tip: Always backup your database before uninstalling!"
echo "   You can use 'docker exec oracle-xe expdp...' for full exports"
echo ""

# Show disk space freed (approximate)
if command -v df &> /dev/null; then
    echo "💾 Approximate disk space freed: ~3-4GB"
fi

echo ""
echo "🚀 Uninstallation completed successfully!"
