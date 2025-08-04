@echo off
chcp 65001 >nul
title LOCAPO ERP - Flutter Web Başlatıcı
color 0A

echo.
echo ================================
echo     🚀 LOCAPO ERP BAŞLATICI     
echo ================================
echo.
echo 📍 Proje Dizini: C:\Projects\locapo
echo 📅 Güncelleme: %date% %time%
echo.

:: Proje dizinine git
cd /d "C:\Projects\locapo"
if %errorlevel% neq 0 (
    echo ❌ HATA: Proje dizini bulunamadı!
    echo 📂 Beklenen: C:\Projects\locapo
    pause
    exit /b 1
)

echo ✅ Proje dizininde: %cd%
echo.

:: Flutter sürümünü kontrol et
echo 🔍 Flutter sürümü kontrol ediliyor...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ HATA: Flutter bulunamadı! PATH kontrolü gerekli.
    pause
    exit /b 1
)
echo.

:: Chrome kontrolü
echo 🌐 Chrome kontrolü...
where chrome >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Chrome bulunamadı, varsayılan tarayıcı kullanılacak
) else (
    echo ✅ Chrome bulundu
)
echo.

:: Packages güncelle
echo 📦 Dependencies güncelleniyor...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ HATA: pub get başarısız!
    pause
    exit /b 1
)
echo ✅ Dependencies güncellendi
echo.

:: Build cache temizle (opsiyonel)
echo 🧹 Build cache temizleniyor...
flutter clean
flutter pub get
echo ✅ Cache temizlendi
echo.

:: Web desteği kontrol et
echo 🔧 Flutter web desteği kontrol ediliyor...
flutter config --enable-web
echo ✅ Web desteği aktif
echo.

:: Ana dosyaları kontrol et
echo 📄 Ana dosyalar kontrol ediliyor...
if not exist "lib\main.dart" (
    echo ❌ HATA: lib\main.dart bulunamadı!
    pause
    exit /b 1
)
if not exist "web\index.html" (
    echo ❌ HATA: web\index.html bulunamadı!
    pause
    exit /b 1
)
echo ✅ Ana dosyalar mevcut
echo.

:: Firebase config kontrol et
if exist "web\firebase-config.js" (
    echo ✅ Firebase config bulundu
) else (
    echo ⚠️  Firebase config bulunamadı (web\firebase-config.js)
)
echo.

:: Google services kontrol et
if exist "web\google-services.json" (
    echo ✅ Google services config bulundu
) else (
    echo ⚠️  Google services config bulunamadı
)
echo.

echo ================================
echo      🚀 UYGULAMA BAŞLATILIYOR     
echo ================================
echo.
echo 🌐 Tarayıcı açılacak: Chrome
echo 🔧 Mod: Debug
echo 📱 Platform: Web
echo.
echo ⏳ Lütfen bekleyin...
echo.

:: Flutter web uygulamasını başlat
flutter run -d chrome --web-port=8080 --web-hostname=localhost
if %errorlevel% neq 0 (
    echo.
    echo ❌ UYGULAMA BAŞLATMA HATASI!
    echo.
    echo 🔍 Muhtemel nedenler:
    echo    - Chrome bulunamadı
    echo    - Port 8080 kullanımda
    echo    - Compile hataları
    echo    - Firebase config eksik
    echo.
    echo 💡 Çözüm önerileri:
    echo    1. Chrome yüklü mü kontrol edin
    echo    2. Port 8080'i kullanan programı kapatın
    echo    3. flutter analyze komutu çalıştırın
    echo    4. Firebase config dosyalarını kontrol edin
    echo.
) else (
    echo.
    echo ✅ UYGULAMA BAŞARILI BİR ŞEKİLDE BAŞLATILDI!
    echo 🌐 URL: http://localhost:8080
    echo.
)

echo.
echo ================================
echo Press any key to exit...
pause >nul