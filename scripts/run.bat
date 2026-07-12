@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%frontend"

echo === YT Downloader Launcher (Development Mode) ===
echo.

:: Start backend
echo [1/2] Starting backend...

:: Check if bundled backend executable exists (production mode)
if exist "%ROOT_DIR%\yt-downloader-backend.exe" (
    echo [INFO] Found bundled backend executable.
    start "YT-Backend" "%ROOT_DIR%\yt-downloader-backend.exe"
    goto wait_backend
)

if exist "%BACKEND_DIR%\dist\yt-downloader-backend.exe" (
    echo [INFO] Found built backend executable.
    start "YT-Backend" "%BACKEND_DIR%\dist\yt-downloader-backend.exe"
    goto wait_backend
)

:: Development mode: try poetry or uvicorn
cd /d "%BACKEND_DIR%"

where poetry >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Starting backend via poetry...
    start "YT-Backend" cmd /c "poetry run uvicorn main:app --host 127.0.0.1 --port 8000"
    goto wait_backend
)

:: Check inside .venv directly
if exist ".venv\Scripts\uvicorn.exe" (
    echo [INFO] Starting backend via .venv uvicorn...
    start "YT-Backend" cmd /c ".venv\Scripts\uvicorn main:app --host 127.0.0.1 --port 8000"
    goto wait_backend
)

where uvicorn >nul 2>nul
if %errorlevel% equ 0 (
    echo [INFO] Starting backend via system uvicorn...
    start "YT-Backend" cmd /c "uvicorn main:app --host 127.0.0.1 --port 8000"
    goto wait_backend
)

echo [ERROR] Backend not found.
echo.
echo Options:
echo   1. Run backend manually:  cd backend ^&^& poetry run uvicorn main:app --host 127.0.0.1 --port 8000
echo   2. Build backend first:   pyinstaller backend\build.spec
pause
exit /b 1

:wait_backend
echo Waiting for backend to be ready...
timeout /t 5 /nobreak >nul

:: Start frontend
echo [2/2] Starting frontend...
cd /d "%FRONTEND_DIR%"

:: Detect Flutter (FVM or system)
set "FLUTTER_CMD=flutter"

if exist ".fvm\flutter_sdk\bin\flutter.bat" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter.bat"
) else if exist ".fvm\flutter_sdk\bin\flutter" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter"
) else (
    where fvm >nul 2>nul
    if !errorlevel! equ 0 (
        set "FLUTTER_CMD=fvm flutter"
    ) else (
        where flutter >nul 2>nul
        if !errorlevel! equ 0 (
            echo [INFO] Using system Flutter
        ) else (
            echo [ERROR] Flutter not found.
            echo If using FVM, run: fvm use
            pause
            exit /b 1
        )
    )
)

echo [INFO] Running: %FLUTTER_CMD% run
call %FLUTTER_CMD% run

:: Cleanup backend on exit
echo Shutting down backend...
taskkill /fi "WINDOWTITLE eq YT-Backend" /f >nul 2>nul
echo Done.
pause
