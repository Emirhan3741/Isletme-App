@echo off
chcp 65001 > nul
cls

echo.
echo 🚀 RANDEVU ERP - GELİŞTİRİCİ BAŞLATICI 🚀
echo ==========================================
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

echo 🎯 BAŞLATMA SEÇENEKLERİ:
echo.
echo [1] 🌐 Web (Chrome) - Port 3000
echo [2] 📱 Android Emulator
echo [3] 🔧 Debug Mode (VS Code)
echo [4] 🧹 Clean + Rebuild
echo [5] 📦 Paket Güncelle
echo [6] 🚀 Production Build
echo [7] 🔍 Kod Analizi
echo [0] ❌ Çıkış
echo.

set /p choice="Seçiminizi yapın (1-7): "

if "%choice%"=="1" goto web_start
if "%choice%"=="2" goto android_start
if "%choice%"=="3" goto debug_start
if "%choice%"=="4" goto clean_rebuild
if "%choice%"=="5" goto update_packages
if "%choice%"=="6" goto production_build
if "%choice%"=="7" goto code_analysis
if "%choice%"=="0" goto exit
goto invalid_choice

:web_start
echo.
echo 🌐 Web için başlatılıyor...
echo 📱 Tarayıcı otomatik açılacak: http://localhost:3000
echo.

call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Paket yükleme başarısız!
    pause
    exit /b 1
)

start "" "http://localhost:3000/public/home"
call flutter run -d chrome --web-port 3000
goto end

:android_start
echo.
echo 📱 Android için başlatılıyor...
echo.

call flutter pub get
call flutter run
goto end

:debug_start
echo.
echo 🔧 Debug mode başlatılıyor...
echo 💡 VS Code'dan F5 ile debug yapabilirsiniz
echo.

call flutter pub get
call flutter run --debug
goto end

:clean_rebuild
echo.
echo 🧹 Temizlik ve yeniden build...
echo.

call flutter clean
call flutter pub get
call flutter pub upgrade
echo ✅ Temizlik tamamlandı!
pause
goto start

:update_packages
echo.
echo 📦 Paketler güncelleniyor...
echo.

call flutter pub upgrade
call flutter pub get
echo ✅ Paket güncellemesi tamamlandı!
pause
goto start

:production_build
echo.
echo 🚀 Production build yapılıyor...
echo.

call flutter clean
call flutter pub get
call flutter build web --release

if %errorlevel% equ 0 (
    echo ✅ Production build başarılı!
    echo 📁 Build dosyaları: build/web/
    if exist "build/web/index.html" (
        echo 🌐 Test için: build/web/index.html açın
    )
) else (
    echo ❌ Production build başarısız!
)
pause
goto start

:code_analysis
echo.
echo 🔍 Kod analizi yapılıyor...
echo.

call flutter analyze
call flutter test
echo ✅ Kod analizi tamamlandı!
pause
goto start

:invalid_choice
echo.
echo ❌ Geçersiz seçim! Lütfen 1-7 arası bir sayı girin.
pause
goto start

:exit
echo.
echo 👋 Çıkılıyor...
exit /b 0

:end
echo.
echo 👋 Proje kapatıldı
pause

:start
cls
goto :eof