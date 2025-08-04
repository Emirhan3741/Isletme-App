@echo off
cls
color 0B
echo ===============================================================
echo  📦 LOCAPO - DEPLOYMENT SCRIPT'İ
echo ===============================================================
echo.

if not exist "pubspec.yaml" (
    echo ❌ pubspec.yaml bulunamadı!
    pause
    exit /b 1
)

:menu
echo 🚀 DEPLOYMENT SEÇENEKLERI:
echo.
echo [1] Web Build (Production)
echo [2] Android APK Build
echo [3] Android App Bundle (AAB)
echo [4] iOS Build (Simulator)
echo [5] Windows Desktop Build
echo [6] Web Build + Firebase Deploy
echo [7] All Platforms Build
echo [8] Build Size Analysis
echo [0] Çıkış
echo.

set /p choice="Seçiminiz [1-8, 0]: "

if "%choice%"=="1" goto web_build
if "%choice%"=="2" goto android_apk
if "%choice%"=="3" goto android_aab
if "%choice%"=="4" goto ios_build
if "%choice%"=="5" goto windows_build
if "%choice%"=="6" goto web_deploy
if "%choice%"=="7" goto all_builds
if "%choice%"=="8" goto size_analysis
if "%choice%"=="0" goto end
goto menu

:web_build
echo.
echo 🌐 Web production build başlatılıyor...
call flutter clean
call flutter pub get
call flutter build web --release --web-renderer html
if errorlevel 1 (
    echo ❌ Web build başarısız!
) else (
    echo ✅ Web build tamamlandı: build\web\
    echo 📋 Dosyalar:
    dir build\web\ /B
)
echo.
pause
goto menu

:android_apk
echo.
echo 📱 Android APK build başlatılıyor...
call flutter clean
call flutter pub get
call flutter build apk --release
if errorlevel 1 (
    echo ❌ Android APK build başarısız!
) else (
    echo ✅ Android APK tamamlandı: build\app\outputs\flutter-apk\
    dir build\app\outputs\flutter-apk\ /B
)
echo.
pause
goto menu

:android_aab
echo.
echo 📱 Android App Bundle build başlatılıyor...
call flutter clean
call flutter pub get
call flutter build appbundle --release
if errorlevel 1 (
    echo ❌ Android AAB build başarısız!
) else (
    echo ✅ Android AAB tamamlandı: build\app\outputs\bundle\release\
)
echo.
pause
goto menu

:ios_build
echo.
echo 🍎 iOS build başlatılıyor...
call flutter clean
call flutter pub get
call flutter build ios --release --no-codesign
if errorlevel 1 (
    echo ❌ iOS build başarısız!
) else (
    echo ✅ iOS build tamamlandı
)
echo.
pause
goto menu

:windows_build
echo.
echo 🖥️ Windows Desktop build başlatılıyor...
call flutter clean
call flutter pub get
call flutter build windows --release
if errorlevel 1 (
    echo ❌ Windows build başarısız!
) else (
    echo ✅ Windows build tamamlandı: build\windows\runner\Release\
)
echo.
pause
goto menu

:web_deploy
echo.
echo 🌐 Web build + Firebase deploy...
call flutter clean
call flutter pub get
call flutter build web --release --web-renderer html
if errorlevel 1 (
    echo ❌ Web build başarısız!
    pause
    goto menu
)

echo 🔥 Firebase deploy başlatılıyor...
call firebase deploy --only hosting
if errorlevel 1 (
    echo ❌ Firebase deploy başarısız!
) else (
    echo ✅ Firebase deploy tamamlandı!
)
echo.
pause
goto menu

:all_builds
echo.
echo 🏗️ Tüm platformlar için build...
echo.

echo [1/4] Web build...
call flutter build web --release --web-renderer html

echo [2/4] Android APK build...
call flutter build apk --release

echo [3/4] Android AAB build...
call flutter build appbundle --release

echo [4/4] Windows build...
call flutter build windows --release

echo.
echo ✅ Tüm build'ler tamamlandı!
echo.
echo 📋 Build Dosyaları:
echo    Web: build\web\
echo    Android APK: build\app\outputs\flutter-apk\
echo    Android AAB: build\app\outputs\bundle\release\
echo    Windows: build\windows\runner\Release\
echo.
pause
goto menu

:size_analysis
echo.
echo 📊 Build boyut analizi...
call flutter build web --analyze-size
echo.
call flutter build apk --analyze-size
echo.
pause
goto menu

:end
echo.
echo 👋 Deployment script'i kapatılıyor...
pause