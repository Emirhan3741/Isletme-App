# Google Sign-In ve Otomatik E-posta Sistemi Kurulum Rehberi

## 🚀 Genel Bakış

Randevu ERP uygulamasına Google ile giriş yapma özelliği ve otomatik karşılama e-postası sistemi eklenmiştir. Bu rehber kurulum ve test sürecini açıklar.

## 🔧 Eklenen Özellikler

### 1. Google Sign-In Entegrasyonu
- **Konum**: `lib/providers/auth_provider.dart`
- **Widget**: `lib/widgets/google_sign_in_button.dart`
- **Özellikler**:
  - Yeni kullanıcı otomatik Firestore'a kaydedilir
  - Mevcut kullanıcı bilgileri güncellenir
  - FCM token otomatik kaydedilir
  - Hoş geldin e-postası gönderilir

### 2. E-posta Servisi
- **Konum**: `lib/services/email_service.dart`
- **Özellikler**:
  - HTML tabanlı e-posta şablonları
  - Firestore e-posta geçmişi
  - Çoklu e-posta türü desteği
  - Production hazır yapı

### 3. UI Güncellemeleri
- **Login Sayfası**: `lib/screens/auth/login_page.dart`
- **Register Sayfası**: `lib/screens/auth/register_page.dart`
- **Ortak Widget**: `lib/widgets/google_sign_in_button.dart`

## 🔥 Firebase Console Konfigürasyonu

### Adım 1: Google Sign-In Etkinleştirme

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. **Authentication** → **Sign-in method** sekmesine gidin
3. **Google** sağlayıcısını bulun ve **Etkinleştir**'e tıklayın
4. **Project public-facing name** alanını doldurun: `Randevu ERP`
5. **Project support email** alanını doldurun
6. **Kaydet**'e tıklayın

### Adım 2: OAuth 2.0 İstemci Yapılandırması

#### Android İçin:
1. Firebase Console → **Project settings** → **General** sekmesi
2. Android uygulamanızı bulun ve **google-services.json**'ı indirin
3. Dosyayı `android/app/` klasörüne yerleştirin

```bash
# SHA-1 parmak izi alma (gerekirse)
cd android
./gradlew signingReport
```

#### iOS İçin:
1. Firebase Console → **Project settings** → **General** sekmesi
2. iOS uygulamanızı bulun ve **GoogleService-Info.plist**'i indirin
3. Dosyayı `ios/Runner/` klasörüne yerleştirin
4. Xcode'da projeye ekleyin

#### Web İçin:
1. Firebase Console → **Project settings** → **General** sekmesi
2. Web uygulamanızı ekleyin
3. Firebase SDK snippet'ini `web/index.html`'e ekleyin

## 📱 Platform Spesifik Konfigürasyon

### Android Konfigürasyonu

#### `android/app/build.gradle.kts`
```kotlin
// Zaten mevcut (kontrol edin)
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

#### `android/app/src/main/AndroidManifest.xml`
```xml
<!-- Google Sign-In için gerekli izin (zaten mevcut) -->
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS Konfigürasyonu

#### `ios/Runner/Info.plist`
```xml
<!-- URL Scheme ekleme gerekebilir -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**NOT**: `YOUR_REVERSED_CLIENT_ID`'yi GoogleService-Info.plist dosyasından alın.

## 🗄️ Firestore Veri Yapısı

### Kullanıcı Koleksiyonu (`users/{userId}`)
```javascript
{
  "id": "firebase_user_uid",
  "name": "John Doe",
  "email": "john@gmail.com",
  "role": "owner",
  "sector": "güzellik_salon",
  "createdAt": "2024-01-15T10:30:00Z",
  
  // Google Sign-In ek bilgileri
  "provider": "google",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "emailVerified": true,
  "lastSignInTime": "2024-01-15T10:30:00Z",
  
  // E-posta durumu
  "emails": {
    "welcomeSent": true,
    "welcomeSentAt": "2024-01-15T10:30:00Z"
  },
  
  // Adres bilgileri (register sonrası doldurulur)
  "country": "TR",
  "city": "İstanbul",
  "timeZone": "GMT+3"
}
```

### E-posta Geçmişi (`email_logs/{logId}`)
```javascript
{
  "userId": "firebase_user_uid",
  "userEmail": "john@gmail.com", 
  "emailType": "welcome",
  "subject": "Hoş Geldiniz - Randevu ERP",
  "contentLength": 2548,
  "sentAt": "2024-01-15T10:30:00Z",
  "status": "sent",
  "provider": "system"
}
```

## 🧪 Test Senaryoları

### Test 1: Yeni Kullanıcı Google Sign-In

1. **Başlangıç**: Temiz tarayıcı/uygulama
2. **Adımlar**:
   - Login sayfasını açın
   - "Google ile giriş yap" butonuna tıklayın
   - Google hesabınızı seçin ve onaylayın
3. **Beklenen Sonuç**:
   - Başarılı giriş mesajı
   - Dashboard'a yönlendirme
   - Firestore'da kullanıcı kaydı
   - Console'da hoş geldin e-postası logu

### Test 2: Mevcut Kullanıcı Google Sign-In

1. **Başlangıç**: Daha önce Google ile kayıt olmuş
2. **Adımlar**:
   - Çıkış yapın
   - Login sayfasında "Google ile giriş yap"
3. **Beklenen Sonuç**:
   - Hızlı giriş
   - Hoş geldin e-postası **gönderilmez**
   - lastSignInTime güncellenir

### Test 3: Register Sayfasından Google Sign-In

1. **Başlangıç**: Register sayfası
2. **Adımlar**:
   - "Google ile kayıt ol" butonuna tıklayın
3. **Beklenen Sonuç**:
   - Yeni kullanıcı için hoş geldin e-postası
   - Varsayılan rol: "owner"
   - Varsayılan sektör: "güzellik_salon"

### Test 4: E-posta Sistemi

1. **Kontrol Noktaları**:
   ```bash
   # Console logları kontrol edin
   Flutter: === HOŞ GELDİN E-POSTASI GÖNDERİLDİ ===
   Flutter: Alıcı: test@gmail.com
   Flutter: Konu: Hoş Geldiniz - Randevu ERP
   ```

2. **Firestore Kontrolleri**:
   - `email_logs` koleksiyonunda kayıt
   - `users/{uid}/emails/welcomeSent: true`

## 🔍 Debug ve Sorun Giderme

### Yaygın Sorunlar

#### 1. Google Sign-In Butonu Çalışmıyor
```bash
# Console hatalarını kontrol edin
adb logcat | grep -i google  # Android
# iOS: Xcode Console
```

**Çözümler**:
- SHA-1 parmak izini kontrol edin
- `google-services.json` güncel mi?
- Internet bağlantısı var mı?

#### 2. E-posta Gönderilmiyor
```dart
// Debug modunda console logları aktif
print('=== HOŞ GELDİN E-POSTASI GÖNDERİLDİ ===');
```

**Çözümler**:
- Firestore izinlerini kontrol edin
- E-posta adresi geçerli mi?
- Kullanıcı yeni mi? (isNewUser kontrolü)

#### 3. Firestore Yazma Hatası
```javascript
// Firestore Rules kontrol edin
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /email_logs/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Debug Araçları

#### 1. Firebase Console Monitoring
- Authentication → Users (yeni kullanıcılar)
- Firestore → Data (kullanıcı verileri)

#### 2. Flutter DevTools
```bash
# Detaylı log çıktısı
flutter run --verbose
```

#### 3. Test Komutları
```dart
// AuthProvider test
final authProvider = Provider.of<AuthProvider>(context, listen: false);
print('Current user: ${authProvider.user?.email}');
print('User provider: ${authProvider.getUserAuthProvider()}');

// E-posta servisi test
final emailService = EmailService();
final stats = await emailService.getEmailStats();
print('E-posta istatistikleri: $stats');
```

## 🚀 Production Hazırlık

### 1. E-posta Servisi Entegrasyonu

#### SendGrid Entegrasyonu
```dart
// lib/services/email_service.dart içinde
Future<bool> _sendEmailViaService(String to, String subject, String content) async {
  final response = await http.post(
    Uri.parse('https://api.sendgrid.com/v3/mail/send'),
    headers: {
      'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'personalizations': [
        {
          'to': [{'email': to}],
          'subject': subject
        }
      ],
      'from': {'email': 'noreply@randevu-erp.com', 'name': 'Randevu ERP'},
      'content': [
        {
          'type': 'text/html',
          'value': content
        }
      ]
    }),
  );
  
  return response.statusCode == 202;
}
```

#### SMTP Entegrasyonu
```yaml
# pubspec.yaml
dependencies:
  mailer: ^6.0.1
```

```dart
// SMTP örneği
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

final smtpServer = gmail('your-email@gmail.com', 'your-app-password');

final message = Message()
  ..from = Address('your-email@gmail.com', 'Randevu ERP')
  ..recipients.add(to)
  ..subject = subject
  ..html = content;

final sendReport = await send(message, smtpServer);
```

### 2. Güvenlik Ayarları

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar kendi verilerini okuyabilir/yazabilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // E-posta logları sadece okunabilir
    match /email_logs/{document} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow write: if request.auth != null; // Sistem tarafından yazılır
    }
  }
}
```

#### API Anahtarları
```dart
// lib/config/firebase_config.dart
class FirebaseConfig {
  static const String sendGridApiKey = String.fromEnvironment('SENDGRID_API_KEY');
  static const String appUrl = String.fromEnvironment('APP_URL', defaultValue: 'https://randevu-erp.web.app');
}
```

### 3. Performans Optimizasyonu

#### Batch İşlemler
```dart
// Çoklu kullanıcı kayıt için batch yazma
final batch = FirebaseFirestore.instance.batch();
batch.set(userRef, userData);
batch.set(emailLogRef, emailData);
await batch.commit();
```

#### Offline Desteği
```dart
// Firestore offline persistence
await FirebaseFirestore.instance.enablePersistence();
```

## 📈 İzleme ve Analitik

### Firebase Analytics Entegrasyonu
```dart
// Giriş eventi kaydet
await FirebaseAnalytics.instance.logLogin(loginMethod: 'google');

// Kayıt eventi kaydet  
await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'google');
```

### E-posta İstatistikleri
```dart
// Günlük e-posta raporu
final emailService = EmailService();
final stats = await emailService.getEmailStats();

print('Bugün gönderilen: ${stats['today']}');
print('Bu hafta gönderilen: ${stats['week']}');
print('Bu ay gönderilen: ${stats['month']}');
print('Toplam gönderilen: ${stats['total']}');
```

## 🔮 Gelecek Geliştirmeler

### 1. Çoklu Sağlayıcı Desteği
- Apple Sign-In
- Facebook Login
- Twitter/X Login
- Microsoft Account

### 2. Gelişmiş E-posta Özellikleri
- E-posta şablonu editörü
- Zamanlı e-posta gönderimi
- E-posta kampanyaları
- Otomatik takip e-postaları

### 3. Push Notification Entegrasyonu
- Welcome push bildirimi
- E-posta + Push kombinasyonu

## ⚠️ Önemli Notlar

1. **Güvenlik**: API anahtarlarını environment variables olarak kullanın
2. **Test**: Her platform için ayrı test yapın (Android, iOS, Web)
3. **Performans**: E-posta gönderimini asenkron yapın
4. **Uyumluluk**: Firebase SDK versiyonlarını güncel tutun
5. **Backup**: Firestore verilerini düzenli yedekleyin

## 📞 Destek

Bu rehberle ilgili sorularınız için:
- Firebase Console error logs
- Flutter DevTools network tab
- Firestore Debug mode

---
*Son güncelleme: 2024 - Google Sign-In & Email System v1.0* 