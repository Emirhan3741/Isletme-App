@echo off
echo.
echo ============================================
echo     Flutter Windows Build Script
echo ============================================
echo.

echo [1/4] Temizlik islemi baslatiliyor...
flutter clean
if %errorlevel% neq 0 (
    echo HATA: flutter clean basarisiz!
    pause
    exit /b 1
)

echo.
echo [2/4] Bagimliliklar yukleniyor...
flutter pub get
if %errorlevel% neq 0 (
    echo HATA: flutter pub get basarisiz!
    pause
    exit /b 1
)

echo.
echo [3/4] Windows uygulamasi derleniyor...
flutter build windows --release
if %errorlevel% neq 0 (
    echo HATA: flutter build windows basarisiz!
    pause
    exit /b 1
)

echo.
echo [4/4] Build tamamlandi!
echo.
echo ============================================
echo     BUILD BASARILI!
echo ============================================
echo.
echo Uygulama konumu: build\windows\x64\runner\Release\
echo.
echo Ana dosya: randevu_erp.exe
echo.

pause 