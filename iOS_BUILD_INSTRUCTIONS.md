# 🍏 iOS Build Talimatları

## Gereksinimler
- macOS işletim sistemi
- Xcode 15+ kurulu
- iOS Developer hesabı (opsiyonel, test için)

## Firebase Konfigürasyonu Eksik!
⚠️ **ÖNEMLİ**: `ios/Runner/GoogleService-Info.plist` dosyası eksik!

### GoogleService-Info.plist Ekleme:
1. Firebase Console → Project Settings → iOS app
2. GoogleService-Info.plist dosyasını indir
3. `ios/Runner/` klasörüne kopyala
4. Xcode'da projeye ekle

## iOS Build Komutları (macOS'ta çalıştırın):

### 1. iOS Debug Build
```bash
cd /path/to/randevu_erp
flutter build ios --debug
```

### 2. Xcode ile Cihazda Test
```bash
open ios/Runner.xcworkspace
```

### 3. IPA Dosyası Oluşturma (TestFlight için)
```bash
flutter build ipa --debug
# Çıktı: build/ios/ipa/
```

## Xcode Ayarları:

### Bundle Identifier
`Runner.xcworkspace` → Runner → Signing & Capabilities
- Bundle Identifier: `com.example.randevuErp` (veya özel domain)

### Team ID
- Development Team: Apple Developer hesabınızı seçin
- Automatically manage signing: ✅

### Deployment Target
- iOS Deployment Target: 12.0+

## Test Etme:
1. iOS cihazı USB ile bağlayın
2. Xcode'da Target Device olarak cihazınızı seçin
3. ▶️ Run butonuna basın

## Sorun Giderme:
- **Signing hatası**: Apple ID ekleyin ve otomatik signing açın
- **GoogleService-Info.plist**: Firebase'den indirip ekleyin
- **Build hatası**: `flutter clean && flutter pub get` çalıştırın 