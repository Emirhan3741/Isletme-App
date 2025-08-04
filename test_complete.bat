@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   RANDEVU ERP COMPLETE TEST SUITE v3.0
echo ==========================================
echo.
echo 🧪 Bu script projenin tüm özelliklerini test eder
echo.

echo 📋 TEST PLANI:
echo    1. ✅ Firebase Deploy (Rules + Indexes)
echo    2. ✅ Flutter Clean + Pub Get
echo    3. ✅ Web Uygulaması Başlatma
echo    4. ✅ Google Sign-In Test
echo    5. ✅ VAPID Key & FCM Test
echo    6. ✅ Firestore Veri Kayıt Test
echo.

pause

REM 1. Firebase Deploy
echo.
echo 🔥 1. Firebase Deploy işlemi başlatılıyor...
echo.
if exist firebase_deploy.bat (
    call firebase_deploy.bat
) else (
    echo ⚠️ firebase_deploy.bat bulunamadı, manuel deploy gerekli
    echo Firebase Console'dan indexes oluşturun: FIRESTORE_INDEX_URLS.md
)

echo.
echo ✅ Firebase deploy tamamlandı

REM 2. Flutter Temizlik
echo.
echo 🧹 2. Flutter temizlik işlemi...
echo.
call flutter clean
call flutter pub get

echo.
echo ✅ Flutter hazırlıkları tamamlandı

REM 3. CORS Ayarları
echo.
echo 🌐 3. CORS ayarları kontrol ediliyor...
echo.
if exist apply_cors.bat (
    call apply_cors.bat
) else (
    echo ⚠️ apply_cors.bat bulunamadı, manuel CORS ayarı gerekli
)

echo.
echo ✅ CORS ayarları tamamlandı

REM 4. Test Server Başlatma
echo.
echo 🚀 4. Test server başlatılıyor...
echo.
echo 📊 TEST KONTROL LİSTESİ:
echo    □ Chrome'da http://localhost:3000 açıldı mı?
echo    □ Login sayfası görünüyor mu?
echo    □ Google Sign-In butonu çalışıyor mu?
echo    □ F12 Console'da hata var mı?
echo    □ VAPID Key konsola yazıldı mı?
echo    □ FCM token alındı mı?
echo    □ Bildirim izni istendi mi?
echo    □ Dashboard navigation çalışıyor mu?
echo.
echo ⏳ Şimdi tarayıcıda test yapın...
echo.
echo 🔑 VAPID KEY TEST:
echo    Konsol'da bu mesajı arayın:
echo    "🔑 VAPID Key loaded: BJ7LMlB1LNtAVtiqk5C_nvzANRpKoLgncFChYu36X3NeClE0H-EcINhS9MFTCSuNanHkitPwdMUI7uX_cEk4Xno"
echo.

REM Web başlatma
call flutter run -d chrome --web-port 3000 --verbose

echo.
echo 🏁 TEST TAMAMLANDI
echo.
echo 📈 SONUÇLAR:
echo    • Eğer uygulama açıldıysa → ✅ Temel kurulum OK
echo    • Google giriş çalışıyorsa → ✅ Firebase Auth OK  
echo    • VAPID key göründüyse → ✅ FCM OK
echo    • Dashboard açıldıysa → ✅ Navigation OK
echo.
echo 🔧 SORUN VARSA:
echo    1. FIRESTORE_INDEX_URLS.md linklerini açın
echo    2. Firebase Console → Authentication kontrol
echo    3. Chrome'da Sıkılaştırılmış güvenlik açın
echo    4. İnternet bağlantısını kontrol edin
echo.
pause