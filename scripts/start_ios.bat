@echo off
chcp 65001 >nul
title RANDEVU ERP - iOS Dev
color 0D

echo.
echo ================================
echo   🍎 RANDEVU ERP iOS DEV        
echo ================================
echo.

:: Proje kök dizinine git
cd /d "%~dp0.."
echo ✅ Proje dizini: %cd%
echo.

:: iOS cihazları kontrol et
echo 🔍 iOS cihazları kontrol ediliyor...
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
echo 🍎 iOS'ta başlatılıyor...
echo ⚠️  UYARI: Compile hataları var - önce onları düzeltin!
echo ⚠️  UYARI: iOS geliştirme macOS gerektirir!
echo.

:: iOS başlatma
call flutter run -d ios
if %errorlevel% neq 0 (
    echo.
    echo ❌ Başlatma başarısız!
    echo 💡 macOS ve iOS Simulator gerekli.
    echo.
)

echo.
echo ✅ İşlem tamamlandı.
pause