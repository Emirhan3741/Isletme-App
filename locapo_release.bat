@echo off
echo ========================================
echo        LOCAPO RELEASE HAZIRLIGI
echo ========================================
echo.

echo [1/7] Flutter Clean...
call flutter clean
if %errorlevel% neq 0 (
    echo HATA: Flutter clean basarisiz!
    pause
    exit /b 1
)

echo [2/7] Flutter Pub Get...
call flutter pub get
if %errorlevel% neq 0 (
    echo HATA: Pub get basarisiz!
    pause
    exit /b 1
)

echo [3/7] Localization Generate...
call flutter gen-l10n
if %errorlevel% neq 0 (
    echo HATA: Localization generate basarisiz!
    pause
    exit /b 1
)

echo [4/7] Flutter Analyze...
call flutter analyze --no-fatal-warnings
if %errorlevel% neq 0 (
    echo UYARI: Analyze'de sorunlar var, devam ediliyor...
)

echo [5/7] Flutter Test...
call flutter test
if %errorlevel% neq 0 (
    echo HATA: Testler basarisiz!
    pause
    exit /b 1
)

echo [6/7] APK Build...
call flutter build apk
if %errorlevel% neq 0 (
    echo HATA: APK build basarisiz!
    pause
    exit /b 1
)

echo [7/7] Web Build (HTML Renderer)...
call flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=false
if %errorlevel% neq 0 (
    echo UYARI: Web build basarisiz! Shader sorunu var.
    echo Cozum: Proje yolunu ASCII karakterli dizine tasi.
    echo Ornek: C:\Projects\randevu_erp
)

echo.
echo ========================================
echo         TAMAMLANDI! ✓
echo ========================================
echo APK: build/app/outputs/flutter-apk/app-release.apk
echo Web: build/web/ (shader sorunu varsa calismiyor olabilir)
echo.
echo Firebase Console Kontrol Listesi:
echo - Storage aktif mi? (console.firebase.google.com)
echo - CORS policy ayarli mi? (console.cloud.google.com)
echo - Cloud Messaging API aktif mi?
echo - IAM rolleri verildi mi?
echo.
pause