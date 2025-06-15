@echo off
echo ========================================
echo    Randevu ERP - Release Build Script
echo ========================================

echo.
echo [1/6] Temizlik yapiliyor...
flutter clean

echo.
echo [2/6] Paketler guncelleniyor...
flutter pub get

echo.
echo [3/6] Kod analizi yapiliyor...
flutter analyze

echo.
echo [4/6] Web build yapiliyor...
flutter build web --release --web-renderer html --base-href /

echo.
echo [5/6] Android APK build yapiliyor...
flutter build apk --release --split-per-abi

echo.
echo [6/6] Android App Bundle build yapiliyor...
flutter build appbundle --release

echo.
echo ========================================
echo           BUILD TAMAMLANDI!
echo ========================================
echo.
echo Dosyalar:
echo - Web: build\web\
echo - APK: build\app\outputs\flutter-apk\
echo - AAB: build\app\outputs\bundle\release\
echo.
echo Firebase Hosting icin:
echo firebase deploy --only hosting
echo.
pause 