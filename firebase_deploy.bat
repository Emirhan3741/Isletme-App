@echo off
echo.
echo =========================================
echo    Firebase Randevu ERP Deployment
echo =========================================
echo.

REM Firebase CLI kurulu mu kontrol et
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI bulunamadi!
    echo 💡 Kurulum: npm install -g firebase-tools
    echo 🔗 Daha fazla bilgi: https://firebase.google.com/docs/cli
    pause
    exit /b 1
)

echo ✅ Firebase CLI bulundu
echo.

REM Firebase'e giriş kontrolü
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔑 Firebase'e giriş yapılıyor...
    firebase login
    if %errorlevel% neq 0 (
        echo ❌ Firebase giriş başarısız!
        pause
        exit /b 1
    )
)

echo ✅ Firebase authenticated
echo.

REM Proje seçimi
echo 🎯 Firebase projesi: randevu-takip-app
firebase use randevu-takip-app
if %errorlevel% neq 0 (
    echo ❌ Proje seçimi başarısız!
    echo 💡 firebase projects:list komutu ile mevcut projeleri görebilirsiniz
    pause
    exit /b 1
)

echo.
echo 📋 Deployment Seçenekleri:
echo [1] Sadece Firestore Rules
echo [2] Sadece Storage Rules  
echo [3] Sadece Indexes
echo [4] Tümü (Rules + Indexes)
echo [5] İptal
echo.

set /p choice="Seçiminizi yapın (1-5): "

if "%choice%"=="1" goto deploy_firestore
if "%choice%"=="2" goto deploy_storage
if "%choice%"=="3" goto deploy_indexes
if "%choice%"=="4" goto deploy_all
if "%choice%"=="5" goto end
echo ❌ Geçersiz seçim!
pause
exit /b 1

:deploy_firestore
echo.
echo 🔧 Firestore Rules deploy ediliyor...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ❌ Firestore Rules deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Firestore Rules başarıyla deploy edildi!
goto success

:deploy_storage
echo.
echo 📦 Storage Rules deploy ediliyor...
firebase deploy --only storage
if %errorlevel% neq 0 (
    echo ❌ Storage Rules deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Storage Rules başarıyla deploy edildi!
goto success

:deploy_indexes
echo.
echo 🔍 Firestore Indexes deploy ediliyor...
firebase deploy --only firestore:indexes
if %errorlevel% neq 0 (
    echo ❌ Indexes deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Indexes başarıyla deploy edildi!
echo ⏰ Index'ler oluşturulması 2-3 dakika sürebilir
goto success

:deploy_all
echo.
echo 🚀 Tüm Firebase konfigürasyonu deploy ediliyor...
echo.
echo 1/3 Firestore Rules...
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ❌ Firestore Rules deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Firestore Rules OK

echo.
echo 2/3 Storage Rules...
firebase deploy --only storage
if %errorlevel% neq 0 (
    echo ❌ Storage Rules deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Storage Rules OK

echo.
echo 3/3 Firestore Indexes...
firebase deploy --only firestore:indexes
if %errorlevel% neq 0 (
    echo ❌ Indexes deployment başarısız!
    pause
    exit /b 1
)
echo ✅ Indexes OK

:success
echo.
echo =========================================
echo           🎉 DEPLOYMENT TAMAMLANDI!
echo =========================================
echo.
echo 📋 Sonraki Adımlar:
echo   1. Firebase Console'da VAPID Key'i ekleyin:
echo      - Project Settings ^> Cloud Messaging ^> Web Push Certificates
echo      - Generate new keypair 
echo      - Key'i lib/firebase_options.dart'a ekleyin
echo.
echo   2. Index'ler oluşturulması 2-3 dakika sürer
echo   3. Test için uygulamayı yeniden başlatın
echo   4. Hata varsa console log'larını kontrol edin
echo.
echo 🔗 Firebase Console: https://console.firebase.google.com/project/randevu-takip-app
echo.
pause
goto end

:end
echo Çıkış yapılıyor...