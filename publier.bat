@echo off
cd /d "%~dp0"
echo === Envoi des changements vers GitHub ===
echo.

git add -A

set "msg="
set /p msg="Decris ta modif en une phrase (ou laisse vide) : "
if "%msg%"=="" set "msg=Mise a jour"

git commit -m "%msg%"
if errorlevel 1 (
    echo.
    echo Rien a envoyer : aucun fichier modifie depuis le dernier envoi.
    echo.
    pause
    exit /b
)

git push

echo.
echo === Termine ===
echo Vercel va redeployer automatiquement le site dans les prochaines minutes.
echo.
pause
