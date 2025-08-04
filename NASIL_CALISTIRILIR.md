# 🚀 Randevu ERP - Hızlı Başlatma Kılavuzu

## 📋 Ön Koşullar

### ✅ Gerekli Yazılımlar
- **Flutter SDK** (3.8.1+) - [İndir](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** - Web geliştirme için
- **Android Studio** - Android geliştirme için (opsiyonel)
- **Git** - Versiyon kontrolü için

### 🔧 Flutter Kurulumu Doğrulama
```bash
flutter --version
flutter doctor
```

## ⚡ Hızlı Başlatma

### 🖱️ Tek Tıkla Başlatma (Önerilen)
Proje dizininde aşağıdaki dosyalardan birini çift tıklayın:

1. **`hizli_baslat.bat`** - Basit başlatma
2. **`gelistirici_baslat.bat`** - Geliştirici seçenekleri
3. **`production_deploy.bat`** - Production build'ler

### 📝 Manuel Başlatma
```bash
# 1. Paketleri yükle
flutter pub get

# 2. Web'de çalıştır
flutter run -d chrome --web-port 3000 --no-sound-null-safety

# 3. Tarayıcıda aç
# http://localhost:3000/public/home
```

## 🌐 Erişim Adresleri

### 🏠 Marketing Sayfaları
- **Ana Sayfa**: http://localhost:3000/public/home
- **Hizmetler**: http://localhost:3000/public/services (yakında)
- **Hakkımızda**: http://localhost:3000/public/about (yakında)
- **İletişim**: http://localhost:3000/public/contact (yakında)

### 💼 ERP Sistemi
1. **Giriş**: http://localhost:3000/login
2. **Kayıt**: http://localhost:3000/register

### 👨‍💼 Admin Paneli
- **AI Chat Takibi**: http://localhost:3000/admin-ai-chat

## 🎯 Özellikler

### ✨ Yeni Marketing Sayfaları
- 📱 **Responsive Tasarım** - Mobile, tablet, desktop
- 🎨 **Modern UI/UX** - Material Design 3
- 🔍 **Hizmet Arama** - Kategorili arama formu
- ⭐ **Müşteri Yorumları** - Carousel slider
- 📰 **Blog Önizleme** - Son yazılar
- 📧 **Newsletter** - E-posta aboneliği

### 🤖 AI Chatbox Entegrasyonu
- 💬 **Çok Dilli Destek** - TR, EN, DE, ES, FR
- 🏢 **Sektör Odaklı** - Her sektör için özel
- 📊 **Admin Takibi** - Firestore tabanlı
- 🔄 **Gerçek Zamanlı** - Canlı mesajlaşma

### 🏢 ERP Modülleri
- 💄 **Güzellik Salonu** - Randevu, müşteri yönetimi
- ⚖️ **Avukatlık** - Dava takibi, müvekkil yönetimi
- 🏥 **Klinik** - Hasta takibi, tedavi planları
- 🧠 **Psikoloji** - Seans yönetimi, hasta profilleri
- 🐕 **Veterinerlik** - Hayvan sağlık takibi
- ⚽ **Spor** - Üye yönetimi, antrenman planları
- 🎓 **Eğitim** - Öğrenci takibi, not yönetimi
- 🏠 **Emlak** - Portföy yönetimi, müşteri takibi

## 🛠️ Geliştirme Araçları

### 📊 Proje Yapısı
```
lib/
├── core/               # Temel işlevsellik
├── models/             # Veri modelleri
├── providers/          # State management
├── services/           # API servisleri
├── screens/            # Sektör sayfaları
├── widgets/            # UI bileşenleri
├── pages/public/       # Marketing sayfaları
└── main.dart          # Ana giriş
```

### 🔧 Geliştirici Komutları
```bash
# Hot reload
flutter run -d chrome --hot

# Debug build
flutter build web --debug

# Release build
flutter build web --release

# Test çalıştırma
flutter test

# Kod analizi
flutter analyze

# Format düzeltme
flutter format .
```

## 🐛 Sorun Giderme

### ❌ Yaygın Sorunlar

1. **Proje çalışmıyor**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Paket hatası**
   ```bash
   flutter pub cache clean
   flutter pub get
   ```

3. **Web build hatası**
   ```bash
   flutter build web --release --no-sound-null-safety
   ```

### 🛠️ Otomatik Sorun Çözme
`sorun_coz.bat` dosyasını çalıştırın - Otomatik tanılama ve düzeltme yapar.

## 📦 Production Build

### 🌐 Web için
```bash
flutter build web --release --no-sound-null-safety
```
Çıktı: `build/web/`

### 📱 Android için
```bash
# APK (Test için)
flutter build apk --release

# AAB (Play Store için)
flutter build appbundle --release
```

### 🔥 Firebase Deploy
```bash
firebase deploy --only hosting
```

## 🔐 Güvenlik

### 🔑 API Anahtarları
- Firebase config dosyaları commit edilmez
- Prod ve dev için ayrı projeler kullanın
- Environment variables kullanın

### 🛡️ Firestore Rules
```javascript
// Firestore güvenlik kuralları
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı sadece kendi verilerini görebilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 Canlıya Alma

### 1. Firebase Hosting
```bash
firebase init hosting
firebase deploy
```

### 2. Netlify
- `build/web` klasörünü drag & drop

### 3. GitHub Pages
- GitHub Actions ile otomatik deploy

## 📞 Destek

### 🆘 Sorun mu yaşıyorsunuz?
1. `sorun_coz.bat` çalıştırın
2. [Issues](../../issues) açın
3. Logları ekleyin

### 📧 İletişim
- **Geliştirici**: AI Assistant
- **Platform**: Cursor AI
- **Versiyon**: 1.0.0

---

## 🎉 Başarıyla Kuruldu!

Artık Randevu ERP'yi kullanmaya başlayabilirsiniz:

1. 🖱️ `hizli_baslat.bat` çift tıklayın
2. 🌐 Tarayıcıda http://localhost:3000/public/home açılır
3. 🚀 Marketing sayfasını keşfedin
4. 💼 Login yaparak ERP'ye girin
5. 🤖 AI Chatbox ile konuşun

**İyi geliştirmeler! 🚀**