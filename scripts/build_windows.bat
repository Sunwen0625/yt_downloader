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

:: Try poetry first, fallback to pip
where poetry >nul 2>nul
if !errorlevel! equ 0 (
    call poetry install
) else (
    echo [INFO] Poetry not found, using pip...
    where pip >nul 2>nul
    if !errorlevel! equ 0 (
        pip install fastapi uvicorn yt-dlp pyinstaller
    ) else (
        where pip3 >nul 2>nul
        if !errorlevel! equ 0 (
            pip3 install fastapi uvicorn yt-dlp pyinstaller
        ) else (
            echo [ERROR] Python package manager not found.
            pause
            exit /b 1
        )
    )
)

:: Step 3: Build backend with PyInstaller
echo [3/5] Building backend executable...
cd /d "%BACKEND_DIR%"

:: Try running pyinstaller (through poetry or directly)
set "PYINSTALL_CMD=pyinstaller build.spec"
where poetry >nul 2>nul
if !errorlevel! equ 0 (
    set "PYINSTALL_CMD=poetry run pyinstaller build.spec"
)
if exist "dist\yt-downloader-backend.exe" del "dist\yt-downloader-backend.exe"
call %PYINSTALL_CMD%

if %errorlevel% neq 0 (
    echo [ERROR] Backend build failed!
    echo.
    echo Troubleshooting:
    echo   - Make sure pyinstaller is installed: pip install pyinstaller
    echo   - Try running directly: python -m PyInstaller build.spec
    pause
    exit /b 1
)

:: Verify backend exe was created
if not exist "dist\yt-downloader-backend.exe" (
    echo [ERROR] Backend executable not found after build!
    pause
    exit /b 1
)
echo [OK] Backend executable created.

:: Step 4: Build Flutter frontend
echo [4/5] Building Flutter frontend...
cd /d "%FRONTEND_DIR%"

:: Try to detect Flutter (FVM or system-wide)
set "FLUTTER_CMD=flutter"

:: Check for FVM
if exist ".fvm\flutter_sdk\bin\flutter.bat" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter.bat"
    echo [INFO] Using FVM Flutter SDK
) else if exist ".fvm\flutter_sdk\bin\flutter" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter"
    echo [INFO] Using FVM Flutter SDK
) else (
    :: Check if fvm command is available
    where fvm >nul 2>nul
    if !errorlevel! equ 0 (
        set "FLUTTER_CMD=fvm flutter"
        echo [INFO] Using fvm flutter
    ) else (
        :: Check system flutter
        where flutter >nul 2>nul
        if !errorlevel! equ 0 (
            echo [INFO] Using system Flutter
        ) else (
            echo [ERROR] Flutter not found.
            echo.
            echo Make sure Flutter SDK is installed and available.
            echo If using FVM, run: fvm use
            pause
            exit /b 1
        )
    )
)

echo [INFO] Running: %FLUTTER_CMD% build windows --release
call %FLUTTER_CMD% build windows --release

if %errorlevel% neq 0 (
    echo [ERROR] Frontend build failed!
    pause
    exit /b 1
)

:: Verify frontend build exists
if not exist "build\windows\x64\runner\Release" (
    echo [ERROR] Frontend build output not found!
    pause
    exit /b 1
)
echo [OK] Frontend build complete.

:: Step 5: Bundle everything
echo [5/5] Bundling application...
rmdir /s /q "%OUTPUT_DIR%" 2>nul
mkdir "%OUTPUT_DIR%"

:: Copy frontend build
xcopy /E /I "%FRONTEND_DIR%\build\windows\x64\runner\Release" "%OUTPUT_DIR%\" >nul

:: Copy backend executable alongside the frontend exe
copy "%BACKEND_DIR%\dist\yt-downloader-backend.exe" "%OUTPUT_DIR%\" >nul

:: Copy launcher (for reference)
copy "%SCRIPT_DIR%\run.bat" "%OUTPUT_DIR%\" >nul

echo.
echo ========================================
echo  Build complete!
echo.
echo  Output: %OUTPUT_DIR%
echo.
echo  To run:
echo    %OUTPUT_DIR%\flutter_window.exe
echo.
echo  (The app will auto-start the backend service)
echo ========================================
pause
