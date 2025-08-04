@echo off
chcp 65001 >nul
title RANDEVU ERP - Android Dev
color 0C

echo.
echo ================================
echo   📱 RANDEVU ERP ANDROID DEV     
echo ================================
echo.

:: Proje kök dizinine git
cd /d "%~dp0.."
echo ✅ Proje dizini: %cd%
echo.

:: Android cihazları kontrol et
echo 🔍 Android cihazları kontrol ediliyor...
call flutter devices
echo.

:: Paketleri çek
echo 📦 Paketler güncelleniyor...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Pub get hatası!
    pause
    exit /b 1
)

echo.
echo 📱 Android'de başlatılıyor...
echo ⚠️  UYARI: Compile hataları var - önce onları düzeltin!
echo.

:: Android başlatma
call flutter run
if %errorlevel% neq 0 (
    echo.
    echo ❌ Başlatma başarısız!
    echo 💡 Android cihaz/emulator bağlı olduğundan emin olun.
    echo.
)

echo.
echo ✅ İşlem tamamlandı.
pause