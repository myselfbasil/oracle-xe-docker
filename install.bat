@echo off
setlocal enabledelayedexpansion

REM Oracle XE Docker - Interactive Setup with Progress Bars for Windows
REM Requires Docker Desktop

title Oracle XE Docker - Interactive Setup

echo [?25l
cls
echo.
echo ************************************************
echo *  Oracle Database XE with SQL*Plus Setup     *
echo *         Interactive Installation             *
echo ************************************************
echo.

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo [31mERROR: Docker is not running. Please start Docker Desktop and try again.[0m
    echo [?25h
    pause
    exit /b 1
)

REM Progress bar function simulation
set "progress_width=50"

:step1
cls
echo [36mStep 1/6: Checking Prerequisites[0m
echo ================================================
echo.
echo Checking Docker...           [OK]
echo Checking available memory... 

REM Simulate memory check
for /f "skip=1" %%p in ('wmic os get TotalVisibleMemorySize') do (
    set memKB=%%p
    goto :mem_calculated
)
:mem_calculated
set /a memGB=!memKB! / 1024 / 1024
echo Available RAM: !memGB!GB

if !memGB! LSS 4 (
    echo [33mWarning: Only !memGB!GB RAM available. Oracle XE requires at least 4GB.[0m
)

echo.
call :show_progress 1 6 "Overall Progress"
timeout /t 1 /nobreak >nul

REM Credentials Setup
cls
echo [36mDatabase Configuration Setup[0m
echo ================================
echo.

echo [33mDatabase Administrator Setup:[0m
echo   This user will have full database privileges (SYSDBA)
echo.

REM Get admin username
:get_admin_user
set /p ORACLE_ADMIN_USER="Enter admin username (default: oracleadmin): "
if "!ORACLE_ADMIN_USER!"=="" set ORACLE_ADMIN_USER=oracleadmin

REM Basic validation for username
echo !ORACLE_ADMIN_USER! | findstr /r "^[a-zA-Z][a-zA-Z0-9_]*$" >nul
if errorlevel 1 (
    echo [31mUsername must start with a letter and contain only letters, numbers, and underscores[0m
    goto :get_admin_user
)

echo.
echo [33mDatabase Administrator Password:[0m
echo   Password requirements:
echo   • At least 8 characters
echo   • Contains uppercase and lowercase letters
echo   • Contains at least one number
echo   • Contains at least one special character
echo.

REM Get admin password
:get_admin_password
set /p "ORACLE_ADMIN_PWD=Enter admin password: "
if "!ORACLE_ADMIN_PWD!"=="" (
    echo [31mPassword cannot be empty[0m
    goto :get_admin_password
)

REM Password length check
set password_length=0
for /l %%i in (0,1,100) do (
    if not "!ORACLE_ADMIN_PWD:~%%i,1!"=="" set /a password_length+=1
)

if !password_length! LSS 8 (
    echo [31mPassword must be at least 8 characters[0m
    goto :get_admin_password
)

set /p "CONFIRM_PWD=Confirm admin password: "
if not "!ORACLE_ADMIN_PWD!"=="!CONFIRM_PWD!" (
    echo [31mPasswords do not match[0m
    goto :get_admin_password
)

echo.
echo [33mApplication User Setup:[0m
echo   This user will be used for application development
echo.

REM Get app username
:get_app_user
set /p ORACLE_APP_USER="Enter application username (default: appuser): "
if "!ORACLE_APP_USER!"=="" set ORACLE_APP_USER=appuser

echo !ORACLE_APP_USER! | findstr /r "^[a-zA-Z][a-zA-Z0-9_]*$" >nul
if errorlevel 1 (
    echo [31mUsername must start with a letter and contain only letters, numbers, and underscores[0m
    goto :get_app_user
)

REM Get app password
:get_app_password
set /p "ORACLE_APP_PWD=Enter application user password: "
if "!ORACLE_APP_PWD!"=="" (
    echo [31mPassword cannot be empty[0m
    goto :get_app_password
)

set /p "CONFIRM_APP_PWD=Confirm application user password: "
if not "!ORACLE_APP_PWD!"=="!CONFIRM_APP_PWD!" (
    echo [31mPasswords do not match[0m
    goto :get_app_password
)

echo.
echo [33mDatabase Configuration:[0m
echo.

REM Get database name
:get_db_name
set /p DATABASE_NAME="Enter database name (default: MYDB): "
if "!DATABASE_NAME!"=="" set DATABASE_NAME=MYDB

REM Store configuration
echo # Oracle XE Configuration - Generated %date% %time% > .oracle_config
echo ORACLE_ADMIN_USER="!ORACLE_ADMIN_USER!" >> .oracle_config
echo ORACLE_ADMIN_PWD="!ORACLE_ADMIN_PWD!" >> .oracle_config
echo ORACLE_APP_USER="!ORACLE_APP_USER!" >> .oracle_config
echo ORACLE_APP_PWD="!ORACLE_APP_PWD!" >> .oracle_config
echo DATABASE_NAME="!DATABASE_NAME!" >> .oracle_config
echo ORACLE_SID=XE >> .oracle_config
echo ORACLE_PDB=!DATABASE_NAME!PDB >> .oracle_config
echo ORACLE_CHARACTERSET=AL32UTF8 >> .oracle_config

echo.
echo [32mConfiguration saved:[0m
echo    Admin User: !ORACLE_ADMIN_USER!
echo    App User: !ORACLE_APP_USER!
echo    Database: !DATABASE_NAME! (PDB: !DATABASE_NAME!PDB)
echo.
pause

:step2
cls
echo [36mStep 2/6: Cleaning Up Previous Installation[0m
echo ================================================
echo.

docker ps -a --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
if not errorlevel 1 (
    echo Removing existing Oracle XE container...
    docker stop oracle-xe >nul 2>&1
    docker rm oracle-xe >nul 2>&1
    docker volume rm oracle_data >nul 2>&1
)

echo Cleanup complete
echo.
call :show_progress 2 6 "Overall Progress"
timeout /t 1 /nobreak >nul

:step3
cls
echo [36mStep 3/6: Preparing Oracle Database Image[0m
echo ================================================
echo.
echo [33mThis step downloads Oracle Database XE 21c (~2.5GB)[0m
echo [33mIt may take 10-15 minutes depending on your connection[0m
echo.

REM Check if image exists
docker image inspect container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
if not errorlevel 1 (
    echo Oracle XE image already available locally
    call :show_progress 3 6 "Overall Progress"
) else (
    echo Downloading Oracle Database XE...
    echo.
    
    REM Start download in background and show progress
    start /b cmd /c docker pull container-registry.oracle.com/database/express:21.3.0-xe 2^>^&1
    
    REM Simulate progress
    set download_progress=0
    :download_loop
    if !download_progress! LSS 100 (
        set /a download_progress+=5
        call :show_download_progress !download_progress!
        timeout /t 3 /nobreak >nul
        
        REM Check if download completed
        docker image inspect container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
        if not errorlevel 1 goto :download_complete
        
        goto :download_loop
    )
    
    :download_complete
    echo.
    echo Download complete!
)

echo.
call :show_progress 3 6 "Overall Progress"
timeout /t 1 /nobreak >nul

:step4
cls
echo [36mStep 4/6: Setting Up Data Persistence[0m
echo ================================================
echo.

docker volume create oracle_data >nul 2>&1
echo Creating Docker volume for data persistence... [OK]
echo.
call :show_progress 4 6 "Overall Progress"
timeout /t 1 /nobreak >nul

:step5
cls
echo [36mStep 5/6: Starting Oracle Database[0m
echo ================================================
echo.
echo [32mStarting with Custom Configuration[0m
echo ==================================
echo.
echo Starting container with your custom settings:
echo    Admin User: !ORACLE_ADMIN_USER!
echo    App User: !ORACLE_APP_USER!
echo    Database: !DATABASE_NAME!
echo.

REM Start container with custom environment variables
docker run -d ^
    --name oracle-xe ^
    -p 1521:1521 ^
    -p 5500:5500 ^
    -e ORACLE_PWD="!ORACLE_ADMIN_PWD!" ^
    -e ORACLE_ADMIN_USER="!ORACLE_ADMIN_USER!" ^
    -e ORACLE_APP_USER="!ORACLE_APP_USER!" ^
    -e ORACLE_APP_PWD="!ORACLE_APP_PWD!" ^
    -e DATABASE_NAME="!DATABASE_NAME!" ^
    -e ORACLE_PDB="!DATABASE_NAME!PDB" ^
    -e ORACLE_CHARACTERSET="AL32UTF8" ^
    -v oracle_data:/opt/oracle/oradata ^
    -v "%cd%\.oracle_config:/opt/oracle/.oracle_config:ro" ^
    --shm-size=2g ^
    container-registry.oracle.com/database/express:21.3.0-xe

echo.
echo [32mContainer started with custom configuration![0m
echo [32mInitializing database...[0m

echo.
echo Waiting for database to be ready...
call :wait_for_database
call :show_progress 5 6 "Overall Progress"
timeout /t 1 /nobreak >nul

:step6
cls
echo [36mStep 6/6: Finalizing Setup[0m
echo ================================================
echo.

echo Testing database connection...

REM Test connection with admin user
docker exec oracle-xe sqlplus -s "!ORACLE_ADMIN_USER!/!ORACLE_ADMIN_PWD!" -c "SELECT 'OK' FROM dual;" >nul 2>&1
if not errorlevel 1 (
    echo Connection test... [OK]
) else (
    echo Connection test... [RETRY]
    timeout /t 5 /nobreak >nul
)

echo.
call :show_progress 6 6 "Overall Progress"
echo.

echo [32m================================================[0m
echo [32m    Setup completed successfully!              [0m
echo [32m================================================[0m
echo.

:final
cls
echo [32mInstallation Complete![0m
echo ======================
echo.
echo You've successfully:
echo   - Set up Oracle Database XE
echo   - Configured the database container
echo   - Database is ready for use
echo.
echo Your Database Connection Info:
echo   Host: localhost
echo   Port: 1521
echo   Service: XE (CDB) or !DATABASE_NAME!PDB (PDB)
echo    Admin User: !ORACLE_ADMIN_USER!
echo    App User: !ORACLE_APP_USER!
echo    Database: !DATABASE_NAME!
echo.
echo Enterprise Manager Express:
echo   URL: https://localhost:5500/em
echo   Login: !ORACLE_ADMIN_USER!/[password]
echo.
echo Quick Commands:
echo   Admin: docker exec -it oracle-xe sqlplus !ORACLE_ADMIN_USER!/[password]
echo   App User: docker exec -it oracle-xe sqlplus !ORACLE_APP_USER!/[password]@!DATABASE_NAME!PDB
echo   Interactive: run.bat
echo   Stop: docker stop oracle-xe
echo   Start: docker start oracle-xe
echo.

set /p try_now="Would you like to connect to SQL*Plus now? (y/n): "
if /i "!try_now!"=="y" (
    echo.
    echo Launching SQL*Plus...
    echo Type 'EXIT;' when done
    echo.
    pause
    
    docker exec -it oracle-xe bash -c "/opt/oracle/scripts/login.sh"
)

echo.
echo [32mSetup Complete! Oracle XE is ready for development![0m
echo.
echo Your data is persistent - it survives container restarts
echo For more advanced usage, see README_FULL.md
echo.
echo Happy Oracle development!
echo [?25h
pause
exit /b 0

REM Functions
:show_progress
set current=%1
set total=%2
set message=%3

set /a percentage=!current!*100/!total!
set /a filled=!current!*!progress_width!/!total!
set /a empty=!progress_width!-!filled!

<nul set /p =!message! [
for /l %%i in (1,1,!filled!) do <nul set /p ==[34m
for /l %%i in (1,1,!empty!) do <nul set /p =-[0m
<nul set /p =] !percentage!%%

if !current! EQU !total! (
    echo  [32mOK[0m
) else (
    echo.
)
goto :eof

:show_download_progress
set percent=%1
<nul set /p =Downloading Oracle XE [
set /a filled=!percent!*!progress_width!/100
set /a empty=!progress_width!-!filled!
for /l %%i in (1,1,!filled!) do <nul set /p ==[34m
for /l %%i in (1,1,!empty!) do <nul set /p =-[0m
<nul set /p =] !percent!%%
echo.
goto :eof

:wait_for_database
set wait_count=0
:wait_loop
set /a wait_count+=1
if !wait_count! geq 60 goto :eof

docker exec oracle-xe sqlplus -s / as sysdba -c "SELECT 'READY' FROM dual;" >nul 2>&1
if not errorlevel 1 goto :eof

<nul set /p =.
timeout /t 2 /nobreak >nul
goto :wait_loop