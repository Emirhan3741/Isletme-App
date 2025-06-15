# 🚀 Windows Build Rehberi - Randevu ERP

Bu rehber, Flutter projesini Windows'ta sorunsuz bir şekilde derlemek için gerekli adımları içerir.

## 🛠️ Ön Hazırlık

### 1. Projeyi Türkçe Karakter İçermeyen Klasöre Taşıma

**Sorun:** `C:\Users\ADMİN` gibi Türkçe karakter içeren yollar CMake ve Flutter build sürecinde hatalara neden olur.

**Çözüm:** Projeyi `C:\Projects\randevu_erp` klasörüne taşıyın.

```powershell
# PowerShell'i Yönetici olarak çalıştırın ve aşağıdaki komutu çalıştırın:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\move_to_projects.ps1
```

### 2. Yeni Konuma Geçiş

```cmd
cd C:\Projects\randevu_erp
```

## 🔧 Build Scripts

Projede 3 farklı script bulunmaktadır:

### 1. `clean_project.bat` - Proje Temizleme

```cmd
clean_project.bat
```

Bu script şunları yapar:
- `build/` klasörünü siler
- `.dart_tool/` klasörünü siler  
- `.idea/` klasörünü siler
- `.packages` dosyasını siler
- `pubspec.lock` dosyasını siler
- `flutter clean` komutunu çalıştırır

### 2. `build_release.bat` - Windows Build

```cmd
build_release.bat
```

Bu script şunları yapar:
- `flutter clean` - Projeyi temizler
- `flutter pub get` - Bağımlılıkları yükler
- `flutter build windows --release` - Windows .exe dosyasını oluşturur

**Build sonucu:** `build\windows\x64\runner\Release\randevu_erp.exe`

## 🎯 Hızlı Başlangıç

1. **İlk Kurulum:**
```cmd
cd C:\Projects\randevu_erp
clean_project.bat
```

2. **Build İşlemi:**
```cmd
build_release.bat
```

3. **Uygulamayı Çalıştırma:**
```cmd
build\windows\x64\runner\Release\randevu_erp.exe
```

## 🔍 Sorun Giderme

### CMake Hatası
Eğer CMake hatası alırsanız:
- Visual Studio 2019 veya 2022'nin yüklü olduğundan emin olun
- Windows SDK'nın yüklü olduğunu kontrol edin

### Flutter Komutu Bulunamadı
Eğer `flutter` komutu tanınmıyorsa:
- Flutter SDK'nın PATH'e eklendiğinden emin olun
- PowerShell'i yeniden başlatın

### Firebase Hatası
Firebase bağlantı hatası alırsanız:
- `firebase_options.dart` dosyasının doğru yapılandırıldığından emin olun
- Internet bağlantınızı kontrol edin

## 📁 Build Çıktıları

Başarılı build sonrası şu dosyalar oluşur:

```
build/windows/x64/runner/Release/
├── randevu_erp.exe          # Ana uygulama
├── flutter_windows.dll     # Flutter runtime
├── data/                    # Uygulama verileri
│   ├── icudtl.dat
│   ├── flutter_assets/
│   └── app.so
└── ...                      # Diğer destekleyici dosyalar
```

## 🚀 Dağıtım

Uygulamayı dağıtmak için `build/windows/x64/runner/Release/` klasörünün tamamını kopyalayın.

**Not:** Tüm dosyalar birlikte olmak zorundadır, sadece .exe dosyası yeterli değildir.

## 💡 İpuçları

- Build öncesi her zaman `clean_project.bat` çalıştırın
- Büyük değişikliklerden sonra tam temizlik yapın
- Release modunda build edin (daha küçük ve hızlı)
- Antivirus yazılımını geçici olarak devre dışı bırakabilirsiniz

---

**Son Güncelleme:** $(Get-Date)
**Flutter Version:** En son stabil sürüm önerilir 