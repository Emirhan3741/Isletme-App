@echo off
echo ========================================
echo      FIREBASE STORAGE CORS AYARLARI
echo ========================================
echo.

echo CORS ayarlari uygulanıyor...
"%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gsutil.cmd" cors set cors.json gs://randevu-takip-app.appspot.com

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo      ✅ CORS SUCCESSFULLY APPLIED
    echo ========================================
    echo.
    echo Uygulanan ayarlar:
    type cors.json
    echo.
    echo Firebase Storage artık web uygulamanızdan
    echo erişilebilir durumda!
) else (
    echo.
    echo ========================================
    echo      ❌ CORS UYGULANAMADI
    echo ========================================
    echo.
    echo Lütfen Firebase Console'da Storage'ı
    echo aktifleştirdiğinizden emin olun:
    echo https://console.firebase.google.com/project/randevu-takip-app/storage
)

echo.
pause