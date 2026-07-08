@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%frontend"

echo === YT Downloader Launcher ===

:: Start backend
echo [1/2] Starting backend...
cd /d "%BACKEND_DIR%"

:: Check if poetry is available
where poetry >nul 2>nul
if %errorlevel% equ 0 (
    start "YT-Backend" cmd /c "poetry run uvicorn main:app --host 127.0.0.1 --port 8000"
) else (
    :: Check if uvicorn is available directly
    where uvicorn >nul 2>nul
    if !errorlevel! equ 0 (
        start "YT-Backend" cmd /c "uvicorn main:app --host 127.0.0.1 --port 8000"
    ) else (
        echo Error: poetry or uvicorn not found. Install dependencies first.
        pause
        exit /b 1
    )
)

:: Wait for backend
echo Waiting for backend...
timeout /t 5 /nobreak >nul

:: Start frontend
echo [2/2] Starting frontend...
cd /d "%FRONTEND_DIR%"

where flutter >nul 2>nul
if %errorlevel% equ 0 (
    flutter run
) else (
    echo Error: flutter not found.
    pause
)

:: Cleanup backend on exit
taskkill /fi "WINDOWTITLE eq YT-Backend" /f >nul 2>nul
pause
