@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Resolve all paths to absolute
for %%i in ("%~dp0..") do set "ROOT_DIR=%%~fi"
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "FRONTEND_DIR=%ROOT_DIR%\frontend"

echo === YT Downloader Launcher (Development Mode) ===
echo.

:: ── Step 1: Start backend ──────────────────────────────────────────
echo [1/2] Starting backend...

:: Production mode: bundled executable
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

:: Development mode
pushd "%BACKEND_DIR%"

where poetry >nul 2>nul
if !errorlevel! equ 0 (
    echo [INFO] Starting backend via poetry...
    start "YT-Backend" cmd /c "poetry run uvicorn main:app --host 127.0.0.1 --port 8000"
    popd
    goto wait_backend
)

if exist ".venv\Scripts\uvicorn.exe" (
    echo [INFO] Starting backend via .venv uvicorn...
    start "YT-Backend" cmd /c ".venv\Scripts\uvicorn main:app --host 127.0.0.1 --port 8000"
    popd
    goto wait_backend
)

where uvicorn >nul 2>nul
if !errorlevel! equ 0 (
    echo [INFO] Starting backend via system uvicorn...
    start "YT-Backend" cmd /c "uvicorn main:app --host 127.0.0.1 --port 8000"
    popd
    goto wait_backend
)

popd
echo [ERROR] Backend not found. Start it manually:
echo   cd backend ^&^& poetry run uvicorn main:app --host 127.0.0.1 --port 8000
pause
exit /b 1

:wait_backend
echo Waiting for backend to be ready...
timeout /t 5 /nobreak >nul

:: ── Step 2: Start frontend ─────────────────────────────────────────
echo [2/2] Starting frontend...
pushd "%FRONTEND_DIR%"

:: Detect Flutter
set "FLUTTER_CMD="
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
            set "FLUTTER_CMD=flutter"
        )
    )
)

if not defined FLUTTER_CMD (
    echo [ERROR] Flutter not found. If using FVM, run: fvm use
    popd
    pause
    exit /b 1
)

echo [INFO] Running: !FLUTTER_CMD! run
call !FLUTTER_CMD! run
popd

:: ── Cleanup ─────────────────────────────────────────────────────────
echo Shutting down backend...
taskkill /fi "WINDOWTITLE eq YT-Backend" /f >nul 2>nul
echo Done.
pause
