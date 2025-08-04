@echo off
chcp 65001 >nul
title FIRESTORE INDEX DEPLOYMENT
color 0A

echo.
echo ================================
echo   🔥 FIRESTORE INDEX DEPLOY
echo ================================
echo.

:: Proje kök dizinine git
cd /d "%~dp0.."
echo ✅ Proje dizini: %cd%
echo.

:: Firebase CLI kontrol
echo 🔍 Firebase CLI kontrol ediliyor...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI bulunamadı!
    echo 💡 Firebase CLI kurulum için: npm install -g firebase-tools
    pause
    exit /b 1
)
echo ✅ Firebase CLI hazır
echo.

:: Firebase login kontrol
echo 🔐 Firebase giriş kontrol ediliyor...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Firebase girişi gerekli
    echo 🔗 Giriş yapılıyor...
    firebase login
    if %errorlevel% neq 0 (
        echo ❌ Firebase giriş başarısız!
        pause
        exit /b 1
    )
)
echo ✅ Firebase girişi onaylandı
echo.

:: firestore.indexes.json varsa dağıt
if exist "firestore.indexes.json" (
    echo 📋 Firestore index'leri dağıtılıyor...
    firebase deploy --only firestore:indexes
    if %errorlevel% equ 0 (
        echo ✅ Index'ler başarıyla dağıtıldı!
    ) else (
        echo ❌ Index dağıtımı başarısız!
    )
) else (
    echo ⚠️ firestore.indexes.json bulunamadı
    echo 💡 Index'leri manuel oluşturmanız gerekiyor
)
echo.

:: firestore.rules varsa dağıt
if exist "firestore.rules" (
    echo 🔒 Firestore kuralları dağıtılıyor...
    firebase deploy --only firestore:rules
    if %errorlevel% equ 0 (
        echo ✅ Kurallar başarıyla dağıtıldı!
    ) else (
        echo ❌ Kural dağıtımı başarısız!
    )
) else (
    echo ⚠️ firestore.rules bulunamadı
)
echo.

echo ================================
echo   🎉 DEPLOYMENT TAMAMLANDI
echo ================================
echo.
echo 💡 Şimdi uygulamanızı test edebilirsiniz:
echo    flutter run -d chrome
echo.
pause