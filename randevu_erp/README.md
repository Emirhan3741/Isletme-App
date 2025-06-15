# Randevu ERP

Modern ve responsive Flutter tabanlı randevu yönetim sistemi. Web ve mobil platformlarda çalışır.

## 🚀 Özellikler

### ✅ Tamamlanan Modüller
- **🔐 Kimlik Doğrulama Sistemi**
  - E-posta/şifre ile giriş ve kayıt
  - Google ile giriş
  - Şifre sıfırlama
  - Otomatik oturum yönetimi

- **📱 Responsive Tasarım**
  - Web ve mobil uyumlu arayüz
  - Material Design 3
  - Koyu/açık tema desteği
  - Responsive navigation

- **🏠 Dashboard**
  - Hoşgeldin ekranı
  - İstatistik kartları (gerçek verilerle)
  - Hızlı işlem butonları
  - Bildirim sistemi

- **👥 Müşteri Yönetimi**
  - Müşteri ekleme/düzenleme/silme
  - Arama ve filtreleme
  - Telefon numarası formatlaması
  - Müşteri detay görüntüleme
  - Kullanıcı bazlı yetkilendirme

- **📅 Randevu Takvimi** *(YENİ!)*
  - Aylık/haftalık/günlük takvim görünümü
  - Randevu ekleme/düzenleme/silme
  - Çakışan randevu kontrolü
  - Müşteri seçimi ve işlem tanımlama
  - Randevu arama ve filtreleme
  - Kullanıcı bazlı yetkilendirme

### 🔄 Gelecek Modüller
- **💰 İşlem ve Ödeme**
- **📊 Gider ve Hatırlatıcı**
- **📝 Notlar / To-do**
- **📈 Raporlama ve Admin Paneli**

## 🛠️ Teknolojiler

- **Flutter** - Cross-platform framework
- **Firebase** - Backend servisleri
  - Authentication
  - Firestore Database
  - Cloud Storage
- **Provider** - State management
- **Material Design 3** - UI/UX

## 📦 Bağımlılıklar

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.4
  cloud_firestore: ^5.6.8
  google_sign_in: ^6.3.0
  provider: ^6.1.5
  flutter_local_notifications: ^14.1.1
  intl: ^0.18.1
  table_calendar: ^3.0.9
  cupertino_icons: ^1.0.8
```

## 🚀 Kurulum

### Ön Gereksinimler
- Flutter SDK (3.8.1+)
- Firebase projesi
- Android Studio / VS Code

### Adımlar

1. **Projeyi klonlayın**
   ```bash
   git clone <repository-url>
   cd randevu_erp
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Firebase yapılandırması**
   ```bash
   # Firebase CLI kurulumu
   npm install -g firebase-tools
   
   # Firebase'e giriş
   firebase login
   
   # FlutterFire CLI kurulumu
   dart pub global activate flutterfire_cli
   
   # Firebase projesi yapılandırması
   flutterfire configure
   ```

4. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama dosyası
├── firebase_options.dart     # Firebase yapılandırması
├── screens/                  # Ekran dosyaları
│   ├── auth/                # Kimlik doğrulama ekranları
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   ├── dashboard/           # Dashboard ekranları
│   │   └── dashboard_page.dart
│   ├── customers/           # Müşteri yönetimi ekranları
│   │   ├── customer_list_page.dart
│   │   └── add_edit_customer_page.dart
│   ├── appointments/        # Randevu yönetimi ekranları
│   │   ├── calendar_page.dart
│   │   └── add_edit_appointment_page.dart
│   └── auth_wrapper.dart    # Auth durumu kontrolü
├── services/                # Servis dosyaları
│   ├── auth_service.dart    # Kimlik doğrulama servisi
│   ├── customer_service.dart # Müşteri yönetimi servisi
│   └── appointment_service.dart # Randevu yönetimi servisi
├── models/                  # Veri modelleri
│   ├── user_model.dart      # Kullanıcı modeli
│   ├── customer_model.dart  # Müşteri modeli
│   └── appointment_model.dart # Randevu modeli
└── providers/               # State management
    └── auth_provider.dart   # Auth provider
```

## 🔧 Firebase Yapılandırması

### 1. Firebase Console'da Proje Oluşturma
1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Yeni proje oluşturun
3. Authentication ve Firestore'u etkinleştirin

### 2. Authentication Ayarları
- **Sign-in methods** bölümünden:
  - Email/Password'ü etkinleştirin
  - Google'ı etkinleştirin

### 3. Firestore Kuralları
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar sadece kendi verilerini okuyabilir/yazabilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Müşteriler - sadece ekleyen kullanıcı erişebilir
    match /customers/{customerId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.ekleyenKullaniciId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.ekleyenKullaniciId;
    }
    
    // Randevular - sadece oluşturan çalışan erişebilir
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.calisanId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.calisanId;
    }
  }
}
```

## 🎨 Tema ve Tasarım

Uygulama Material Design 3 kullanır ve şu özelliklere sahiptir:

- **Ana Renk**: Blue (#1976D2)
- **Responsive Tasarım**: Web ve mobil uyumlu
- **Koyu/Açık Tema**: Sistem temasını takip eder
- **Modern UI**: Rounded corners, elevation, animations

## 📱 Platform Desteği

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)

## 🔐 Güvenlik

- Firebase Authentication ile güvenli giriş
- Firestore güvenlik kuralları
- Input validation
- Error handling
- Secure storage

## 🚀 Deployment

### Web
```bash
flutter build web
```

### Android
```bash
flutter build apk --release
# veya
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

Proje hakkında sorularınız için issue açabilirsiniz.

---

**Not**: Bu proje aktif geliştirme aşamasındadır. Yeni özellikler düzenli olarak eklenmektedir.
