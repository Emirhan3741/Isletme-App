@echo off
chcp 65001 >nul
title RANDEVU ERP - Developer Mode
color 0A

echo.
echo ================================
echo   🚀 RANDEVU ERP DEV SERVER     
echo ================================
echo.

:: Proje kök dizinine git
cd /d "%~dp0.."
echo ✅ Proje dizini: %cd%
echo.

:: Temizlik
echo 🧹 Flutter temizleniyor...
call flutter clean
if %errorlevel% neq 0 (
    echo ❌ Flutter clean hatası!
    pause
    exit /b 1
)

:: Paketleri çek
echo 📦 Paketler güncelleniyor...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Pub get hatası!
    pause
    exit /b 1
)

echo.
echo 🌐 Web server başlatılıyor...
echo 📡 URL: http://localhost:3000
echo 💡 Chrome tarayıcısında açılacak
echo.
echo 🤖 YENİ: AI Chatbox entegrasyonu tamamlandı!
echo 📱 Tüm dashboard'larda sağ alt köşede chat butonu
echo 👨‍💼 Admin chat takibi: /admin-ai-chat
echo.
echo ⚠️  UYARI: Compile hataları var - önce onları düzeltin!
echo.

:: Web başlatma
call flutter run -d chrome --web-port 3000
if %errorlevel% neq 0 (
    echo.
    echo ❌ Başlatma başarısız!
    echo 💡 Önce compile hatalarını düzeltin.
    echo.
)

echo.
echo ✅ İşlem tamamlandı.
pause