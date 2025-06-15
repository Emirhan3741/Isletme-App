# 🚀 Randevu ERP - Deployment Rehberi

## 📋 Ön Hazırlık

### 1. Gerekli Araçlar
```bash
# Flutter SDK (3.8.1+)
flutter --version

# Firebase CLI
npm install -g firebase-tools
firebase --version

# Android Studio (APK için)
# Visual Studio Code (geliştirme için)
```

### 2. Proje Hazırlığı
```bash
# Bağımlılıkları yükle
flutter pub get

# Kod analizi
flutter analyze

# Test çalıştır
flutter test
```

## 🌐 Web Deployment (Firebase Hosting)

### 1. Firebase Projesi Kurulumu
```bash
# Firebase'e giriş yap
firebase login

# Proje başlat (eğer yoksa)
firebase init hosting

# Mevcut proje ile bağla
firebase use randevu-takip-app
```

### 2. Web Build ve Deploy
```bash
# Web build
flutter build web --release --web-renderer html

# Firebase'e deploy
firebase deploy --only hosting

# Özel domain ile deploy
firebase deploy --only hosting --project production
```

### 3. PWA Özellikleri
- ✅ Offline çalışma
- ✅ Ana ekrana ekleme
- ✅ Push notifications
- ✅ Responsive tasarım

## 📱 Android Deployment

### 1. APK Build (Test için)
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK (daha küçük boyut)
flutter build apk --release --split-per-abi
```

### 2. App Bundle (Google Play için)
```bash
# Release App Bundle
flutter build appbundle --release

# Dosya konumu: build/app/outputs/bundle/release/app-release.aab
```

### 3. Google Play Console
1. **Developer hesabı oluştur** ($25 tek seferlik)
2. **Uygulama oluştur**
   - Uygulama adı: "Randevu ERP"
   - Kategori: Business
   - Hedef kitle: İşletmeler
3. **App Bundle yükle**
4. **Store listing hazırla**
5. **İnceleme için gönder**

## 🖥️ Windows Desktop

### 1. Windows Build
```bash
# Windows executable
flutter build windows --release

# Dosya konumu: build/windows/runner/Release/
```

### 2. Installer Oluşturma
```bash
# Inno Setup veya NSIS kullan
# Installer script örneği: scripts/windows_installer.iss
```

## 🔐 Güvenlik Konfigürasyonu

### 1. Firebase Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı bazlı erişim kontrolü
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Owner rolü kontrolü
    function isOwner() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.rol == 'owner';
    }
  }
}
```

### 2. Environment Variables
```dart
// lib/config/environment.dart
class Environment {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'localhost');
}
```

## 📊 Performance Optimizasyonu

### 1. Build Optimizasyonu
```bash
# Web için optimize build
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false

# Android için optimize build
flutter build apk --release --shrink --obfuscate --split-debug-info=build/debug-info
```

### 2. Bundle Analizi
```bash
# Bundle boyutunu analiz et
flutter build apk --analyze-size

# Web bundle analizi
flutter build web --analyze-size
```

## 🔄 CI/CD Pipeline

### 1. GitHub Actions (.github/workflows/deploy.yml)
```yaml
name: Deploy to Firebase
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: randevu-takip-app
```

## 📈 Monitoring ve Analytics

### 1. Firebase Analytics
```dart
// lib/services/analytics_service.dart
await FirebaseAnalytics.instance.logEvent(
  name: 'user_action',
  parameters: {
    'action_type': 'create_appointment',
    'user_role': userRole,
  },
);
```

### 2. Crashlytics
```dart
// lib/main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

## 🎯 Deployment Checklist

### Pre-Deployment
- [ ] Kod analizi temiz
- [ ] Tüm testler geçiyor
- [ ] Firebase kuralları güncel
- [ ] Environment variables ayarlandı
- [ ] Debug kodları temizlendi

### Web Deployment
- [ ] PWA manifest güncel
- [ ] Service worker çalışıyor
- [ ] SEO meta tags ekli
- [ ] Performance optimize
- [ ] Firebase hosting konfigürasyonu

### Mobile Deployment
- [ ] App signing konfigürasyonu
- [ ] Store listing hazır
- [ ] Screenshots ve açıklamalar
- [ ] Privacy policy linki
- [ ] Terms of service

### Post-Deployment
- [ ] Functionality test
- [ ] Performance monitoring
- [ ] User feedback toplama
- [ ] Analytics kontrol
- [ ] Error tracking

## 🌍 Multi-Platform Deployment

### 1. Tek Komutla Deploy
```bash
# Tüm platformlar için build
./scripts/build_release.bat

# Veya Linux/Mac için
./scripts/build_release.sh
```

### 2. Platform Specific Configs
```dart
// lib/config/platform_config.dart
class PlatformConfig {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isWindows => Platform.isWindows;
  
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    return 'Unknown';
  }
}
```

## 📞 Support ve Maintenance

### 1. Update Strategy
- **Minor updates**: Haftalık
- **Major updates**: Aylık
- **Security patches**: Acil

### 2. Backup Strategy
- **Firestore**: Otomatik günlük backup
- **User data**: Export özelliği
- **App data**: Cloud storage

### 3. Rollback Plan
```bash
# Firebase hosting rollback
firebase hosting:clone SOURCE_SITE_ID:SOURCE_VERSION_ID TARGET_SITE_ID

# Android rollback
# Google Play Console'dan önceki versiyonu aktif et
```

## 🎉 Go Live!

### Final Steps
1. **Domain bağla** (opsiyonel)
2. **SSL sertifikası** kontrol et
3. **Performance test** yap
4. **User training** materyalleri hazırla
5. **Support channels** kur

### Success Metrics
- **Page load time**: < 3 saniye
- **App startup time**: < 2 saniye
- **Crash rate**: < 1%
- **User satisfaction**: > 4.5/5

---

## 🔗 Faydalı Linkler

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [Google Play Console](https://play.google.com/console)
- [PWA Best Practices](https://web.dev/pwa-checklist/)

**🎯 Başarılar! Randevu ERP sisteminiz artık yayında!** 