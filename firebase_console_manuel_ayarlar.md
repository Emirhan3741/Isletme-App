# 🔥 Firebase Console Manuel Ayarları - KRİTİK ADIMLAR

## ⚠️ **ÖNEMLİ:** Bu adımlar Firebase Console'da MUTLAKA yapılmalı!

### 1️⃣ **Firebase Cloud Messaging 403 Hatası - Cloud Messaging API Legacy**

📍 **Firebase Console → randevu-takip-app → ⚙️ Project Settings → Cloud Messaging**

✅ **Yapılacaklar:**
1. **Cloud Messaging API (Legacy)** → **ENABLE** yap
2. **Server key** kopyala (ihtiyaç durumunda)
3. **Sender ID:** `308323114774` (doğru mu kontrol et)

### 2️⃣ **IAM Permissions - Service Account Yetkileri**

📍 **Google Cloud Console → IAM & Admin → IAM**

✅ **firebase-adminsdk-xxx@randevu-takip-app.iam.gserviceaccount.com** için:
- ✅ **Firebase Admin SDK Admin Service Agent** 
- ✅ **Firebase Cloud Messaging Sender**
- ✅ **Service Account Token Creator**

### 3️⃣ **Firebase Storage CORS Kuralları**

📍 **Firebase Console → Storage → Rules**

**Manuel CORS ekle:**
```json
[
  {
    "origin": [
      "http://localhost:57813",
      "http://127.0.0.1:57813", 
      "http://localhost:3000",
      "http://localhost:8080",
      "https://randevu-takip-app.firebaseapp.com",
      "https://randevu-takip-app.web.app"
    ],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization", "x-goog-resumable"]
  }
]
```

### 4️⃣ **Firestore Security Rules - Geçici Açık Erişim**

📍 **Firebase Console → Firestore Database → Rules**

**GEÇİCİ olarak tüm erişimi aç:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // ⚠️ SADECE TEST İÇİN!
    }
  }
}
```

**⚠️ ÖNEMLİ:** Production'da gerçek güvenlik kuralları yaz!

### 5️⃣ **Firebase Authentication - Anonymous Auth**

📍 **Firebase Console → Authentication → Sign-in method**

✅ **Anonymous** provider'ı aktifleştir (Storage erişimi için)

---

## 🚀 **BU AYARLAR TAMAMLANDIKTAN SONRA:**

```bash
# Kod değişiklikleri test etmek için
flutter clean
flutter pub get  
flutter build web

# Web sunucusu başlat
cd build/web
python -m http.server 8080
```

**Tarayıcı Console'da kontrol et:**
- ✅ Firebase SW registered başarılı
- ❌ 403 PERMISSION_DENIED yok
- ❌ CORS bloklaması yok  
- ❌ Firestore 400 hatası yok

### 📋 **Test Listesi:**
- [ ] Firebase Messaging çalışıyor mu?
- [ ] Storage upload CORS hatası var mı?
- [ ] Firestore veri okuma/yazma çalışıyor mu?
- [ ] Service Worker registration başarılı mı?

Bu adımlar tamamlandıktan sonra tüm Firebase web hataları çözülmüş olacak! 🎉