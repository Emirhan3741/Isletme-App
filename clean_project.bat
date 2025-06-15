@echo off
echo.
echo ============================================
echo     Flutter Proje Temizlik Scripti
echo ============================================
echo.

echo [1/6] Build klasoru siliniyor...
if exist "build" (
    rmdir /s /q "build"
    echo Build klasoru silindi.
) else (
    echo Build klasoru bulunamadi.
)

echo.
echo [2/6] .dart_tool klasoru siliniyor...
if exist ".dart_tool" (
    rmdir /s /q ".dart_tool"
    echo .dart_tool klasoru silindi.
) else (
    echo .dart_tool klasoru bulunamadi.
)

echo.
echo [3/6] .idea klasoru siliniyor...
if exist ".idea" (
    rmdir /s /q ".idea"
    echo .idea klasoru silindi.
) else (
    echo .idea klasoru bulunamadi.
)

echo.
echo [4/6] .packages dosyasi siliniyor...
if exist ".packages" (
    del ".packages"
    echo .packages dosyasi silindi.
) else (
    echo .packages dosyasi bulunamadi.
)

echo.
echo [5/6] pubspec.lock dosyasi siliniyor...
if exist "pubspec.lock" (
    del "pubspec.lock"
    echo pubspec.lock dosyasi silindi.
) else (
    echo pubspec.lock dosyasi bulunamadi.
)

echo.
echo [6/6] Flutter clean calistiriliyor...
flutter clean

echo.
echo ============================================
echo     TEMIZLIK TAMAMLANDI!
echo ============================================
echo.
echo Simdi flutter pub get calistirabilirsiniz.
echo.

pause 