# 🚀 RANDEVU ERP → LOCAPO MİGRATİON REHBERİ

## 📋 ÖZET
Bu rehber Randevu ERP projesini `C:\Projects\locapo` klasörüne güvenli şekilde taşıma işlemini açıklar.

## ⚡ HIZLI BAŞLATMA

### 1. Otomatik Migration (Önerilen)
```bash
# Mevcut proje klasöründe çalıştırın
migrate_to_locapo.bat
```

### 2. Post-Migration Setup
```powershell
# Migration sonrası konfigürasyon
powershell -ExecutionPolicy Bypass -File post_migration_setup.ps1
```

### 3. Test
```bash
cd C:\Projects\locapo
locato.baslat.bat
```

## 🔧 DETAYLI ADIMLAR

### Adım 1: Migration Script Çalıştırma
1. **Mevcut proje klasöründe** (`C:\Users\ADMİN\randevu_erp`) terminal açın
2. `migrate_to_locapo.bat` çalıştırın
3. Backup seçeneğini belirleyin (önerilen: Yes)

### Adım 2: Konfigürasyon Güncellemesi
1. `powershell -ExecutionPolicy Bypass -File post_migration_setup.ps1` çalıştırın
2. Otomatik güncellemeleri bekleyin

### Adım 3: Test ve Doğrulama
1. `cd C:\Projects\locapo`
2. `flutter clean && flutter pub get`
3. `flutter run -d chrome`

## 📁 YAPILAN DEĞİŞİKLİKLER

### Proje Konfigürasyonu
- **Proje Adı**: `randevu_erp` → `locapo`
- **Android Package**: `com.example.randevu_erp` → `com.projects.locapo`
- **iOS Bundle ID**: `com.example.randevuErp` → `com.projects.locapo`

### Dosya Güncellemeleri
- `pubspec.yaml` - proje adı ve açıklama
- `android/app/build.gradle.kts` - package name
- `android/app/src/main/AndroidManifest.xml` - package name
- `ios/Runner/Info.plist` - bundle identifier
- Tüm `.bat` dosyaları - referanslar güncellendi

### Korunan Ayarlar
- 🔑 **VAPID Key**: `BJ7LMlB1LNtAVtiqk5C_nvzANRpKoLgncFChYu36X3NeClE0H-EcINhS9MFTCSuNanHkitPwdMUI7uX_cEk4Xno`
- 🔥 **Firebase Konfigürasyonu**: Değişmedi
- 🎨 **UI/UX**: Korundu
- 📊 **Veri Modelleri**: Korundu

## 🚨 ÖNEMLİ NOTLAR

### Migration Öncesi
- [ ] Mevcut projeyi commit edin (git)
- [ ] Önemli dosyaları yedekleyin
- [ ] Çalışan terminal/VS Code'u kapatın

### Migration Sonrası
- [ ] Yeni klasörde VS Code açın: `code C:\Projects\locapo`
- [ ] Terminal'de doğru klasörde olduğunuzu kontrol edin
- [ ] Firebase proje ayarları değişmedi
- [ ] Google Auth şifreleri korundu

## 🛠️ SORUN GİDERME

### Compile Hataları
```bash
# Analiz çalıştır
flutter analyze

# Dependencies yenile
flutter clean
flutter pub get

# Cache temizle
flutter pub deps
```

### Migration Hatası
1. **Manuel Kopyalama**:
   ```bash
   xcopy "C:\Users\ADMİN\randevu_erp" "C:\Projects\locapo" /E /I
   ```

2. **Konfigürasyon Manuel Güncelleme**:
   - `pubspec.yaml` → name değiştir
   - Android → package name güncelle
   - iOS → bundle ID güncelle

### Çalışma Dizini Hatası
```bash
# Doğru klasöre git
cd /d C:\Projects\locapo

# Proje kontrolü
dir pubspec.yaml
```

## 📞 DESTEK

### Migration Tamamlandıktan Sonra
- ✅ Proje `C:\Projects\locapo` klasöründe
- ✅ Tüm konfigürasyonlar güncellendi
- ✅ VAPID key korundu
- ✅ Firebase ayarları korundu

### Test Komutları
```bash
# Quick start
cd C:\Projects\locapo
quick_start.bat

# Full test
test_complete.bat

# Manuel start
flutter run -d chrome --web-port 3000
```

## 🎯 SONUÇ

Migration tamamlandığında:
1. **Eski Lokasyon**: `C:\Users\ADMİN\randevu_erp` (backup)
2. **Yeni Lokasyon**: `C:\Projects\locapo` (aktif)
3. **Konfigürasyon**: Otomatik güncellendi
4. **Firebase**: Değişmedi, çalışmaya devam eder

---

**✨ Migration başarılı! Artık LOCAPO olarak `C:\Projects\locapo` klasöründe çalışmaya devam edebilirsiniz.**