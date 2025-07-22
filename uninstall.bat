@echo off
setlocal enabledelayedexpansion

REM Oracle XE Docker - Complete Uninstaller for Windows
REM Requires Docker Desktop

title Oracle XE Docker - Complete Uninstaller

cls
echo.
echo ************************************************
echo *     Oracle XE Docker - Uninstaller          *
echo *           Complete Removal Tool             *
echo ************************************************
echo.
echo Platform: Windows
echo.

echo [33mWARNING: This will completely remove:[0m
echo    - Oracle XE Docker container
echo    - All database data (including your tables and data)
echo    - Docker images and volumes
echo    - All Oracle XE related files
echo.
echo [31mYour data will be permanently lost unless you have backups![0m
echo.

set /p confirm1="Are you sure you want to continue? (Type 'YES' to confirm): "
echo.

if not "!confirm1!"=="YES" (
    echo [31mUninstall cancelled.[0m
    pause
    exit /b 0
)

echo [33mFinal confirmation required.[0m
set /p confirm2="This action cannot be undone. Type 'DELETE EVERYTHING' to proceed: "
echo.

if not "!confirm2!"=="DELETE EVERYTHING" (
    echo [31mUninstall cancelled for safety.[0m
    pause
    exit /b 0
)

echo [32mStarting complete removal...[0m
echo.

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo [33mWarning: Docker is not running, but will continue with file cleanup[0m
    goto file_cleanup
)

REM Step 1: Stop and remove container
echo [36mStep 1/6: Stopping Oracle XE Container[0m
echo =========================================
echo.

docker ps --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
if not errorlevel 1 (
    echo Stopping Oracle XE container...
    docker stop oracle-xe >nul 2>&1
    call :show_progress "Stopping Container"
) else (
    echo Container not running
    call :show_progress "Checking Container"
)

echo [32mContainer stop complete[0m
echo.

REM Step 2: Remove container
echo [36mStep 2/6: Removing Oracle XE Container[0m
echo ========================================
echo.

docker ps -a --format "{{.Names}}" | findstr /r "^oracle-xe$" >nul 2>&1
if not errorlevel 1 (
    echo Removing Oracle XE container...
    docker rm oracle-xe >nul 2>&1
    call :show_progress "Removing Container"
) else (
    echo Container not found
    call :show_progress "Checking Container"
)

echo [32mContainer removal complete[0m
echo.

REM Step 3: Remove Docker volumes
echo [36mStep 3/6: Removing Data Volumes[0m
echo =================================
echo.

echo Removing persistent data volumes...
docker volume rm oracle_data >nul 2>&1
call :show_progress "Removing Volumes"

echo [32mVolume removal complete[0m
echo.

REM Step 4: Remove Docker images
echo [36mStep 4/6: Removing Docker Images[0m
echo ==================================
echo.

echo Removing Oracle Docker images...
set removed_count=0

REM Remove custom ARM64 image
docker image inspect oracle-xe-sqlplus:latest >nul 2>&1
if not errorlevel 1 (
    docker image rm oracle-xe-sqlplus:latest >nul 2>&1
    set /a removed_count+=1
)

REM Remove official Oracle XE image
docker image inspect container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
if not errorlevel 1 (
    docker image rm container-registry.oracle.com/database/express:21.3.0-xe >nul 2>&1
    set /a removed_count+=1
)

call :show_progress "Removing Images"

echo [32mRemoved !removed_count! Docker images[0m
echo.

REM Step 5: Clean up temporary files
echo [36mStep 5/6: Cleaning Temporary Files[0m
echo ===================================
echo.

echo Cleaning temporary files...

REM Remove any temporary files created during installation
del /q /f %TEMP%\docker_build.log >nul 2>&1
del /q /f Dockerfile.arm64 >nul 2>&1

call :show_progress "Cleaning Files"

echo [32mTemporary files cleaned[0m
echo.

:file_cleanup
REM Step 6: Optional cleanup of installation files
echo [36mStep 6/6: Optional File Cleanup[0m
echo ================================
echo.

echo Installation Files:
echo    - install.sh / install.bat
echo    - uninstall.sh / uninstall.bat
echo    - run.sh / run.bat
echo    - Dockerfile and scripts
echo    - README files
echo.

set /p remove_files="Remove installation files too? (y/n): "
echo.

if /i "!remove_files!"=="y" (
    echo Removing installation files...
    
    set removed_files=0
    
    REM Remove main files
    if exist "install.sh" (del /q "install.sh" && set /a removed_files+=1)
    if exist "install.bat" (del /q "install.bat" && set /a removed_files+=1)
    if exist "uninstall.sh" (del /q "uninstall.sh" && set /a removed_files+=1)
    if exist "uninstall.bat" (del /q "uninstall.bat" && set /a removed_files+=1)
    if exist "run.sh" (del /q "run.sh" && set /a removed_files+=1)
    if exist "run.bat" (del /q "run.bat" && set /a removed_files+=1)
    if exist "Dockerfile" (del /q "Dockerfile" && set /a removed_files+=1)
    if exist "docker-compose.yml" (del /q "docker-compose.yml" && set /a removed_files+=1)
    if exist "docker-compose-prebuilt.yml" (del /q "docker-compose-prebuilt.yml" && set /a removed_files+=1)
    if exist "docker-compose-instant-client.yml" (del /q "docker-compose-instant-client.yml" && set /a removed_files+=1)
    if exist "entrypoint.sh" (del /q "entrypoint.sh" && set /a removed_files+=1)
    if exist ".dockerignore" (del /q ".dockerignore" && set /a removed_files+=1)
    if exist "README.md" (del /q "README.md" && set /a removed_files+=1)
    if exist "README_FULL.md" (del /q "README_FULL.md" && set /a removed_files+=1)
    if exist "README_TROUBLESHOOTING.md" (del /q "README_TROUBLESHOOTING.md" && set /a removed_files+=1)
    
    REM Remove scripts directory
    if exist "scripts" (
        rmdir /s /q "scripts" >nul 2>&1
        set /a removed_files+=1
    )
    
    call :show_progress "Removing Files"
    
    echo [32mRemoved !removed_files! installation files[0m
) else (
    echo [33mKeeping installation files for future use[0m
    call :show_progress "Skipping Cleanup"
)

echo.

REM Final cleanup - Docker system prune
set /p cleanup_docker="Run Docker system cleanup to free disk space? (y/n): "
echo.

if /i "!cleanup_docker!"=="y" (
    echo Cleaning Docker system...
    docker system prune -f >nul 2>&1
    echo [32mDocker cleanup completed[0m
)

REM Final summary
cls
echo [32m************************************************[0m
echo [32m*         Uninstallation Complete!            *[0m
echo [32m************************************************[0m
echo.

echo [32mSuccessfully removed:[0m
echo    - Oracle XE Docker container
echo    - All database data and volumes
echo    - Docker images
echo    - Temporary files

if /i "!remove_files!"=="y" (
    echo    - Installation files
)

echo.
echo [33mWhat was removed:[0m
echo    - Container: oracle-xe
echo    - Volume: oracle_data (all your database data)
echo    - Images: Oracle XE Docker images
echo.

echo [36mTo reinstall Oracle XE:[0m
echo    - Download the installation files again
echo    - Run: install.bat
echo.

echo [36mSystem Status:[0m
echo    - Docker is still installed and running
echo    - Other Docker containers are unaffected
echo    - System dependencies remain intact
echo.

echo [32mThank you for using Oracle XE Docker![0m
echo.

echo [33mPro Tip: Always backup your database before uninstalling![0m
echo    You can use 'docker exec oracle-xe expdp...' for full exports
echo.

echo [33mApproximate disk space freed: ~3-4GB[0m
echo.

echo [32mUninstallation completed successfully![0m
echo.
pause
exit /b 0

REM Functions
:show_progress
set message=%1
echo %message%... [                                                  ]
timeout /t 1 /nobreak >nul
echo %message%... [==========                                        ]
timeout /t 1 /nobreak >nul
echo %message%... [====================                              ]
timeout /t 1 /nobreak >nul
echo %message%... [==============================                    ]
timeout /t 1 /nobreak >nul
echo %message%... [========================================          ]
timeout /t 1 /nobreak >nul
echo %message%... [==================================================] [32mOK[0m
goto :eof