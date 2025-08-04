@echo off
chcp 65001 > nul
cls

echo.
echo 🚀 RANDEVU ERP - PRODUCTION DEPLOY 🚀
echo ====================================
echo.

:: 🔍 Gereksinimler kontrol
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter kurulu değil!
    pause
    exit /b 1
)

where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo ⚠️  Firebase CLI kurulu değil!
    echo 💡 Firebase CLI kurmak için: npm install -g firebase-tools
    echo 💡 Şimdilik sadece web build yapılacak...
    set FIREBASE_AVAILABLE=false
) else (
    set FIREBASE_AVAILABLE=true
)

if not exist "pubspec.yaml" (
    echo ❌ pubspec.yaml bulunamadı!
    pause
    exit /b 1
)

echo 🎯 PRODUCTION DEPLOY SEÇENEKLERİ:
echo.
echo [1] 🌐 Web Build (Firebase Ready)
echo [2] 📱 Android APK
echo [3] 📦 Android AAB (Play Store)
echo [4] 🔥 Firebase Deploy (Web)
echo [5] 📊 Full Deploy (Web + Android)
echo [0] ❌ Çıkış
echo.

set /p choice="Seçiminizi yapın (1-5): "

if "%choice%"=="1" goto web_build
if "%choice%"=="2" goto android_apk
if "%choice%"=="3" goto android_aab
if "%choice%"=="4" goto firebase_deploy
if "%choice%"=="5" goto full_deploy
if "%choice%"=="0" goto exit
goto invalid_choice

:web_build
echo.
echo 🌐 Web Production Build...
echo.

echo 🧹 Temizlik yapılıyor...
call flutter clean

echo 📦 Paketler yükleniyor...
call flutter pub get

echo 🔨 Web build yapılıyor...
call flutter build web --release --web-renderer html

if %errorlevel% equ 0 (
    echo ✅ Web build başarılı!
    echo 📁 Build dosyaları: build/web/
    
    :: Firebase config ekle
    if exist "web/firebase-config.js" (
        copy "web/firebase-config.js" "build/web/firebase-config.js"
        echo ✅ Firebase config kopyalandı
    )
    
    :: Service worker ekle
    if exist "web/firebase-messaging-sw.js" (
        copy "web/firebase-messaging-sw.js" "build/web/firebase-messaging-sw.js"
        echo ✅ Service worker kopyalandı
    )
    
    echo.
    echo 🎉 Web build tamamlandı!
    echo 📂 Dosyalar: build/web/
    echo 🌐 Test için: build/web/index.html
) else (
    echo ❌ Web build başarısız!
)
pause
goto end

:android_apk
echo.
echo 📱 Android APK Build...
echo.

call flutter clean
call flutter pub get

echo 🔨 Android APK yapılıyor...
call flutter build apk --release 

if %errorlevel% equ 0 (
    echo ✅ Android APK başarılı!
    echo 📁 APK dosyası: build/app/outputs/flutter-apk/app-release.apk
    
    :: APK boyutunu göster
    if exist "build/app/outputs/flutter-apk/app-release.apk" (
        for %%A in (build/app/outputs/flutter-apk/app-release.apk) do echo 📊 APK boyutu: %%~zA bytes
    )
) else (
    echo ❌ Android APK build başarısız!
)
pause
goto end

:android_aab
echo.
echo 📦 Android AAB (Play Store) Build...
echo.

call flutter clean
call flutter pub get

echo 🔨 Android AAB yapılıyor...
call flutter build appbundle --release 

if %errorlevel% equ 0 (
    echo ✅ Android AAB başarılı!
    echo 📁 AAB dosyası: build/app/outputs/bundle/release/app-release.aab
    echo 📤 Google Play Console'a yükleyebilirsiniz!
) else (
    echo ❌ Android AAB build başarısız!
)
pause
goto end

:firebase_deploy
if "%FIREBASE_AVAILABLE%"=="false" (
    echo ❌ Firebase CLI kurulu değil!
    echo 💡 npm install -g firebase-tools
    pause
    goto end
)

echo.
echo 🔥 Firebase Deploy...
echo.

:: Önce web build yap
call :web_build_silent

if %errorlevel% equ 0 (
    echo 🔥 Firebase'e deploy ediliyor...
    call firebase deploy --only hosting
    
    if %errorlevel% equ 0 (
        echo ✅ Firebase deploy başarılı!
        echo 🌐 Uygulamanız yayında!
    ) else (
        echo ❌ Firebase deploy başarısız!
        echo 💡 firebase login yapıp tekrar deneyin
    )
) else (
    echo ❌ Web build başarısız, deploy yapılamıyor!
)
pause
goto end

:full_deploy
echo.
echo 📊 FULL DEPLOY - Tüm platformlar...
echo.

:: Web build
echo 🌐 1/3 - Web build...
call :web_build_silent

:: Android APK
echo 📱 2/3 - Android APK...
call flutter build apk --release  > nul

:: Android AAB  
echo 📦 3/3 - Android AAB...
call flutter build appbundle --release  > nul

echo.
echo 🎉 FULL DEPLOY TAMAMLANDI!
echo.
echo 📁 ÇIKTILER:
echo    🌐 Web: build/web/
echo    📱 APK: build/app/outputs/flutter-apk/app-release.apk
echo    📦 AAB: build/app/outputs/bundle/release/app-release.aab
echo.

if "%FIREBASE_AVAILABLE%"=="true" (
    echo 🔥 Firebase deploy yapmak istiyor musunuz? (y/n)
    set /p firebase_choice=""
    if /i "%firebase_choice%"=="y" (
        call firebase deploy --only hosting
    )
)

pause
goto end

:web_build_silent
call flutter clean > nul
call flutter pub get > nul
call flutter build web --release  > nul
exit /b %errorlevel%

:invalid_choice
echo ❌ Geçersiz seçim!
pause
goto start

:exit
echo 👋 Çıkılıyor...
exit /b 0

:end
echo.
echo ✨ Deploy işlemi tamamlandı!
pause

:start
cls
goto :eof