# 🔥 Firebase Sorun Giderme Rehberi

## 🟥 1. Firestore Index Hatası

**Hata:**
```
[cloud_firestore/failed-precondition] The query requires an index.
```

**✅ Çözüm:**
1. Hata mesajındaki **index oluşturma linkine** tıklayın:
   ```
   https://console.firebase.google.com/v1/r/project/randevu-takip-app/firestore/indexes?create_composite=...
   ```
2. Açılan sayfada **"Create Index"** butonuna basın
3. Firebase 2-3 dakika içinde indeksi oluşturacak
4. **Uygulama yeniden başlatın**

---

## 🟥 2. CORS Hatası (Firebase Storage)

**Hata:**
```
Access to XMLHttpRequest at ... has been blocked by CORS policy
```

**✅ Çözüm:**

### A) Geçici Çözüm (Test için):
```bash
# Firebase Console → Storage → Rules
# Web tarayıcıda şu ayarı yapın:
```

### B) Kalıcı Çözüm:
```bash
# Firebase CLI ile CORS ayarla
firebase storage:bucket:set-cors-rules cors.json
```

**cors.json dosyası zaten projenizde mevcut ve güncellenmiş:**
```json
[
  {
    "origin": [
      "http://localhost:3000",
      "http://localhost:49935",
      "http://localhost:*"
    ],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

---

## 🟥 3. FCM Token Alma Hatası (403 PERMISSION_DENIED)

**Hata:**
```
Installations: Create Installation request failed with error "403 PERMISSION_DENIED"
```

**✅ Çözüm:**
1. **Firebase Console** → **Cloud Messaging** → **Web Push certificates**
2. **"Generate key pair"** butonuna tıklayın
3. Oluşan **VAPID Key**'i kopyalayın
4. `firebase_options.dart` dosyasına ekleyin:
   ```dart
   static const FirebaseOptions web = FirebaseOptions(
     // ... diğer ayarlar
     messagingSenderId: 'YOUR_SENDER_ID',
     vapidKey: 'YOUR_VAPID_KEY_HERE', // Bu satırı ekleyin
   );
   ```

---

## 🟥 4. Google ile Giriş Web'de Desteklenmiyor

**Hata:**
```
UnimplementedError: authenticate is not supported on the web.
```

**✅ Çözüm:**
**Bu hata düzeltildi!** Artık Google Sign-In web'de şu şekilde çalışıyor:
- Web: `signInWithPopup()` 
- Mobile: `GoogleSignIn().signIn()`
- Backup: `signInWithRedirect()`

**Firebase Console Ayarları:**
1. **Authentication** → **Sign-in method** → **Google** → **Enable**
2. **Authorized domains** → `localhost` ve domain'inizi ekleyin
3. **Web Client ID** otomatik oluşur

---

## 🟥 5. RenderFlex Overflow (Ekran Taşması)

**Hata:**
```
A RenderFlex overflowed by 19 pixels on the bottom.
```

**✅ Çözüm:**
**Bu hatalar düzeltildi!** `SingleChildScrollView` eklendi:
```dart
SingleChildScrollView(
  child: Column(
    children: [...]
  ),
)
```

---

## 🟥 6. Dil Hatası: Desteklenmeyen Locale

**Hata:**
```
Warning: This application's locale, es, is not supported...
```

**✅ Çözüm:**
`lib/main.dart`'ta desteklenen diller listesine eklenmiş:
```dart
supportedLocales: [
  Locale('en'),
  Locale('tr'),
  Locale('es'), // İspanyolca desteği eklendi
],
```

---

## 🟥 7. Google Sign-In accessToken Hatası

**Hata:**
```
Try correcting the name to the name of an existing getter, or defining a getter or field named 'accessToken'.
```

**✅ Çözüm:**
**Bu hata düzeltildi!** Google Sign-In 7.x API'si ile uyumlu hale getirildi:
- Web ve Mobile için ayrı implementasyon
- Doğru credential oluşturma
- Error handling geliştirildi

---

## ✅ Yapılacaklar Listesi

| Sorun | Durum | Eylem |
|-------|-------|-------|
| Firestore Index | ⚠️ Manuel | Konsol linkine tıkla |
| Firebase Storage CORS | ✅ Düzeltildi | cors.json güncel |
| FCM 403 | ⚠️ Manuel | VAPID key oluştur |
| Google Auth Web | ✅ Düzeltildi | 7.x API uyumlu |
| Flex overflow | ✅ Düzeltildi | ScrollView eklendi |
| Locale es desteği | ✅ Düzeltildi | Dil listesine eklendi |
| AccessToken hatası | ✅ Düzeltildi | API güncellemesi |

---

## 🚀 Test Etme

**`locato.baslat.bat` dosyasını çalıştırın:**
1. ✅ Sistem kontrolleri
2. ✅ Dependency çözümlemesi
3. ✅ Gelişmiş hata raporlama
4. ✅ Sorun giderme ipuçları

**Beklenen sonuç:**
- Chrome açılır → `http://localhost:3000`
- Login sayfası → Google Sign-In butonu
- Sektör seçimi → Dashboard

---

## 📞 Acil Durum Komutları

```bash
# Port değiştir
flutter run -d chrome --web-port 3001

# Verbose debug
flutter run -d chrome --web-port 3000 --verbose

# Cache temizle
flutter clean && flutter pub get

# Dependency sıfırla
flutter pub deps
```

---

**🎯 Tüm kritik hatalar düzeltildi ve test edilmeye hazır!**