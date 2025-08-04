@echo off
chcp 65001 > nul
cls

echo.
echo 🛠️ RANDEVU ERP - SORUN ÇÖZÜCÜ 🛠️
echo =================================
echo.

echo 🔍 Yaşadığınız sorun nedir?
echo.
echo [1] 🚫 Proje çalışmıyor
echo [2] 📦 Paket hataları
echo [3] 🔥 Firebase bağlantı sorunu
echo [4] 🌐 Web build hataları
echo [5] 📱 Android build hataları
echo [6] 💾 Cache temizleme
echo [7] 🔄 Tam reset (her şeyi temizle)
echo [8] 📊 Sistem bilgilerini göster
echo [0] ❌ Çıkış
echo.

set /p choice="Sorun numaranızı seçin (1-8): "

if "%choice%"=="1" goto fix_not_running
if "%choice%"=="2" goto fix_packages
if "%choice%"=="3" goto fix_firebase
if "%choice%"=="4" goto fix_web_build
if "%choice%"=="5" goto fix_android_build
if "%choice%"=="6" goto clear_cache
if "%choice%"=="7" goto full_reset
if "%choice%"=="8" goto system_info
if "%choice%"=="0" goto exit
goto invalid_choice

:fix_not_running
echo.
echo 🚫 Proje çalışmıyor - Otomatik düzeltme...
echo.

echo 1️⃣ Flutter doctor kontrol...
call flutter doctor

echo.
echo 2️⃣ Paketler yenileniyor...
call flutter clean
call flutter pub get

echo.
echo 3️⃣ Cache temizleniyor...
call flutter pub cache clean
call flutter pub get

echo.
echo 4️⃣ Tekrar deneniyor...
call flutter run -d chrome --web-port 3000 --no-sound-null-safety

if %errorlevel% neq 0 (
    echo.
    echo ❌ Hala çalışmıyor! Manuel kontrol gerekli:
    echo    • pubspec.yaml'da syntax hatası var mı?
    echo    • lib/main.dart dosyası var mı?
    echo    • Import hataları var mı?
    echo.
    pause
)
goto end

:fix_packages
echo.
echo 📦 Paket sorunları düzeltiliyor...
echo.

echo 1️⃣ Pubspec.lock siliniyor...
if exist "pubspec.lock" del "pubspec.lock"

echo 2️⃣ .packages siliniyor...
if exist ".packages" del ".packages"

echo 3️⃣ Cache temizleniyor...
call flutter pub cache clean

echo 4️⃣ Paketler yeniden yükleniyor...
call flutter pub get

echo 5️⃣ Paket uyumluluğu kontrol ediliyor...
call flutter pub deps

echo ✅ Paket sorunları düzeltildi!
pause
goto end

:fix_firebase
echo.
echo 🔥 Firebase sorunları düzeltiliyor...
echo.

echo 1️⃣ Firebase config kontrol...
if not exist "lib/firebase_options.dart" (
    echo ❌ firebase_options.dart bulunamadı!
    echo 💡 firebase_cli ile proje konfigürasyonu yapın:
    echo    firebase init
    echo    flutterfire configure
) else (
    echo ✅ firebase_options.dart mevcut
)

echo.
echo 2️⃣ Web Firebase config kontrol...
if not exist "web/firebase-config.js" (
    echo ⚠️  web/firebase-config.js bulunamadı!
    echo 💡 Firebase Console'dan web config alın
) else (
    echo ✅ web/firebase-config.js mevcut
)

echo.
echo 3️⃣ Android Firebase config kontrol...
if not exist "android/app/google-services.json" (
    echo ⚠️  android/app/google-services.json bulunamadı!
    echo 💡 Firebase Console'dan Android config indirin
) else (
    echo ✅ google-services.json mevcut
)

echo.
echo 4️⃣ Firebase bağlantısı test ediliyor...
call flutter run -d chrome --web-port 3000 --no-sound-null-safety --verbose

pause
goto end

:fix_web_build
echo.
echo 🌐 Web build sorunları düzeltiliyor...
echo.

echo 1️⃣ Web klasörü kontrol...
if not exist "web" mkdir web

echo 2️⃣ index.html kontrol...
if not exist "web/index.html" (
    echo ❌ web/index.html eksik!
    echo 💡 flutter create . komutu ile yeniden oluşturun
) else (
    echo ✅ web/index.html mevcut
)

echo 3️⃣ Web dependencies temizleniyor...
if exist "build/web" rmdir /s /q "build/web"

echo 4️⃣ Web build test...
call flutter build web --release --no-sound-null-safety --verbose

if %errorlevel% equ 0 (
    echo ✅ Web build başarılı!
) else (
    echo ❌ Web build başarısız!
    echo 💡 Hatayı kontrol edin ve tekrar deneyin
)
pause
goto end

:fix_android_build
echo.
echo 📱 Android build sorunları düzeltiliyor...
echo.

echo 1️⃣ Android klasörü kontrol...
if not exist "android" (
    echo ❌ android klasörü yok!
    echo 💡 flutter create . komutu ile yeniden oluşturun
    pause
    goto end
)

echo 2️⃣ Gradle wrapper kontrol...
if not exist "android/gradlew" (
    echo ❌ Gradle wrapper eksik!
    echo 💡 Android Studio ile projeyi açın
)

echo 3️⃣ Android cache temizleniyor...
if exist "build/app" rmdir /s /q "build/app"

echo 4️⃣ Gradle cache temizleniyor...
call cd android && gradlew clean && cd ..

echo 5️⃣ Android build test...
call flutter build apk --debug --no-sound-null-safety

if %errorlevel% equ 0 (
    echo ✅ Android build başarılı!
) else (
    echo ❌ Android build başarısız!
    echo 💡 Android Studio ile proje açıp hatayı kontrol edin
)
pause
goto end

:clear_cache
echo.
echo 💾 Tüm cache temizleniyor...
echo.

echo 1️⃣ Flutter cache...
call flutter clean

echo 2️⃣ Pub cache...
call flutter pub cache clean

echo 3️⃣ Build klasörleri...
if exist "build" rmdir /s /q "build"

echo 4️⃣ Dart cache...
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo 5️⃣ Packages...
if exist ".packages" del ".packages"
if exist "pubspec.lock" del "pubspec.lock"

echo 6️⃣ Paketler yeniden yükleniyor...
call flutter pub get

echo ✅ Cache temizlendi!
pause
goto end

:full_reset
echo.
echo 🔄 TAM RESET - DİKKAT: Her şey silinecek!
echo.
echo ⚠️  Bu işlem geri alınamaz! Devam etmek istiyor musunuz? (y/n)
set /p confirm=""

if /i not "%confirm%"=="y" (
    echo İptal edildi.
    pause
    goto end
)

echo.
echo 🗑️ Tam reset yapılıyor...

echo 1️⃣ Build klasörleri siliniyor...
if exist "build" rmdir /s /q "build"

echo 2️⃣ Cache klasörleri siliniyor...
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo 3️⃣ Packages siliniyor...
if exist ".packages" del ".packages"
if exist "pubspec.lock" del "pubspec.lock"

echo 4️⃣ Flutter cache siliniyor...
call flutter clean
call flutter pub cache clean

echo 5️⃣ Flutter doctor çalıştırılıyor...
call flutter doctor

echo 6️⃣ Paketler yeniden yükleniyor...
call flutter pub get

echo 7️⃣ Test çalıştırması...
call flutter run -d chrome --web-port 3000 --no-sound-null-safety

echo ✅ Tam reset tamamlandı!
pause
goto end

:system_info
echo.
echo 📊 SİSTEM BİLGİLERİ
echo ===================
echo.

echo 🔍 Flutter bilgileri:
call flutter --version

echo.
echo 🩺 Flutter doctor:
call flutter doctor -v

echo.
echo 💻 Sistem bilgileri:
echo OS: %OS%
echo Kullanıcı: %USERNAME%
echo Bilgisayar: %COMPUTERNAME%

echo.
echo 📁 Proje bilgileri:
if exist "pubspec.yaml" (
    echo ✅ pubspec.yaml mevcut
) else (
    echo ❌ pubspec.yaml YOK!
)

if exist "lib/main.dart" (
    echo ✅ lib/main.dart mevcut
) else (
    echo ❌ lib/main.dart YOK!
)

echo.
echo 🌐 Chrome kontrol:
where chrome >nul 2>nul
if %errorlevel% equ 0 (
    echo ✅ Chrome kurulu
) else (
    echo ⚠️  Chrome bulunamadı
)

pause
goto end

:invalid_choice
echo ❌ Geçersiz seçim!
pause
goto start

:exit
echo 👋 Çıkılıyor...
exit /b 0

:end
echo.
echo ✨ Sorun çözme işlemi tamamlandı!
pause

:start
cls
goto :eof