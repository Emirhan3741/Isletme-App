@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo   RANDEVU ERP → C:\Projects\locapo MİGRATİON
echo ==========================================
echo.
echo 🚀 Proje güvenli şekilde taşınacak
echo.

REM Hedef klasörü oluştur
set "TARGET_DIR=C:\Projects\locapo"
echo 📁 Hedef klasör: %TARGET_DIR%

if not exist "C:\Projects\" (
    echo 📁 C:\Projects\ klasörü oluşturuluyor...
    mkdir "C:\Projects"
)

if exist "%TARGET_DIR%" (
    echo ⚠️  UYARI: %TARGET_DIR% zaten var!
    echo.
    echo Seçenekler:
    echo   1) Backup oluştur ve üzerine yaz
    echo   2) İptal et
    echo.
    set /p choice="Seçiminiz (1/2): "
    
    if "!choice!"=="2" (
        echo ❌ İşlem iptal edildi
        pause
        exit /b 1
    )
    
    if "!choice!"=="1" (
        echo 📦 Backup oluşturuluyor...
        set "BACKUP_DIR=%TARGET_DIR%_backup_%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%"
        set "BACKUP_DIR=!BACKUP_DIR: =!"
        set "BACKUP_DIR=!BACKUP_DIR::=!"
        
        if exist "%TARGET_DIR%" (
            echo Eski proje backup'lanıyor: !BACKUP_DIR!
            move "%TARGET_DIR%" "!BACKUP_DIR!"
        )
    )
)

echo.
echo 🔄 Proje kopyalanıyor...
echo   Kaynak: %CD%
echo   Hedef:  %TARGET_DIR%
echo.

REM ROBOCOPY ile gelişmiş kopyalama
robocopy "%CD%" "%TARGET_DIR%" /E /COPYALL /R:3 /W:1 /NP /XD "build" ".dart_tool" "android\.gradle" "ios\build" "web\build" ".git" "node_modules" /XF "*.log" "*.tmp" "pubspec.lock.bak" "*.temp"

if errorlevel 8 (
    echo ❌ HATA: Kopyalama başarısız!
    echo Detaylar için ROBOCOPY log'unu kontrol edin
    pause
    exit /b 1
) else if errorlevel 4 (
    echo ⚠️  UYARI: Bazı dosyalar kopyalanamadı, ama proje çalışabilir
) else (
    echo ✅ Kopyalama başarılı!
)

echo.
echo 🔧 Yeni klasörde Flutter setup...

cd /d "%TARGET_DIR%"

if exist pubspec.yaml (
    echo 📦 Dependencies yükleniyor...
    call flutter clean
    call flutter pub get
    
    if errorlevel 1 (
        echo ⚠️  Flutter pub get başarısız, manuel çalıştırın
    ) else (
        echo ✅ Dependencies hazır
    )
) else (
    echo ❌ pubspec.yaml bulunamadı!
)

echo.
echo 🎯 YENİ PROJE LOKASYONU: %TARGET_DIR%
echo.
echo 📋 SONRAKI ADIMLAR:
echo   1. CMD/Terminal'de: cd /d "%TARGET_DIR%"
echo   2. Test et: flutter run -d chrome
echo   3. VS Code: File > Open Folder > "%TARGET_DIR%"
echo.

REM Yeni klasörde quick_start.bat güncelle
if exist "%TARGET_DIR%\quick_start.bat" (
    echo 🔧 quick_start.bat güncelleniyor...
    powershell -Command "(Get-Content '%TARGET_DIR%\quick_start.bat') -replace 'randevu_erp', 'locapo' | Set-Content '%TARGET_DIR%\quick_start.bat'"
)

echo ✨ MİGRATİON TAMAMLANDI!
echo.
echo 🚨 UNUTMAYIN:
echo   • Eski klasör: %CD%
echo   • Yeni klasör: %TARGET_DIR%
echo   • Firebase ayarları değişmedi
echo   • VAPID Key korundu: BJ7LMlB1LNtAVtiqk5C_nvzANRpKoLgncFChYu36X3NeClE0H-EcINhS9MFTCSuNanHkitPwdMUI7uX_cEk4Xno
echo.

pause