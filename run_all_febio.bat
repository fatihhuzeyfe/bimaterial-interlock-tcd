@echo off
setlocal enabledelayedexpansion
rem ============================================================
rem  Runs every *.feb in this folder with FEBio (AM_* production, ML_* surrogate).
rem  - finds febio3.exe automatically (or set FEBIO below)
rem  - skips models that already terminated normally
rem  - writes febio_run_log.txt and failed_models.txt
rem ============================================================
cd /d "%~dp0"

rem ---- If auto-detection fails, write the full path here, e.g.
rem set "FEBIO=C:\Program Files\FEBioStudio\bin\febio4.exe"
set "FEBIO="

rem Look for the command-line solver (febio5/febio4/febio3.exe), NOT FEBioStudio.exe
for %%D in ("C:\Program Files\FEBioStudio\bin" "C:\Program Files\FEBio Studio\bin" "C:\Program Files\FEBioStudio2\bin" "C:\Program Files\FEBio4\bin" "C:\Program Files\FEBio3.2\bin" "C:\Program Files\FEBio3\bin") do (
    for %%E in (febio5.exe febio4.exe febio3.exe) do (
        if not defined FEBIO if exist "%%~D\%%E" set "FEBIO=%%~D\%%E"
    )
)
for %%E in (febio5.exe febio4.exe febio3.exe) do (
    if not defined FEBIO for /f "delims=" %%W in ('where %%E 2^>nul') do if not defined FEBIO set "FEBIO=%%W"
)
echo "%FEBIO%" | findstr /i "FEBioStudio.exe" >nul && (
    echo.
    echo  FEBIO degiskeni FEBioStudio.exe'yi gosteriyor. Bu arayuz programidir, cozucu degildir.
    echo  Ayni klasordeki febio4.exe / febio5.exe / febio3.exe dosyasinin yolunu yazin.
    echo.
    pause
    exit /b 1
)
if not defined FEBIO (
    echo.
    echo  Komut satiri cozucusu ^(febio4.exe / febio5.exe / febio3.exe^) bulunamadi.
    echo  Bu dosyayi Not Defteri ile acip "set FEBIO=" satirina tam yolunu yazin.
    echo.
    pause
    exit /b 1
)
echo FEBio: "%FEBIO%"
echo.

set /a n=0, done=0, fail=0
for %%F in (*.feb) do set /a n+=1
set /a i=0
for %%F in (*.feb) do (
    set /a i+=1
    set "ok="
    if exist "%%~nF.log" findstr /c:"N O R M A L" "%%~nF.log" >nul 2>&1 && set "ok=1"
    if defined ok (
        echo [!i!/!n!] zaten cozulmus: %%~nF
    ) else (
        echo [!i!/!n!] cozuluyor: %%~nF
        "%FEBIO%" -i "%%F" >> febio_run_log.txt 2>&1
        findstr /c:"N O R M A L" "%%~nF.log" >nul 2>&1 && (set /a done+=1) || (
            set /a fail+=1
            echo %%~nF>> failed_models.txt
            echo         HATA - failed_models.txt dosyasina yazildi
        )
    )
)
echo.
echo Bitti. Yeni cozulen: %done%   Hatali: %fail%
pause
