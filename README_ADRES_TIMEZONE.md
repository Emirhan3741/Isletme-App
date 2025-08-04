# Adres ve Saat Dilimi Özelliği Kullanım Rehberi

## 📍 Genel Bakış

Randevu ERP uygulamasına adres bilgileri ve saat dilimi seçim özelliği eklenmiştir. Bu özellik hem kayıt ekranında hem de ayarlar sayfasında kullanılabilir.

## 🏗️ Eklenen Bileşenler

### 1. UserModel Güncellemeleri
```dart
// Yeni eklenen alanlar
final String? country;          // Ülke kodu (TR, US, DE, etc.)
final String? city;             // Şehir adı
final String? district;         // İlçe/Bölge
final String? zipCode;          // Posta kodu
final String? fullAddress;      // Açık adres
final String? timeZone;         // Saat dilimi (GMT+3, GMT-5, etc.)
```

### 2. Widget Bileşenleri

#### AddressSectionWidget
- **Konum**: `lib/widgets/address_section_widget.dart`
- **Özellikler**:
  - Ülke dropdown (33 ülke seçeneği)
  - Şehir ve ilçe text alanları
  - Posta kodu alanı
  - Açık adres multiline alanı
  - Validation desteği
  - Yeniden kullanılabilir tasarım

#### TimezoneSectionWidget  
- **Konum**: `lib/widgets/timezone_section_widget.dart`
- **Özellikler**:
  - GMT offset dropdown (GMT-12 ile GMT+12 arası)
  - Otomatik cihaz saat dilimi algılama
  - Saat dilimi helper fonksiyonları
  - Refresh butonu ile yeniden algılama

### 3. Helper Sınıfları

#### CountryHelper
```dart
// Ülke kodundan ülke adını alma
String countryName = CountryHelper.getCountryName('TR'); // Türkiye
```

#### TimezoneHelper
```dart
// Saat dilimi çevirme fonksiyonları
DateTime userTime = TimezoneHelper.convertToUserTimezone(utcTime, 'GMT+3');
DateTime utcTime = TimezoneHelper.convertFromUserTimezone(localTime, 'GMT+3');
int offsetHours = TimezoneHelper.getOffsetHours('GMT+3'); // 3
```

## 📱 Kullanım Alanları

### 1. Kayıt Ekranı
- **Konum**: `lib/screens/auth/register_page.dart`
- **Özellikler**:
  - Para birimi seçiminden sonra adres bölümü
  - Adres bölümünden sonra saat dilimi bölümü
  - Adres alanları **zorunlu** (validation)
  - Saat dilimi **opsiyonel** (otomatik algılanır)

### 2. Ayarlar Sayfası
- **Konum**: `lib/screens/settings/settings_page.dart`
- **Özellikler**:
  - Para birimi bölümünden sonra adres düzenleme
  - Ayrı saat dilimi bölümü
  - Anlık kaydetme (onChange)
  - "Adres Bilgilerini Kaydet" butonu

## 🗄️ Firestore Veri Yapısı

```javascript
// users/{userId} dökümanında yeni alanlar
{
  // ... mevcut alanlar
  "country": "TR",
  "city": "İstanbul", 
  "district": "Kadıköy",
  "zipCode": "34710",
  "fullAddress": "Moda Mahallesi, Bahariye Caddesi No:123 Daire:5",
  "timeZone": "GMT+3",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

## 🎯 Otomatik Özellikler

### 1. Cihaz Saat Dilimi Algılama
```dart
// TimezoneSectionWidget otomatik olarak cihaz saat dilimini algılar
String systemTimezone = _getSystemTimeZone(); // GMT+3
```

### 2. Validation Kuralları
- **Ülke**: Seçim zorunlu (dropdown)
- **Şehir**: Minimum 2 karakter, boş olamaz
- **İlçe**: Minimum 2 karakter, boş olamaz  
- **Posta Kodu**: Boş olamaz
- **Açık Adres**: Minimum metin gerekli

### 3. Varsayılan Değerler
- **Saat Dilimi**: Cihazdan otomatik algılanır, aksi halde GMT+3 (Türkiye)
- **Ülke**: Seçim zorunlu, varsayılan yok

## 🔄 Entegrasyon Noktaları

### 1. Register Page
```dart
// Adres bilgileri state değişkenleri
String? _selectedCountry;
String? _selectedCity;
String? _selectedDistrict;
String? _selectedZipCode;
String? _selectedFullAddress;
String? _selectedTimeZone;

// Firestore'a kaydetme
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({
  'country': _selectedCountry,
  'city': _selectedCity,
  'district': _selectedDistrict,
  'zipCode': _selectedZipCode,
  'fullAddress': _selectedFullAddress,
  'timeZone': _selectedTimeZone,
  // ... diğer alanlar
});
```

### 2. Settings Page
```dart
// Mevcut verileri yükleme
final data = doc.data()!;
setState(() {
  _selectedCountry = data['country'];
  _selectedCity = data['city'];
  // ... diğer alanlar
});

// Güncellemeleri kaydetme
await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .update({
  'country': _selectedCountry,
  'city': _selectedCity,
  // ... güncellenecek alanlar
});
```

## 🎨 UI/UX Özellikleri

### 1. Responsive Tasarım
- Mobil ve masaüstü uyumlu
- Şehir ve ilçe alanları yan yana (Row widget)
- Adaptive padding ve spacing

### 2. Görsel Öğeler
- **Adres**: 📍 konum ikonu
- **Saat Dilimi**: 🕐 saat ikonu
- Renk kodlu başlıklar (AppConstants.primaryColor)
- Card tabanlı bölümler

### 3. Kullanıcı Deneyimi
- Otomatik saat dilimi algılama mesajı
- "Otomatik Algıla" butonu
- Başarı/hata mesajları (SnackBar)
- Form validation feedback

## 🔮 Gelecek Geliştirmeler

### 1. Coğrafi Konum
```dart
// GeoLocator entegrasyonu (opsiyonel)
Position position = await Geolocator.getCurrentPosition();
// Konumdan ülke/şehir tahmini
```

### 2. Randevu Saat Çevirme
```dart
// Kullanıcı saat dilimine göre randevu saatlerini dönüştürme
DateTime appointmentTime = TimezoneHelper.convertToUserTimezone(
  utcAppointmentTime, 
  user.timeZone
);
```

### 3. Otomatik Ülke/Şehir Tahmini
- IP tabanlı konum algılama
- Cihaz dil ayarlarından tahmin
- Kullanıcı geçmişi analizi

## 📊 Test Senaryoları

### 1. Kayıt Testi
1. Kayıt sayfasını açın
2. Temel bilgileri doldurun
3. Adres bölümünde tüm alanları doldurun
4. Saat dilimi seçin (otomatik algılanır)
5. Kayıt işlemini tamamlayın
6. Firestore'da verilerin kaydedildiğini kontrol edin

### 2. Ayarlar Testi
1. Ayarlar sayfasını açın
2. Adres bölümünü güncelleyin
3. "Kaydet" butonuna tıklayın
4. Saat dilimini değiştirin (otomatik kaydedilir)
5. Sayfayı yenileyin ve değişikliklerin kalıcı olduğunu kontrol edin

### 3. Validation Testi
1. Kayıt sayfasında adres alanlarını boş bırakın
2. Form göndermeye çalışın
3. Validation mesajlarının görüntülendiğini kontrol edin
4. Geçerli veriler girin ve başarılı kayıt yapın

## ⚠️ Önemli Notlar

1. **Geriye Uyumluluk**: Mevcut kullanıcılar için adres alanları null olabilir
2. **Validation**: Kayıt sırasında adres zorunlu, ayarlarda opsiyonel
3. **Performans**: Büyük ülke listesi için lazy loading düşünülebilir
4. **Güvenlik**: Adres verilerinin güvenliği için uygun Firestore rules gerekli

## 📞 Destek

Bu özellikle ilgili sorularınız için:
- Kod incelemesi: `lib/widgets/` klasörü
- Model yapısı: `lib/models/user_model.dart`
- Kullanım örnekleri: Kayıt ve ayarlar sayfaları

---
*Son güncelleme: 2024 - Adres ve Saat Dilimi Özelliği v1.0* 