# Flutter Projesi Taşıma Scripti
# Türkçe karakter sorunu nedeniyle projeyi C:\Projects\randevu_erp klasörüne taşır

Write-Host "Flutter Projesi Tasima Baslaniyor..." -ForegroundColor Green

# Hedef klasörü oluştur
$targetPath = "C:\Projects\randevu_erp"
Write-Host "Hedef klasor olusturuluyor: $targetPath" -ForegroundColor Yellow

if (!(Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force
    Write-Host "Klasor olusturuldu." -ForegroundColor Green
} else {
    Write-Host "Klasor zaten mevcut." -ForegroundColor Yellow
}

# Mevcut konumu al
$currentPath = Get-Location

Write-Host "Mevcut konum: $currentPath" -ForegroundColor Yellow
Write-Host "Dosyalar kopyalaniyor..." -ForegroundColor Yellow

# Tüm dosyaları kopyala (build ve .dart_tool hariç)
$excludeFolders = @(".dart_tool", "build", ".idea")
$items = Get-ChildItem -Path $currentPath -Exclude $excludeFolders

foreach ($item in $items) {
    $targetItem = Join-Path $targetPath $item.Name
    if ($item.PSIsContainer) {
        Write-Host "Klasor kopyalaniyor: $($item.Name)" -ForegroundColor Cyan
        Copy-Item -Path $item.FullName -Destination $targetItem -Recurse -Force
    } else {
        Write-Host "Dosya kopyalaniyor: $($item.Name)" -ForegroundColor Cyan
        Copy-Item -Path $item.FullName -Destination $targetItem -Force
    }
}

Write-Host "Tum dosyalar basariyla kopyalandi!" -ForegroundColor Green
Write-Host "Yeni proje konumu: $targetPath" -ForegroundColor Green
Write-Host "" 
Write-Host "Sonraki adimlar:" -ForegroundColor Yellow
Write-Host "1. cd C:\Projects\randevu_erp" -ForegroundColor White
Write-Host "2. flutter clean && flutter pub get" -ForegroundColor White
Write-Host "3. flutter build windows" -ForegroundColor White

pause 