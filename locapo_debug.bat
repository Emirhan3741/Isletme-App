@echo off
chcp 65001 >nul
title LOCAPO ERP - Debug & Analiz
color 0C

echo.
echo ================================
echo    🔍 LOCAPO ERP DEBUG MODU     
echo ================================
echo.

cd /d "C:\Projects\locapo"
if %errorlevel% neq 0 (
    echo ❌ Proje dizini bulunamadı!
    pause
    exit /b 1
)

echo 📂 Çalışma dizini: %cd%
echo.

echo 🔍 Flutter analiz...
flutter analyze
echo.

echo 🔍 Flutter doktor...
flutter doctor -v
echo.

echo 🔍 Pub dependencies...
flutter pub deps
echo.

echo 🔍 Mevcut cihazlar...
flutter devices
echo.

echo ================================
echo      📊 DEBUG RAPORU HAZIR      
echo ================================
echo.
echo 💡 İsterseniz şimdi debug modda başlatabilirsiniz:
echo    flutter run -d chrome --debug
echo.

pause