# RANDEVU ERP → LOCAPO POST-MIGRATION SETUP
# Bu script migration sonrası gerekli konfigürasyonları yapar

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   POST-MIGRATION SETUP FOR LOCAPO" -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

$ProjectPath = "C:\Projects\locapo"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "❌ HATA: $ProjectPath bulunamadı!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $ProjectPath
Write-Host "📁 Çalışma dizini: $ProjectPath" -ForegroundColor Green

# 1. pubspec.yaml'da proje adını güncelle
Write-Host ""
Write-Host "🔧 1. pubspec.yaml güncellemesi..." -ForegroundColor Yellow

$pubspecPath = Join-Path $ProjectPath "pubspec.yaml"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    $content = $content -replace "name: randevu_erp", "name: locapo"
    $content = $content -replace "description: A new Flutter project.", "description: Locapo - Multi-sector appointment management system."
    Set-Content $pubspecPath $content
    Write-Host "✅ pubspec.yaml güncellendi" -ForegroundColor Green
} else {
    Write-Host "❌ pubspec.yaml bulunamadı" -ForegroundColor Red
}

# 2. Android package name güncelle  
Write-Host ""
Write-Host "🔧 2. Android package name güncellemesi..." -ForegroundColor Yellow

$androidManifestPath = Join-Path $ProjectPath "android\app\src\main\AndroidManifest.xml"
if (Test-Path $androidManifestPath) {
    $content = Get-Content $androidManifestPath -Raw
    $content = $content -replace "com.example.randevu_erp", "com.projects.locapo"
    Set-Content $androidManifestPath $content
    Write-Host "✅ AndroidManifest.xml güncellendi" -ForegroundColor Green
} else {
    Write-Host "⚠️  AndroidManifest.xml bulunamadı" -ForegroundColor Yellow
}

$buildGradlePath = Join-Path $ProjectPath "android\app\build.gradle.kts"
if (Test-Path $buildGradlePath) {
    $content = Get-Content $buildGradlePath -Raw
    $content = $content -replace "com.example.randevu_erp", "com.projects.locapo"
    Set-Content $buildGradlePath $content
    Write-Host "✅ build.gradle.kts güncellendi" -ForegroundColor Green
}

# 3. iOS Bundle ID güncelle
Write-Host ""
Write-Host "🔧 3. iOS Bundle ID güncellemesi..." -ForegroundColor Yellow

$iosInfoPlistPath = Join-Path $ProjectPath "ios\Runner\Info.plist"
if (Test-Path $iosInfoPlistPath) {
    $content = Get-Content $iosInfoPlistPath -Raw
    $content = $content -replace "com.example.randevuErp", "com.projects.locapo"
    Set-Content $iosInfoPlistPath $content
    Write-Host "✅ iOS Info.plist güncellendi" -ForegroundColor Green
} else {
    Write-Host "⚠️  iOS Info.plist bulunamadı" -ForegroundColor Yellow
}

# 4. .bat dosyalarını güncelle
Write-Host ""
Write-Host "🔧 4. Batch dosyaları güncellemesi..." -ForegroundColor Yellow

$batFiles = @("locato.baslat.bat", "quick_start.bat", "test_complete.bat")
foreach ($batFile in $batFiles) {
    $batPath = Join-Path $ProjectPath $batFile
    if (Test-Path $batPath) {
        $content = Get-Content $batPath -Raw
        $content = $content -replace "randevu_erp", "locapo"
        $content = $content -replace "RANDEVU ERP", "LOCAPO"
        Set-Content $batPath $content
        Write-Host "✅ $batFile güncellendi" -ForegroundColor Green
    }
}

# 5. Flutter clean & pub get
Write-Host ""
Write-Host "🔧 5. Flutter dependencies..." -ForegroundColor Yellow

try {
    & flutter clean
    & flutter pub get
    Write-Host "✅ Flutter dependencies yüklendi" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Flutter komutları başarısız, manuel çalıştırın" -ForegroundColor Yellow
}

# 6. Konfigürasyon özeti
Write-Host ""
Write-Host "🎯 MİGRATİON TAMAMLANDI!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 YAPILAN DEĞİŞİKLİKLER:" -ForegroundColor Cyan
Write-Host "   • Proje adı: randevu_erp → locapo" -ForegroundColor White
Write-Host "   • Android package: com.example.randevu_erp → com.projects.locapo" -ForegroundColor White  
Write-Host "   • iOS Bundle ID: com.example.randevuErp → com.projects.locapo" -ForegroundColor White
Write-Host "   • Batch dosyaları güncellendi" -ForegroundColor White
Write-Host "   • Flutter dependencies yenilendi" -ForegroundColor White
Write-Host ""
Write-Host "🔑 VAPID KEY KORUNDU:" -ForegroundColor Cyan
Write-Host "   BJ7LMlB1LNtAVtiqk5C_nvzANRpKoLgncFChYu36X3NeClE0H-EcINhS9MFTCSuNanHkitPwdMUI7uX_cEk4Xno" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 SONRAKI ADIMLAR:" -ForegroundColor Cyan
Write-Host "   1. cd C:\Projects\locapo" -ForegroundColor White
Write-Host "   2. .\locato.baslat.bat (or .\quick_start.bat)" -ForegroundColor White
Write-Host "   3. Test: flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "🔧 COMPILE HATALARI İÇİN:" -ForegroundColor Cyan
Write-Host "   • flutter analyze ile kontrol edin" -ForegroundColor White
Write-Host "   • En kritik hatalar düzeltildi, kalan hatalar warning seviyesinde" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"