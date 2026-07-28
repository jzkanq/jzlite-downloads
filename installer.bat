@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title JZLite 1.0.1 Downloader

set "VERSION=1.0.1"
set "DOWNLOAD_URL=https://github.com/jzkanq/jzlite-downloads/releases/download/v%VERSION%/JZLite-%VERSION%-UNSIGNED-EXPERIMENTAL.tgz"
set "EXPECTED_SHA256=3a19bb5f365334f9daa615193c8ece4a28e7cd33dac748bdc0e4299ed3de87f0"
set "INSTALL_FOLDER=%USERPROFILE%\Downloads\JZLite-%VERSION%"
set "ARCHIVE=%INSTALL_FOLDER%\JZLite.tgz"
set "MODE=%~1"
if not defined MODE goto mode_ok

if /i "%MODE%"=="--clean-install" goto mode_ok
if /i "%MODE%"=="--install-persistent" goto mode_ok
if /i "%MODE%"=="--migrate-xlite" goto mode_ok
if /i "%MODE%"=="--upgrade-persistent" goto mode_ok
if /i "%MODE%"=="--uninstall" goto mode_ok
goto usage

:mode_ok
if not "%~2"=="" (
  echo ERROR: Choose exactly one installation mode.
  goto usage
)

echo.
echo JZLite %VERSION% - unsigned experimental installer
echo ==================================================
if defined MODE (
  echo Mode: %MODE%
) else (
  echo Mode: choose from the setup menu after verification
)
echo The archive will be verified before execution.
echo.

where curl.exe >nul 2>&1 || (
  echo ERROR: curl.exe was not found.
  exit /b 1
)
where tar.exe >nul 2>&1 || (
  echo ERROR: tar.exe was not found.
  exit /b 1
)
where powershell.exe >nul 2>&1 || (
  echo ERROR: powershell.exe was not found.
  exit /b 1
)

if exist "%INSTALL_FOLDER%" (
  echo ERROR: Delete the old "%INSTALL_FOLDER%" folder first, then try again.
  exit /b 1
)
mkdir "%INSTALL_FOLDER%" >nul 2>&1 || (
  echo ERROR: Could not create "%INSTALL_FOLDER%".
  exit /b 1
)

echo Downloading release archive...
curl.exe --fail --location --retry 3 --retry-delay 2 --proto "=https" --tlsv1.2 --output "%ARCHIVE%" "%DOWNLOAD_URL%"
if errorlevel 1 (
  echo ERROR: Download failed.
  exit /b 1
)

echo Verifying SHA-256...
set "ACTUAL_SHA256="
for /f "usebackq tokens=1" %%H in (`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "(Get-FileHash -LiteralPath '%ARCHIVE%' -Algorithm SHA256).Hash.ToLowerInvariant()"`) do set "ACTUAL_SHA256=%%H"
if /i not "%ACTUAL_SHA256%"=="%EXPECTED_SHA256%" (
  echo ERROR: SHA-256 checksum mismatch. Do not run this download.
  echo Expected: %EXPECTED_SHA256%
  echo Actual:   %ACTUAL_SHA256%
  exit /b 1
)

echo Extracting archive...
tar.exe -xzf "%ARCHIVE%" -C "%INSTALL_FOLDER%"
if errorlevel 1 (
  echo ERROR: Archive extraction failed.
  exit /b 1
)
if not exist "%INSTALL_FOLDER%\Install-JZLite.bat" (
  echo ERROR: Install-JZLite.bat is missing from the verified archive.
  exit /b 1
)
if not exist "%INSTALL_FOLDER%\Verify-JZLite.ps1" (
  echo ERROR: Verify-JZLite.ps1 is missing from the verified archive.
  exit /b 1
)

echo Verifying files inside the archive...
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%INSTALL_FOLDER%\Verify-JZLite.ps1" -ExtractedFolder "%INSTALL_FOLDER%" -AllowUnsignedExperimental
if errorlevel 1 (
  echo ERROR: Internal release verification failed. Do not run this download.
  exit /b 1
)

pushd "%INSTALL_FOLDER%"
if defined MODE (
  call ".\Install-JZLite.bat" %MODE%
) else (
  call ".\Install-JZLite.bat"
)
set "INSTALL_EXIT=%ERRORLEVEL%"
popd
exit /b %INSTALL_EXIT%

:usage
echo Usage: installer.bat [mode]
echo.
echo   --clean-install
echo   --install-persistent
echo   --migrate-xlite
echo   --upgrade-persistent
echo   --uninstall
exit /b 2
