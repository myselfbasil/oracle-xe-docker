@echo off
setlocal enabledelayedexpansion

REM Oracle XE Docker - Run Script for Windows
REM Use this after installation to start and connect to Oracle

title Oracle XE Docker - Run Manager

:main_menu
cls
echo.
echo ╔═══════════════════════════════════════════════╗
echo ║        Oracle XE Docker - Run Manager         ║
echo ║              Quick Access Menu                ║
echo ╚═══════════════════════════════════════════════╝
echo.

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Check if Oracle XE is installed
docker image inspect oracle-xe-sqlplus:latest >nul 2>&1
if errorlevel 1 (
    docker image inspect container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
    if errorlevel 1 (
        echo ❌ Oracle XE Docker image not found!
        echo.
        echo Please run the installation first:
        echo   install.bat
        echo.
        pause
        exit /b 1
    )
)

REM Load configuration if available
set "ORACLE_ADMIN_USER=system"
set "ORACLE_APP_USER=appuser" 
set "DATABASE_NAME=XE"

if exist ".oracle_config" (
    echo Loading configuration...
    for /f "tokens=1,2 delims==" %%a in (.oracle_config) do (
        if "%%a"=="ORACLE_ADMIN_USER" set "ORACLE_ADMIN_USER=%%~b"
        if "%%a"=="ORACLE_APP_USER" set "ORACLE_APP_USER=%%~b"
        if "%%a"=="DATABASE_NAME" set "DATABASE_NAME=%%~b"
    )
    echo Configuration loaded
) else (
    echo Warning: No configuration found, using defaults
)

REM Get container status
set "container_status=not_created"
docker ps --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
if not errorlevel 1 (
    set "container_status=running"
) else (
    docker ps -a --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
    if not errorlevel 1 (
        set "container_status=stopped"
    )
)

echo Container Status: !container_status!
echo.
echo Select an option:
echo.
echo   1) 🚀 Start Oracle XE
echo   2) 🛑 Stop Oracle XE  
echo   3) 🔄 Restart Oracle XE
echo   4) 💻 Connect to SQL*Plus
echo   5) 👑 Connect as SYSDBA
echo   6) 📋 Show Container Info
echo   7) 📜 View Logs
echo   8) 🔍 Execute SQL Command
echo   9) 🌐 Open Web Console
echo   0) 🚪 Exit
echo.

set /p choice="Enter your choice (0-9): "

if "!choice!"=="1" goto start_oracle
if "!choice!"=="2" goto stop_oracle
if "!choice!"=="3" goto restart_oracle
if "!choice!"=="4" goto connect_sqlplus
if "!choice!"=="5" goto connect_sysdba
if "!choice!"=="6" goto show_info
if "!choice!"=="7" goto show_logs
if "!choice!"=="8" goto execute_sql
if "!choice!"=="9" goto open_web
if "!choice!"=="0" goto exit_script

echo.
echo ❌ Invalid option. Please try again.
pause
goto main_menu

:start_oracle
echo.
if "!container_status!"=="running" (
    echo ✅ Oracle XE is already running!
) else if "!container_status!"=="stopped" (
    echo ℹ️  Starting Oracle XE container...
    docker start oracle-xe
    call :wait_for_database
    echo ✅ Oracle XE started successfully!
) else (
    echo ℹ️  Creating and starting Oracle XE container...
    call :create_container
    call :wait_for_database
    echo ✅ Oracle XE created and started successfully!
)
pause
goto main_menu

:create_container
REM Check if we have the official Oracle image
docker image inspect container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
if not errorlevel 1 (
    set "IMAGE=container-registry.oracle.com/database/express:21.3.0-xe"
) else (
    set "IMAGE=oracle-xe-sqlplus:latest"
)

docker run -d ^
    --name oracle-xe ^
    -p 1521:1521 ^
    -p 5500:5500 ^
    -e ORACLE_PWD="OracleXE123!" ^
    -e ORACLE_CHARACTERSET="AL32UTF8" ^
    -v oracle_data:/opt/oracle/oradata ^
    --shm-size=2g ^
    !IMAGE!
goto :eof

:wait_for_database
echo ℹ️  Waiting for database to be ready...
set wait_count=0
:wait_loop
set /a wait_count+=1
if !wait_count! geq 30 goto :eof

docker exec oracle-xe sqlplus -s / as sysdba -c "SELECT 'READY' FROM dual;" >nul 2>&1
if not errorlevel 1 goto :eof

timeout /t 2 /nobreak >nul
goto wait_loop

:stop_oracle
echo.
docker ps --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
if not errorlevel 1 (
    echo ℹ️  Stopping Oracle XE...
    docker stop oracle-xe
    echo ✅ Oracle XE stopped!
) else (
    echo ⚠️  Oracle XE is not running
)
pause
goto main_menu

:restart_oracle
echo.
echo ℹ️  Restarting Oracle XE...
call :stop_oracle
timeout /t 2 /nobreak >nul
call :start_oracle
goto main_menu

:connect_sqlplus
echo.
if not "!container_status!"=="running" (
    echo ⚠️  Oracle XE is not running. Starting it first...
    call :start_oracle
)

echo.
echo ℹ️  Launching Interactive SQL*Plus Login...
echo 🏛️  Oracle Database - Interactive Login Terminal
echo.

docker exec -it oracle-xe bash -c "/opt/oracle/scripts/login.sh"
goto main_menu

:connect_sysdba
echo.
if not "!container_status!"=="running" (
    echo ⚠️  Oracle XE is not running. Starting it first...
    call :start_oracle
)

echo.
echo ℹ️  Connecting as SYSDBA...
docker exec -it oracle-xe sqlplus / as sysdba
goto main_menu

:show_info
echo.
echo ℹ️  Oracle XE Container Information
echo ═══════════════════════════════════════
echo.
echo Status: !container_status!

if "!container_status!"=="running" (
    echo.
    echo Connection Details:
    echo   Host: localhost
    echo   Port: 1521
    echo   Service: XE (CDB) or !DATABASE_NAME!PDB (PDB)
    echo    Admin User: !ORACLE_ADMIN_USER!
    echo    App User: !ORACLE_APP_USER!
    echo    Database: !DATABASE_NAME!
    echo.
    echo Web Console:
    echo   URL: https://localhost:5500/em
    echo   Login: !ORACLE_ADMIN_USER! / [password]
    echo.
    echo Resource Usage:
    docker stats oracle-xe --no-stream --format "  CPU: {{.CPUPerc}}    Memory: {{.MemUsage}}"
)
echo.
pause
goto main_menu

:show_logs
echo.
echo ℹ️  Showing Oracle XE logs (Ctrl+C to exit)...
echo.
docker logs oracle-xe
pause
goto main_menu

:execute_sql
echo.
if not "!container_status!"=="running" (
    echo ⚠️  Oracle XE is not running. Starting it first...
    call :start_oracle
)

echo.
set /p sql_cmd="Enter SQL command (or 'back' to return): "

if not "!sql_cmd!"=="back" (
    echo.
    echo !sql_cmd! | docker exec -i oracle-xe sqlplus -s system/OracleXE123!
    echo.
    pause
)
goto main_menu

:open_web
echo.
echo ℹ️  Opening Enterprise Manager Express...
echo URL: https://localhost:5500/em
echo Login: system / OracleXE123!
echo.

start https://localhost:5500/em
pause
goto main_menu

:exit_script
echo.
echo ✅ Thank you for using Oracle XE Docker!
echo.
pause
exit /b 0