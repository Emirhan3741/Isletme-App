# Randevu ERP - Çoklu Dil Desteği En İyi Uygulamalar

## 📋 Genel Kurallar

### 1. Build Metodu İçinde L10n Kullanımı
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Scaffold(
    appBar: AppBar(title: Text(l10n.notifications)),
    body: Text(l10n.welcome),
  );
}
```

### 2. Build Dışında L10n Kullanımı
```dart
Future<void> _saveData() async {
  final l10n = AppLocalizations.of(context)!;
  
  try {
    // İşlem
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    }
  }
}
```

### 3. L10nHelper Kullanımı (Opsiyonel)
```dart
import '../utils/l10n_helper.dart';

Future<void> _processData() async {
  final l10n = L10nHelper.of(context);
  // Kullanım
}
```

## 🎯 Zorunlu Kontroller

### Context Geçerliliği
- `mounted` kontrolü mutlaka yapılmalı
- `AppLocalizations.of(context)!` sadece context geçerliyken kullanılmalı

### Hata Yönetimi
```dart
try {
  // Ana işlem
} catch (e) {
  if (mounted) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.error}: $e')),
    );
  }
}
```

## 📝 ARB Dosyası Standartları

### Key Adlandırma
- camelCase kullanın: `createTestNotification`
- Açıklayıcı isimler: `markAllAsRead` ✅ `mark` ❌
- Sayfa gruplaması: `notifications_`, `beauty_`, vb.

### Çeviri Kalitesi
- Türkçe'de kültürel uygunluk sağlayın
- İngilizce'de net ve anlaşılır ifadeler kullanın
- Diğer dillerde profesyonel çeviriler tercih edin

## 🔧 Provider Pattern Kullanımı

### Dil Değiştirme
```dart
// Dil değiştirme
await Provider.of<LocaleProvider>(context, listen: false)
    .setLocale(const Locale('en'));
```

### Mevcut Dil Kontrolü
```dart
final localeProvider = Provider.of<LocaleProvider>(context);
final currentLanguage = localeProvider.locale.languageCode;
```

## ⚠️ Yaygın Hatalar ve Çözümleri

### ❌ YANLIŞ: Build dışında doğrudan erişim
```dart
Future<void> _wrongExample() async {
  final title = l10n.createTestNotification; // HATA!
}
```

### ✅ DOĞRU: Context ile erişim
```dart
Future<void> _correctExample() async {
  final l10n = AppLocalizations.of(context)!;
  final title = l10n.createTestNotification; // DOĞRU
}
```

### ❌ YANLIŞ: Sabit metin kullanımı
```dart
Text('Hata oluştu') // YANLIŞ
```

### ✅ DOĞRU: Çeviri kullanımı
```dart
Text(l10n.error) // DOĞRU
```

## 🧪 Test Senaryoları

### Dil Değiştirme Testi
1. Uygulamayı başlatın
2. Ayarlardan dil değiştirin
3. Tüm metinlerin doğru çevrildiğini kontrol edin
4. Yeniden başlatma gerektirmediğini doğrulayın

### Build Dışı Fonksiyon Testi
1. Hata senaryolarını tetikleyin
2. SnackBar mesajlarının çevrildiğini kontrol edin
3. Dialog metinlerinin doğru göründüğünü onaylayın

## 📊 Performans Optimizasyonları

### Gereksiz Yeniden İnşa Önleme
```dart
Consumer<LocaleProvider>(
  builder: (context, localeProvider, child) {
    // Sadece dil değişikliğinde yeniden inşa et
    return MaterialApp(
      locale: localeProvider.locale,
      // ...
    );
  },
);
```

### Bellek Yönetimi
- Büyük çeviri anahtarlarını lazy load edin
- Kullanılmayan dil dosyalarını belleğe almayın

## 📋 Checklist

- [ ] Tüm metinler .arb dosyalarında tanımlı
- [ ] Build dışı fonksiyonlarda context kontrolü var
- [ ] Hata mesajları çevrilmiş
- [ ] Dil değiştirme işlevi çalışıyor
- [ ] RTL dil desteği (Arapça) doğru
- [ ] Yeni dil ekleme kolay
- [ ] Performance sorunları yok
- [ ] Test senaryoları geçiyor

## 🚀 Gelecek Geliştirmeler

### Dinamik Çeviri Yükleme
```dart
// Gelecekte uygulanabilir
Future<void> loadTranslationsFromServer() async {
  // Server'dan çevirileri al ve cache'le
}
```

### Çeviri Eksiklik Raporlama
```dart
// Eksik çevirileri otomatik tespit et
void reportMissingTranslations() {
  // Debugging modunda eksik anahtarları logla
}
```

---

**Not**: Bu rehber projede çoklu dil desteğinin tutarlı ve sürdürülebilir olması için hazırlanmıştır. Yeni sayfa eklerken bu standartları takip ediniz. 