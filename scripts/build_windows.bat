@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo  YT Downloader - Windows Build Script
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "OUTPUT_DIR=%ROOT_DIR%\dist\yt-downloader-win64"

:: Step 1: Clean config.json
echo [1/5] Resetting config.json to defaults...
echo {"download_path": "~/Downloads", "dark_mode": false, "character": "\u661f\u5948"} > "%BACKEND_DIR%\config.json"

:: Step 2: Install Python dependencies
echo [2/5] Installing Python dependencies...
cd /d "%BACKEND_DIR%"
call poetry install --no-root || (
    echo [WARNING] Poetry not found, trying pip...
    pip install -r requirements.txt 2>nul || (
        pip install fastapi uvicorn yt-dlp pyinstaller
    )
)

:: Step 3: Build backend with PyInstaller
echo [3/5] Building backend executable...
cd /d "%BACKEND_DIR%"
if exist "pyinstaller.exe" (
    pyinstaller build.spec
) else (
    python -m PyInstaller build.spec
)

if %errorlevel% neq 0 (
    echo [ERROR] Backend build failed!
    pause
    exit /b 1
)

:: Step 4: Build Flutter frontend
echo [4/5] Building Flutter frontend...
cd /d "%FRONTEND_DIR%"
call flutter build windows --release

if %errorlevel% neq 0 (
    echo [ERROR] Frontend build failed!
    pause
    exit /b 1
)

:: Step 5: Bundle everything
echo [5/5] Bundling application...
rmdir /s /q "%OUTPUT_DIR%" 2>nul
mkdir "%OUTPUT_DIR%"

:: Copy frontend build
xcopy /E /I "%FRONTEND_DIR%\build\windows\x64\runner\Release" "%OUTPUT_DIR%\frontend"

:: Copy backend executable
copy "%BACKEND_DIR%\dist\yt-downloader-backend.exe" "%OUTPUT_DIR%\frontend\"

:: Copy launcher
copy "%SCRIPT_DIR%\run.bat" "%OUTPUT_DIR%\"

:: Copy config (will be created on first run)
:: (intentionally omitted - backend creates default at startup)

echo.
echo ========================================
echo  Build complete!
echo.
echo  Output: %OUTPUT_DIR%
echo.
echo  To run:
echo    %OUTPUT_DIR%\run.bat
echo ========================================
pause
