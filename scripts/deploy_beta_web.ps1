# PowerShell Beta Web Deployment Script for Randevu ERP
# Bu script Flutter web uygulamasını Firebase Hosting'e beta olarak deploy eder

param(
    [switch]$SkipDependencies,
    [switch]$SkipBuild,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Randevu ERP Beta Web Deployment Başlatılıyor..." -ForegroundColor Green

# Gerekli araçları kontrol et
function Test-Requirements {
    Write-Host "📋 Gereksinimler kontrol ediliyor..." -ForegroundColor Blue
    
    # Flutter kontrolü
    try {
        flutter --version | Out-Null
        Write-Host "✅ Flutter bulundu" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Flutter bulunamadı. Lütfen Flutter'ı yükleyin." -ForegroundColor Red
        exit 1
    }
    
    # Firebase CLI kontrolü
    try {
        firebase --version | Out-Null
        Write-Host "✅ Firebase CLI bulundu" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Firebase CLI bulunamadı. 'npm install -g firebase-tools' çalıştırın." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Tüm gereksinimler tamam." -ForegroundColor Green
}

# Flutter dependencies'leri güncelle
function Update-Dependencies {
    if ($SkipDependencies) {
        Write-Host "⏭️ Dependencies güncelleme atlandı" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📦 Dependencies güncelleniyor..." -ForegroundColor Blue
    flutter pub get
    flutter pub upgrade
    Write-Host "✅ Dependencies güncellendi." -ForegroundColor Green
}

# Beta konfigürasyonunu kontrol et
function Set-BetaConfig {
    Write-Host "⚙️ Beta konfigürasyonu kontrol ediliyor..." -ForegroundColor Blue
    
    $configFile = "lib/config/app_config.dart"
    
    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw
        
        if ($content -match "Environment\.beta") {
            Write-Host "✅ Beta konfigürasyonu aktif." -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ Beta konfigürasyonu aktif değil. Değiştiriliyor..." -ForegroundColor Yellow
            $content = $content -replace "Environment\.development", "Environment.beta"
            Set-Content -Path $configFile -Value $content
            Write-Host "✅ Beta konfigürasyonu aktif edildi." -ForegroundColor Green
        }
    }
    else {
        Write-Host "❌ AppConfig dosyası bulunamadı: $configFile" -ForegroundColor Red
        exit 1
    }
}

# Web build oluştur
function Build-Web {
    if ($SkipBuild) {
        Write-Host "⏭️ Build oluşturma atlandı" -ForegroundColor Yellow
        return
    }
    
    Write-Host "🔨 Web build oluşturuluyor..." -ForegroundColor Blue
    
    # Build klasörünü temizle
    flutter clean
    
    # Web için optimize edilmiş build
    flutter build web --release --web-renderer canvaskit --base-href "/" --source-maps --pwa-strategy=offline-first
    
    Write-Host "✅ Web build tamamlandı." -ForegroundColor Green
}

# Firebase hosting için hazırla
function Initialize-Firebase {
    Write-Host "🔥 Firebase deployment hazırlanıyor..." -ForegroundColor Blue
    
    # Firebase projesi seç (beta environment)
    try {
        firebase use randevu-erp-beta --add
    }
    catch {
        Write-Host "⚠️ Firebase projesi seçilemedi. Manuel olarak ayarlayın." -ForegroundColor Yellow
    }
    
    # Firebase.json'ı kontrol et veya oluştur
    if (-not (Test-Path "firebase.json")) {
        Write-Host "⚠️ firebase.json bulunamadı. Oluşturuluyor..." -ForegroundColor Yellow
        New-FirebaseConfig
    }
    
    Write-Host "✅ Firebase hazırlıkları tamamlandı." -ForegroundColor Green
}

# Firebase.json dosyasını oluştur
function New-FirebaseConfig {
    $firebaseConfig = @{
        hosting = @{
            site = "randevu-erp-beta"
            public = "build/web"
            ignore = @(
                "firebase.json",
                "**/.*",
                "**/node_modules/**"
            )
            rewrites = @(
                @{
                    source = "**"
                    destination = "/index.html"
                }
            )
            headers = @(
                @{
                    source = "**"
                    headers = @(
                        @{
                            key = "Cache-Control"
                            value = "public, max-age=3600"
                        }
                    )
                },
                @{
                    source = "**/*.@(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)"
                    headers = @(
                        @{
                            key = "Cache-Control"
                            value = "public, max-age=31536000"
                        }
                    )
                }
            )
        }
        firestore = @{
            rules = "firestore.rules"
            indexes = "firestore.indexes.json"
        }
    }
    
    $firebaseConfig | ConvertTo-Json -Depth 10 | Set-Content -Path "firebase.json"
    Write-Host "✅ firebase.json oluşturuldu." -ForegroundColor Green
}

# Beta versiyonu deploy et
function Deploy-ToFirebase {
    Write-Host "🚀 Firebase Hosting'e deploy ediliyor..." -ForegroundColor Blue
    
    # Beta channel'a deploy et
    firebase deploy --only hosting --project randevu-erp-beta
    
    Write-Host "✅ Beta deployment tamamlandı!" -ForegroundColor Green
    Write-Host "🌐 Beta URL: https://randevu-erp-beta.web.app" -ForegroundColor Blue
}

# Beta test kullanıcıları bildir
function Show-BetaInfo {
    Write-Host "📧 Beta testerları bilgilendiriliyor..." -ForegroundColor Blue
    
    Write-Host ""
    Write-Host "ℹ️ Beta test hesapları:" -ForegroundColor Green
    Write-Host "  • test.beauty@randevuerp.com (TestBeauty123!)" -ForegroundColor Yellow
    Write-Host "  • test.clinic@randevuerp.com (TestClinic123!)" -ForegroundColor Yellow
    Write-Host "  • test.sports@randevuerp.com (TestSports123!)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔗 Linkler:" -ForegroundColor Green
    Write-Host "  • Beta URL: https://randevu-erp-beta.web.app" -ForegroundColor Cyan
    Write-Host "  • Feedback: https://forms.google.com/randevu-erp-beta-feedback" -ForegroundColor Cyan
    Write-Host "  • Bug Report: https://github.com/randevu-erp/issues" -ForegroundColor Cyan
}

# Rollback fonksiyonu
function Invoke-Rollback {
    Write-Host "❌ Deployment sırasında hata oluştu. Rollback yapılıyor..." -ForegroundColor Red
    
    try {
        firebase hosting:channel:deploy previous --project randevu-erp-beta
        Write-Host "⚠️ Önceki versiyon geri yüklendi." -ForegroundColor Yellow
    }
    catch {
        Write-Host "❌ Rollback yapılamadı. Manuel müdahale gerekli." -ForegroundColor Red
    }
    
    exit 1
}

# Ana fonksiyon
function Main {
    Write-Host ""
    Write-Host "=== RANDEVU ERP BETA WEB DEPLOYMENT ===" -ForegroundColor Green
    Write-Host "Tarih: $(Get-Date)" -ForegroundColor Blue
    Write-Host "Versiyon: 1.0.0-beta.1" -ForegroundColor Blue
    Write-Host "Platform: Web (Firebase Hosting)" -ForegroundColor Blue
    Write-Host ""
    
    try {
        Test-Requirements
        Update-Dependencies
        Set-BetaConfig
        Build-Web
        Initialize-Firebase
        Deploy-ToFirebase
        Show-BetaInfo
        
        Write-Host ""
        Write-Host "🎉 Beta deployment başarıyla tamamlandı!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Hata oluştu: $($_.Exception.Message)" -ForegroundColor Red
        
        if (-not $Force) {
            $rollback = Read-Host "Rollback yapmak istiyor musunuz? (y/n)"
            if ($rollback -eq 'y' -or $rollback -eq 'Y') {
                Invoke-Rollback
            }
        }
        
        exit 1
    }
}

# Script'i çalıştır
Main 