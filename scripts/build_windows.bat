@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo  YT Downloader - Windows Build Script
echo ========================================
echo.

:: Resolve all paths to absolute
for %%i in ("%~dp0..") do set "ROOT_DIR=%%~fi"
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "FRONTEND_DIR=%ROOT_DIR%\frontend"
set "OUTPUT_DIR=%ROOT_DIR%\dist\yt-downloader-win64"

echo Root:    %ROOT_DIR%
echo Backend: %BACKEND_DIR%
echo Frontend:%FRONTEND_DIR%
echo.

:: ===================================================================
:: Step 1: Clean config.json
:: ===================================================================
echo [1/5] Resetting config.json to defaults...
python -c "import json; json.dump({'download_path': '~/Downloads', 'dark_mode': False, 'character': '\u661f\u5948'}, open(r'%BACKEND_DIR%\config.json', 'w', encoding='utf-8'), indent=2, ensure_ascii=False)"

:: ===================================================================
:: Step 2: Install Python dependencies
:: ===================================================================
echo [2/5] Installing Python dependencies...
pushd "%BACKEND_DIR%"

where poetry >nul 2>nul
if !errorlevel! equ 0 (
    echo [INFO] Installing via Poetry...
    call poetry install
) else (
    echo [INFO] Poetry not found, using pip...
    pip install fastapi uvicorn yt-dlp pyinstaller
    if !errorlevel! neq 0 (
        pip3 install fastapi uvicorn yt-dlp pyinstaller
    )
)
popd

:: ===================================================================
:: Step 3: Build backend with PyInstaller
:: ===================================================================
echo [3/5] Building backend executable...
pushd "%BACKEND_DIR%"

:: Delete any previous build
if exist "dist\yt-downloader-backend.exe" del "dist\yt-downloader-backend.exe"
if exist "yt-downloader-backend.exe" del "yt-downloader-backend.exe"

:: Determine pyinstaller command
set "PYINSTALL_CMD=pyinstaller build.spec"
where poetry >nul 2>nul
if !errorlevel! equ 0 (
    set "PYINSTALL_CMD=poetry run pyinstaller build.spec"
)

call %PYINSTALL_CMD%
if %errorlevel% neq 0 (
    echo [ERROR] Backend build failed!
    echo.
    echo Try: cd backend ^&^& python -m PyInstaller build.spec
    popd
    pause
    exit /b 1
)

:: Verify output
if not exist "dist\yt-downloader-backend.exe" (
    echo [ERROR] Backend executable not found after build!
    popd
    pause
    exit /b 1
)
echo [OK] Backend executable created.
popd

:: ===================================================================
:: Step 4: Build Flutter frontend
:: ===================================================================
echo [4/5] Building Flutter frontend...
pushd "%FRONTEND_DIR%"

:: If already built, clean it
if exist "build\windows\x64\runner\Release" (
    rmdir /s /q "build\windows\x64\runner\Release" 2>nul
)

:: Detect Flutter (FVM or system)
set "FLUTTER_CMD="
if exist ".fvm\flutter_sdk\bin\flutter.bat" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter.bat"
    echo [INFO] Using FVM Flutter SDK
) else if exist ".fvm\flutter_sdk\bin\flutter" (
    set "FLUTTER_CMD=.fvm\flutter_sdk\bin\flutter"
    echo [INFO] Using FVM Flutter SDK
) else (
    where fvm >nul 2>nul
    if !errorlevel! equ 0 (
        set "FLUTTER_CMD=fvm flutter"
        echo [INFO] Using fvm flutter
    ) else (
        where flutter >nul 2>nul
        if !errorlevel! equ 0 (
            set "FLUTTER_CMD=flutter"
            echo [INFO] Using system Flutter
        )
    )
)

if not defined FLUTTER_CMD (
    echo [ERROR] Flutter not found.
    echo If using FVM, make sure you've run: fvm use
    popd
    pause
    exit /b 1
)

echo [INFO] Running: !FLUTTER_CMD! build windows --release
call !FLUTTER_CMD! build windows --release
if %errorlevel% neq 0 (
    echo [ERROR] Frontend build failed!
    popd
    pause
    exit /b 1
)

:: Verify output
if not exist "build\windows\x64\runner\Release" (
    echo [ERROR] Frontend build output not found!
    popd
    pause
    exit /b 1
)
echo [OK] Frontend build complete.
popd

:: ===================================================================
:: Step 5: Bundle everything
:: ===================================================================
echo [5/5] Bundling application...
rmdir /s /q "%OUTPUT_DIR%" 2>nul
mkdir "%OUTPUT_DIR%"

:: Copy frontend build output
xcopy /E /I "%FRONTEND_DIR%\build\windows\x64\runner\Release" "%OUTPUT_DIR%\" >nul

:: Copy backend executable
copy "%BACKEND_DIR%\dist\yt-downloader-backend.exe" "%OUTPUT_DIR%\" >nul

:: Copy config.json (will be recreated by backend on first save if missing)
copy "%BACKEND_DIR%\config.json" "%OUTPUT_DIR%\" >nul

:: Copy launcher
copy "%ROOT_DIR%\scripts\run.bat" "%OUTPUT_DIR%\" >nul

:: Verify final bundle
if not exist "%OUTPUT_DIR%\flutter_windows.exe" (
    if not exist "%OUTPUT_DIR%\frontend.exe" (
        echo [WARN] Main executable not found in output.
        dir "%OUTPUT_DIR%"
    )
)

echo.
echo ========================================
echo  Build complete!
echo.
echo  Output: %OUTPUT_DIR%
echo.
echo  To run:
echo    %OUTPUT_DIR%\frontend.exe  ^(adjust name based on actual exe^)
echo.
echo  The app will auto-start the backend service on launch.
echo ========================================
pause
