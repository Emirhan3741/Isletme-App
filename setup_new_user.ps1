# Flutter Yeni Kullanıcı Kurulum Scripti
# Bu scripti yeni Developer kullanıcısında çalıştırın

Write-Host "=== FLUTTER YENİ KULLANICI KURULUMU ===" -ForegroundColor Green

# 1. Flutter SDK Yolu Kontrol
Write-Host "1. Flutter SDK yolu kontrol ediliyor..." -ForegroundColor Yellow
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterPath) {
    Write-Host "✅ Flutter bulundu: $($flutterPath.Source)" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter bulunamadı! PATH'e eklemelisiniz." -ForegroundColor Red
    Write-Host "Flutter SDK yolu: C:\flutter\bin" -ForegroundColor Cyan
}

# 2. Proje klasörü oluştur
Write-Host "2. Proje klasörü hazırlanıyor..." -ForegroundColor Yellow
$projectPath = "C:\Projects\locapo"
if (Test-Path $projectPath) {
    Write-Host "✅ Proje klasörü mevcut: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ Proje klasörü yok! Kopyalanması gerekiyor." -ForegroundColor Red
}

# 3. Proje bağımlılıklarını yükle
Write-Host "3. Flutter projesine gidiliyor..." -ForegroundColor Yellow
Set-Location $projectPath

Write-Host "4. Flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "5. Flutter pub get..." -ForegroundColor Yellow  
flutter pub get

Write-Host "6. Flutter doctor kontrol..." -ForegroundColor Yellow
flutter doctor

Write-Host "=== KURULUM TAMAMLANDI ===" -ForegroundColor Green
Write-Host "Şimdi 'flutter build apk --debug' komutunu deneyebilirsiniz." -ForegroundColor Cyan