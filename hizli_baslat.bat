@echo off
chcp 65001 > nul
cls

echo.
echo ⚡ RANDEVU ERP - HIZLI BAŞLATICI ⚡
echo =====================================
echo.

:: 🔍 Flutter kurulu mu kontrol et
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter kurulu değil!
    echo 💡 Flutter'ı kurmak için: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

:: 📁 Doğru dizinde mi kontrol et
if not exist "pubspec.yaml" (
    echo ❌ pubspec.yaml bulunamadı!
    echo 💡 Bu dosyayı proje kök dizininde çalıştırın
    pause
    exit /b 1
)

echo 🔧 Paketler kontrol ediliyor...
call flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo ❌ Paket yükleme başarısız!
    echo 💡 İnternet bağlantınızı kontrol edin
    pause
    exit /b 1
)

echo.
echo ✅ Paketler başarıyla yüklendi
echo.

:: 🌐 Web için build
echo 🔨 Web için build yapılıyor...
call flutter build web --release --no-sound-null-safety
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  Build başarısız, ama development modunda çalıştırmaya devam...
    echo.
)

:: 🚀 Projeyi başlat
echo.
echo 🚀 Proje başlatılıyor...
echo 📱 Tarayıcı otomatik açılacak: http://localhost:3000
echo.
echo 🔹 ÖZELLIKLER:
echo    • 🏠 Ana Sayfa: /public/home
echo    • 💼 ERP Dashboard: /login sonrası
echo    • 🤖 AI Chatbox: Tüm sayfalarda aktif
echo    • 👨‍💼 Admin Panel: /admin-ai-chat
echo.
echo 🛑 Durdurmak için: Ctrl+C
echo.

start "" "http://localhost:3000/public/home"

call flutter run -d chrome --web-port 3000
if %errorlevel% neq 0 (
    echo.
    echo ❌ Başlatma başarısız!
    echo 💡 Aşağıdaki adımları deneyin:
    echo    1. flutter clean
    echo    2. flutter pub get
    echo    3. Tekrar çalıştırın
    echo.
    pause
)

echo.
echo 👋 Proje kapatıldı
pause