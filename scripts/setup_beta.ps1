# Beta Environment Setup Script for Randevu ERP
# Bu script beta test ortamını hazırlar ve gerekli konfigürasyonları yapar

param(
    [switch]$CreateTestUsers,
    [switch]$InitializeTestData,
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Randevu ERP Beta Environment Setup Başlatılıyor..." -ForegroundColor Green

# Gerekli araçları kontrol et
function Test-Requirements {
    Write-Host "📋 Gereksinimler kontrol ediliyor..." -ForegroundColor Blue
    
    # Flutter kontrolü
    try {
        $flutterVersion = flutter --version 2>$null
        Write-Host "✅ Flutter bulundu" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Flutter bulunamadı. Lütfen Flutter'ı yükleyin." -ForegroundColor Red
        Write-Host "   Download: https://flutter.dev/docs/get-started/install" -ForegroundColor Cyan
        exit 1
    }
    
    # Firebase CLI kontrolü
    try {
        $firebaseVersion = firebase --version 2>$null
        Write-Host "✅ Firebase CLI bulundu" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Firebase CLI bulunamadı." -ForegroundColor Red
        Write-Host "   Install: npm install -g firebase-tools" -ForegroundColor Cyan
        
        $install = Read-Host "Firebase CLI'yi şimdi yüklemek istiyor musunuz? (y/n)"
        if ($install -eq 'y' -or $install -eq 'Y') {
            try {
                npm install -g firebase-tools
                Write-Host "✅ Firebase CLI yüklendi" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Firebase CLI yüklenemedi. Manuel olarak yükleyin." -ForegroundColor Red
                exit 1
            }
        }
        else {
            exit 1
        }
    }
    
    # Git kontrolü
    try {
        git --version | Out-Null
        Write-Host "✅ Git bulundu" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Git bulunamadı. Önerilir ancak zorunlu değil." -ForegroundColor Yellow
    }
}

# Dependencies güncelle
function Update-Dependencies {
    if ($SkipDependencies) {
        Write-Host "⏭️ Dependencies güncelleme atlandı" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📦 Flutter dependencies güncelleniyor..." -ForegroundColor Blue
    
    try {
        flutter clean
        flutter pub get
        Write-Host "✅ Dependencies güncellendi" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Dependencies güncellenemedi" -ForegroundColor Red
        throw
    }
}

# Beta konfigürasyonunu oluştur
function Initialize-BetaConfig {
    Write-Host "⚙️ Beta konfigürasyonu hazırlanıyor..." -ForegroundColor Blue
    
    # AppConfig dosyasını beta'ya ayarla
    $configFile = "lib/config/app_config.dart"
    
    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw
        $content = $content -replace "Environment\.development", "Environment.beta"
        Set-Content -Path $configFile -Value $content
        Write-Host "✅ AppConfig beta'ya ayarlandı" -ForegroundColor Green
    }
    else {
        Write-Host "❌ AppConfig dosyası bulunamadı" -ForegroundColor Red
        throw "Config file not found"
    }
}

# Firebase projesini ayarla
function Initialize-Firebase {
    Write-Host "🔥 Firebase beta projesi ayarlanıyor..." -ForegroundColor Blue
    
    # Firebase login kontrolü
    try {
        firebase projects:list | Out-Null
        Write-Host "✅ Firebase'e giriş yapılmış" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Firebase'e giriş yapmak gerekiyor" -ForegroundColor Yellow
        firebase login
    }
    
    # Firebase projesi oluştur veya seç
    Write-Host "Firebase beta projesi seçiliyor..." -ForegroundColor Blue
    
    try {
        firebase use randevu-erp-beta
        Write-Host "✅ Beta projesi seçildi" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Beta projesi bulunamadı. Yeni proje oluşturmak için Firebase Console'u kullanın." -ForegroundColor Yellow
        Write-Host "   Console: https://console.firebase.google.com" -ForegroundColor Cyan
        
        $continueSetup = Read-Host "Devam etmek istiyor musunuz? (y/n)"
        if ($continueSetup -ne 'y' -and $continueSetup -ne 'Y') {
            exit 1
        }
    }
}

# Test kullanıcıları oluştur
function New-TestUsers {
    if (-not $CreateTestUsers) {
        Write-Host "⏭️ Test kullanıcı oluşturma atlandı" -ForegroundColor Yellow
        return
    }
    
    Write-Host "👥 Test kullanıcıları oluşturuluyor..." -ForegroundColor Blue
    
    $testUsers = @(
        @{
            email = "test.beauty@randevuerp.com"
            password = "TestBeauty123!"
            role = "beauty_salon_owner"
            businessType = "beauty"
        },
        @{
            email = "test.clinic@randevuerp.com"
            password = "TestClinic123!"
            role = "clinic_doctor"
            businessType = "clinic"
        },
        @{
            email = "test.sports@randevuerp.com"
            password = "TestSports123!"
            role = "sports_coach"
            businessType = "sports"
        }
    )
    
    Write-Host "ℹ️ Test kullanıcıları:" -ForegroundColor Green
    foreach ($user in $testUsers) {
        Write-Host "  • $($user.email) ($($user.password))" -ForegroundColor Yellow
    }
    
    Write-Host "⚠️ Test kullanıcıları manuel olarak Firebase Authentication'da oluşturulmalıdır." -ForegroundColor Yellow
    Write-Host "   Console: https://console.firebase.google.com" -ForegroundColor Cyan
}

# Test verilerini hazırla
function Initialize-TestData {
    if (-not $InitializeTestData) {
        Write-Host "⏭️ Test data hazırlama atlandı" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📊 Test verileri hazırlanıyor..." -ForegroundColor Blue
    
    # TestDataService kullanarak data oluşturma
    Write-Host "ℹ️ Test verileri uygulama çalıştığında otomatik oluşturulacak:" -ForegroundColor Green
    Write-Host "  • 20 müşteri" -ForegroundColor Yellow
    Write-Host "  • 7 hizmet" -ForegroundColor Yellow
    Write-Host "  • 25 randevu" -ForegroundColor Yellow
    Write-Host "  • 30 finansal işlem" -ForegroundColor Yellow
    Write-Host "  • 10 not" -ForegroundColor Yellow
    
    Write-Host "✅ Test data konfigürasyonu hazır" -ForegroundColor Green
}

# Development tools'u ayarla
function Set-DevelopmentTools {
    Write-Host "🛠️ Development araçları ayarlanıyor..." -ForegroundColor Blue
    
    # Flutter doctor çalıştır
    Write-Host "Flutter doctor kontrolü..." -ForegroundColor Blue
    flutter doctor
    
    # VS Code extensions önerisi
    Write-Host ""
    Write-Host "📝 Önerilen VS Code Extensions:" -ForegroundColor Green
    Write-Host "  • Flutter" -ForegroundColor Cyan
    Write-Host "  • Dart" -ForegroundColor Cyan
    Write-Host "  • Firebase Tools" -ForegroundColor Cyan
    Write-Host "  • GitLens" -ForegroundColor Cyan
    Write-Host "  • Flutter Tree" -ForegroundColor Cyan
    
    Write-Host "✅ Development tools kontrol edildi" -ForegroundColor Green
}

# Beta testing rehberi göster
function Show-BetaGuide {
    Write-Host ""
    Write-Host "📋 Beta Test Rehberi:" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🚀 Deployment Komutları:" -ForegroundColor Blue
    Write-Host "  Web: .\scripts\deploy_beta_web.ps1" -ForegroundColor Cyan
    Write-Host "  Android: .\scripts\deploy_beta_android.sh" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "👤 Test Hesapları:" -ForegroundColor Blue
    Write-Host "  • test.beauty@randevuerp.com (TestBeauty123!)" -ForegroundColor Yellow
    Write-Host "  • test.clinic@randevuerp.com (TestClinic123!)" -ForegroundColor Yellow
    Write-Host "  • test.sports@randevuerp.com (TestSports123!)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "📊 Beta Limitleri:" -ForegroundColor Blue
    Write-Host "  • Müşteri: Max 100" -ForegroundColor Yellow
    Write-Host "  • Randevu: Max 500" -ForegroundColor Yellow
    Write-Host "  • İşlem: Max 1,000" -ForegroundColor Yellow
    Write-Host "  • Not: Max 200" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "🔗 Linkler:" -ForegroundColor Blue
    Write-Host "  • Dokümantasyon: .\BETA_RELEASE_GUIDE.md" -ForegroundColor Cyan
    Write-Host "  • Feedback: https://forms.google.com/randevu-erp-beta-feedback" -ForegroundColor Cyan
    Write-Host "  • Bug Report: https://github.com/randevu-erp/issues" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "📱 Test Senaryoları:" -ForegroundColor Blue
    Write-Host "  1. Kullanıcı kaydı ve giriş" -ForegroundColor Yellow
    Write-Host "  2. Dashboard istatistikleri" -ForegroundColor Yellow
    Write-Host "  3. Müşteri CRUD işlemleri" -ForegroundColor Yellow
    Write-Host "  4. Randevu yönetimi" -ForegroundColor Yellow
    Write-Host "  5. Finansal işlemler" -ForegroundColor Yellow
    Write-Host "  6. Not yönetimi" -ForegroundColor Yellow
}

# Kurulum doğrulaması
function Test-Installation {
    Write-Host "🧪 Kurulum doğrulanıyor..." -ForegroundColor Blue
    
    $errors = @()
    
    # Flutter test
    try {
        flutter test | Out-Null
        Write-Host "✅ Flutter tests pass" -ForegroundColor Green
    }
    catch {
        $errors += "Flutter tests failed"
        Write-Host "❌ Flutter tests failed" -ForegroundColor Red
    }
    
    # Build test
    try {
        flutter build web --debug
        Write-Host "✅ Web build successful" -ForegroundColor Green
    }
    catch {
        $errors += "Web build failed"
        Write-Host "❌ Web build failed" -ForegroundColor Red
    }
    
    if ($errors.Count -eq 0) {
        Write-Host "✅ Tüm doğrulamalar başarılı" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "❌ $($errors.Count) hata bulundu:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
        return $false
    }
}

# Ana fonksiyon
function Main {
    Write-Host ""
    Write-Host "=== RANDEVU ERP BETA ENVIRONMENT SETUP ===" -ForegroundColor Green
    Write-Host "Tarih: $(Get-Date)" -ForegroundColor Blue
    Write-Host "Versiyon: 1.0.0-beta.1" -ForegroundColor Blue
    Write-Host ""
    
    try {
        # Adım adım kurulum
        Test-Requirements
        Update-Dependencies
        Initialize-BetaConfig
        Initialize-Firebase
        New-TestUsers
        Initialize-TestData
        Set-DevelopmentTools
        
        Write-Host ""
        Write-Host "🎉 Beta environment kurulumu tamamlandı!" -ForegroundColor Green
        
        # Doğrulama yap
        if (Test-Installation) {
            Show-BetaGuide
            
            Write-Host ""
            Write-Host "🚀 Beta testing'e hazır!" -ForegroundColor Green
            Write-Host "Deployment yapmak için: .\scripts\deploy_beta_web.ps1" -ForegroundColor Cyan
        }
        else {
            Write-Host "⚠️ Bazı sorunlar var. Lütfen hataları düzeltin." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Setup sırasında hata oluştu: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Detaylar için BETA_RELEASE_GUIDE.md dosyasını inceleyin." -ForegroundColor Yellow
        exit 1
    }
}

# Script'i çalıştır
Main 