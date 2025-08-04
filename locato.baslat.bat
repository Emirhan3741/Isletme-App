@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   RANDEVU ERP FLUTTER WEB STARTER v3.0
echo ========================================
echo.
echo 🔧 Sistem kontrolleri yapılıyor...

REM Flutter versiyonu kontrol et
flutter --version | findstr "Flutter" > nul
if errorlevel 1 (
    echo ❌ Flutter bulunamadı! Lütfen Flutter'ı yükleyin.
    pause
    exit /b 1
)

echo ✅ Flutter bulundu
echo.

REM Projeyi temizle
echo 🧹 Flutter cache ve build dosyaları temizleniyor...
call flutter clean
if errorlevel 1 (
    echo ⚠️ Flutter clean başarısız, devam ediliyor...
)

echo.
echo 📦 Dependency çakışmaları çözülüyor...
call flutter pub add timezone:^0.9.4

echo.
echo 📦 Bağımlılıklar yükleniyor...
call flutter pub get
if errorlevel 1 (
    echo ❌ Pub get başarısız! Paket sorunları var.
    pause
    exit /b 1
)

echo ✅ Bağımlılıklar yüklendi
echo.

echo 🔧 Build runner çalıştırılıyor...
call flutter packages pub run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo ⚠️ Build runner sorunlu, devam ediliyor...
)

echo.
echo 🌐 Web için Chrome'da başlatılıyor...
echo 📡 URL: http://localhost:3000
echo.
echo ✨ YENİ ÖZELLIKLER (v3.0):
echo    🔐 Google Sign-In API v7+ uyumlu
echo    🔑 VAPID Key: BJ7LMlB1LNtAVtiqk5C_nvzANRpKoLgncFChYu36X3NeClE0H-EcINhS9MFTCSuNanHkitPwdMUI7uX_cEk4Xno
echo    🎯 Multi-sektör dashboard sistemi
echo    📊 Unified calendar sistem  
echo    🔔 FCM push notification sistemi
echo    📄 Gelişmiş belge yönetimi
echo    🛡️ Firestore güvenlik kuralları
echo.
echo 🚨 SORUN GIDERME v3.0:
echo    • Firestore Index hatası → FIRESTORE_INDEX_URLS.md linklerini açın
echo    • GoogleSignIn v7+ hatası → Düzeltildi (idToken only)
echo    • CORS hatası → apply_cors.bat çalıştırın
echo    • VAPID Key test → F12 Console'da FCM token kontrolü
echo    • CustomerId hatası → Düzeltildi (placeholder values)
echo    • AppConstants hatası → Düzeltildi (tüm collections eklendi)
echo.
echo ⏳ Tarayıcı açılacak, lütfen bekleyin...
echo.

REM Chrome'da web uygulamasını başlat
call flutter run -d chrome --web-port 3000 --verbose --dart-define=FLUTTER_WEB_USE_SKIA=true
if errorlevel 1 (
    echo.
    echo ❌ HATA: Uygulama başlatılamadı!
    echo.
    echo 🔧 Çözüm önerileri v3.0:
    echo    1. Chrome güncel mi kontrol edin
    echo    2. Port 3000 kullanımda olabilir  
    echo    3. firebase_deploy.bat çalıştırın (indexes)
    echo    4. Firebase Console → Authentication → Google aktif
    echo    5. SHA1/SHA256 fingerprints Firebase'e eklendi mi
    echo.
    echo 🔄 Alternatif başlatma komutları:
    echo    flutter run -d chrome --web-port 3001
    echo    flutter run -d chrome --no-sound-null-safety (eski Flutter)
    echo.
    echo 📋 TEST ADIMLARİ:
    echo    1. Uygulamayı başlatın
    echo    2. Google ile giriş yapın
    echo    3. F12 → Console → FCM token kontrol edin
    echo    4. Bildirim izni verin
    echo    5. VAPID Key çalışmasını test edin
    echo.
)

echo.
echo 🔴 Uygulama durduruldu.
echo.
echo 💡 TİP: Kod değişikliği yaptıysanız bu dosyayı tekrar çalıştırın.
echo.
pause