# Firebase Cloud Messaging (FCM) Test Rehberi

## 🚀 Firebase Console'dan Test Bildirimi Gönderme

### 1. Firebase Console'a Erişim
1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. `randevu-takip-app` projenizi seçin
3. Sol menüden **Messaging** seçeneğine tıklayın

### 2. Yeni Kampanya Oluşturma
1. **Create your first campaign** veya **New campaign** butonuna tıklayın
2. **Firebase Notification messages** seçeneğini seçin
3. **Create** butonuna tıklayın

### 3. Bildirim Detaylarını Doldurma

#### Notification Sekmesi:
- **Notification title**: `Randevu Hatırlatması`
- **Notification text**: `Yaklaşan randevunuz için hatırlatma`
- **Notification image** (opsiyonel): Resim URL'si ekleyebilirsiniz

#### Target Sekmesi:
- **App**: `randevu_erp` uygulamanızı seçin
- **Hedef türü**:
  - **All users**: Tüm kullanıcılara gönder
  - **User segment**: Belirli kullanıcı gruplarına
  - **Single device**: Tek cihaza (test için önerilen)

#### Single Device Test İçin:
1. **Single device** seçeneğini işaretleyin
2. **FCM registration token** alanına test token'ı girin

### 4. FCM Token'ı Nasıl Bulunur?

#### Flutter Uygulamasından:
1. Uygulamayı çalıştırın
2. Login olun
3. Debug console'da şu log'u arayın:
   ```
   FCM Token: fxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

#### Firebase Firestore'dan:
1. Firebase Console → Firestore Database
2. `user_tokens` koleksiyonunu açın
3. Kullanıcı ID'nize ait dokümanı bulun
4. `fcmToken` alanındaki değeri kopyalayın

### 5. Scheduling (Zamanlama)
- **Now**: Hemen gönder
- **Schedule**: Belirli bir zamanda gönder

### 6. Additional Options (Ek Seçenekler)

#### Advanced Seçenekleri:
- **Android notification channel**: `randevu_erp_channel`
- **Sound**: `default` veya özel ses dosyası
- **Priority**: `high` (önerilen)
- **TTL**: Mesajın geçerlilik süresi

#### Custom Data (Özel Veri):
Key-Value çiftleri ekleyebilirsiniz:
- `type`: `appointment`
- `id`: `123`
- `action`: `open_calendar`

### 7. Test Bildirimi Gönderme
1. **Review** sekmesinde detayları kontrol edin
2. **Publish** butonuna tıklayarak bildirimi gönderin

## 📱 Test Senaryoları

### Senaryo 1: Uygulama Ön Planda
- ✅ Bildirim alınmalı ve local notification gösterilmeli
- ✅ Bildirime tıklandığında uygun sayfaya yönlendirme yapılmalı

### Senaryo 2: Uygulama Arka Planda
- ✅ System notification gösterilmeli
- ✅ Bildirime tıklandığında uygulama açılmalı ve yönlendirme yapılmalı

### Senaryo 3: Uygulama Kapalı
- ✅ System notification gösterilmeli
- ✅ Bildirime tıklandığında uygulama açılmalı ve initial message handle edilmeli

## 🛠️ Debug İpuçları

### FCM Token Kontrolü:
```dart
// NotificationService içinde bu kodu çalıştırın
final token = await FirebaseMessaging.instance.getToken();
print('Current FCM Token: $token');
```

### Message Logları:
```dart
// main.dart içinde background handler loglarını kontrol edin
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message alındı: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}
```

### Notification Permissions:
```dart
// Permission durumunu kontrol etmek için
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Permission durumu: ${settings.authorizationStatus}');
```

## 🎯 Topic Tabanlı Bildirim Testi

### Topic'e Abone Olma:
```dart
await FirebaseMessaging.instance.subscribeToTopic('beauty_salon');
await FirebaseMessaging.instance.subscribeToTopic('company_123');
```

### Firebase Console'dan Topic'e Mesaj Gönderme:
1. **Target** sekmesinde **Topic** seçin
2. Topic adını girin (örn: `beauty_salon`)
3. Bildirimi gönderin

## 📋 Test Checklist

- [ ] FCM token başarıyla alınıyor
- [ ] Token Firestore'a kaydediliyor
- [ ] Uygulama ön plandayken bildirim alınıyor
- [ ] Uygulama arka plandayken bildirim alınıyor
- [ ] Uygulama kapalıyken bildirim alınıyor
- [ ] Bildirime tıklandığında doğru sayfaya yönlendiriliyor
- [ ] Background handler çalışıyor
- [ ] Topic aboneliği çalışıyor
- [ ] Android ve iOS'ta test edildi

## 🔧 Sorun Giderme

### Bildirim Gelmiyor:
1. FCM token'ın doğru olduğunu kontrol edin
2. Firebase project konfigürasyonunu kontrol edin
3. `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarının güncel olduğunu kontrol edin
4. Internet bağlantısını kontrol edin
5. Notification permissions verdiğinizden emin olun

### Android Spesifik Sorunlar:
- `POST_NOTIFICATIONS` izni Android 13+ için gerekli
- Notification channel tanımlandığından emin olun
- Google Play Services güncel olmalı

### iOS Spesifik Sorunlar:
- APNs sertifikası Firebase'de tanımlanmalı
- Provisioning profile push notification enabled olmalı
- iOS Simulator'da push notification çalışmaz (fiziksel cihaz gerekli)

## 📞 İletişim ve Destek

Bu rehberle ilgili sorularınız için geliştirici ekibiyle iletişime geçebilirsiniz.

---
*Son güncelleme: 2024* 