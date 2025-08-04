# Firestore ve Cloud Storage Entegrasyonu

Bu dokümantasyon, randevu ERP projesi için kapsamlı Firestore ve Cloud Storage entegrasyonunu açıklar.

## 📋 İçindekiler

- [Genel Bakış](#genel-bakış)
- [Kurulum](#kurulum)
- [Servisler](#servisler)
- [Güvenlik Kuralları](#güvenlik-kuralları)
- [Dosya Yükleme](#dosya-yükleme)
- [UI Bileşenleri](#ui-bileşenleri)
- [Performans Optimizasyonu](#performans-optimizasyonu)
- [Kullanım Örnekleri](#kullanım-örnekleri)
- [Sorun Giderme](#sorun-giderme)

## 🔍 Genel Bakış

### Entegrasyon Hedefleri

✅ **Tamamlanan Özellikler:**
- Firestore koleksiyon yapıları ve veri modelleri
- Cloud Storage yapılandırması ve klasör organizasyonu
- Ortak dosya yükleme servisi
- Güvenli erişim kuralları (Firestore ve Storage)
- Hata yönetimi ve progress bar implementasyonu
- Modül entegrasyonu (örnek: randevu yönetimi)
- Performans optimizasyonu ve önbellekleme

### Desteklenen Modüller

- **Randevular**: Belge ekleme, sözleşmeler, faturalar
- **Müşteriler**: Kimlik belgeleri, sözleşmeler, tıbbi geçmiş
- **Personel**: Çalışan belgeleri, sertifikalar, sözleşmeler
- **Hizmetler**: Görsel materyaller, broşürler, fiyat listeleri
- **Genel**: Raporlar, yedek dosyalar, şablonlar

## 🚀 Kurulum

### 1. Firebase Bağımlılıkları

```yaml
dependencies:
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
  firebase_storage: ^11.7.7
  file_picker: ^6.2.1
  uuid: ^4.3.1
```

### 2. Firebase Başlatma

```dart
// main.dart içinde
import 'lib/services/performance_optimization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Performans optimizasyonları
  await PerformanceOptimizationService.enableOfflinePersistence();
  await PerformanceOptimizationService.configureFirestoreSettings();
  
  runApp(MyApp());
}
```

### 3. Güvenlik Kuralları Dağıtımı

```bash
# Firestore rules
firebase deploy --only firestore:rules

# Storage rules
firebase deploy --only storage
```

## 🛠 Servisler

### FirestoreService

Tüm Firestore işlemleri için merkezi servis:

```dart
final firestoreService = FirestoreService();

// Kullanıcı profili oluşturma
await firestoreService.createUserProfile(userData: {
  'sector': 'güzellik_salon',
  'role': 'admin',
  'businessInfo': {...},
});

// Randevu oluşturma
final appointmentId = await firestoreService.createAppointment(
  appointmentData: {
    'customerId': 'customer_id',
    'serviceId': 'service_id',
    'startDateTime': Timestamp.fromDate(DateTime.now()),
    'endDateTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
  },
);
```

### EnhancedFileUploadService

Gelişmiş dosya yükleme özellikleri:

```dart
final uploadService = EnhancedFileUploadService();

// Profil fotoğrafı yükleme
final result = await uploadService.uploadProfilePhoto(
  onProgress: (progress) => print('Progress: ${(progress * 100).toInt()}%'),
);

// Randevu belgesi yükleme
final result = await uploadService.uploadAppointmentDocument(
  appointmentId: 'appointment_id',
  documentType: 'contract',
  title: 'Hizmet Sözleşmesi',
  description: 'Müşteri hizmet sözleşmesi',
);
```

### PerformanceOptimizationService

Performans ve önbellekleme:

```dart
final perfService = PerformanceOptimizationService();

// Önbellekli veri getirme
final customers = await perfService.getOptimizedCustomers(
  status: 'active',
  limit: 50,
);

// Toplu işlemler
await perfService.batchCreateDocuments(
  collection: 'customers',
  documentsData: [customer1Data, customer2Data, customer3Data],
);
```

## 🔒 Güvenlik Kuralları

### Firestore Güvenlik

- **Kimlik Doğrulama**: Tüm işlemler için kullanıcı girişi gerekli
- **Sahiplik Kontrolü**: Kullanıcılar sadece kendi verilerine erişebilir
- **Rol Bazlı Erişim**: Admin, personel ve kullanıcı rolleri
- **Veri Doğrulama**: Gerekli alanların kontrolü

### Cloud Storage Güvenlik

- **Dosya Boyutu Sınırları**: 
  - Resimler: 10MB
  - Belgeler: 50MB
  - Medya: 100MB
- **Dosya Türü Kontrolü**: Sadece izin verilen uzantılar
- **Yol Bazlı Erişim**: Kullanıcı klasörü izolasyonu

## 📁 Cloud Storage Yapısı

```
randevu-takip-app.appspot.com/
├── users/
│   └── {userId}/
│       └── profile.{ext}
├── appointments/
│   └── {userId}/
│       └── {appointmentId}/
│           ├── contract_timestamp.pdf
│           └── invoice_timestamp.pdf
├── customers/
│   └── {userId}/
│       └── {customerId}/
│           ├── id_card_timestamp.jpg
│           └── medical_history_timestamp.pdf
├── staff/
│   └── {userId}/
│       └── {staffId}/
├── services/
│   └── {userId}/
│       └── {serviceId}/
├── documents/
│   └── {userId}/
│       └── {category}/
└── reports/
    └── {userId}/
        └── {reportType}/
```

## 🎨 UI Bileşenleri

### FileUploadButton

Basit dosya yükleme butonu:

```dart
FileUploadButton(
  module: 'appointment',
  entityId: appointmentId,
  documentType: 'contract',
  buttonText: 'Sözleşme Yükle',
  icon: Icons.description,
  onUploadComplete: () => print('Yükleme tamamlandı'),
)
```

### FileListWidget

Dosya listesi ve yönetimi:

```dart
FileListWidget(
  entityType: 'appointment',
  entityId: appointmentId,
  allowUpload: true,
  allowDelete: true,
  uploadButtonText: 'Belge Ekle',
)
```

### StorageUsageWidget

Depolama kullanım istatistikleri:

```dart
StorageUsageWidget()
```

## ⚡ Performans Optimizasyonu

### Önbellekleme Stratejisi

- **Kısa Süreli Cache**: 5 dakika (sık değişen veriler)
- **Uzun Süreli Cache**: 1 saat (az değişen veriler)
- **Otomatik Temizlik**: Cache boyutu sınırı aşıldığında

### Toplu İşlemler

```dart
// Birden fazla belgeyi aynı anda oluşturma
await perfService.batchCreateDocuments(
  collection: 'appointments',
  documentsData: multipleAppointments,
);

// Birden fazla güncelleme
await perfService.batchUpdateDocuments(
  collection: 'customers',
  updates: {
    'customer1': {'status': 'active'},
    'customer2': {'status': 'inactive'},
  },
);
```

### Önerilen İndeksler

Firestore Console'da oluşturulması gereken indeksler:

```javascript
// appointments koleksiyonu
{
  fields: ['userId', 'startDateTime'],
  order: 'ASC'
}

{
  fields: ['userId', 'status', 'startDateTime'],
  order: 'ASC'
}

// customers koleksiyonu
{
  fields: ['userId', 'status', 'firstName'],
  order: 'ASC'
}
```

## 💡 Kullanım Örnekleri

### Randevu Oluşturma ve Belge Yükleme

```dart
class AppointmentFormPage extends StatefulWidget {
  @override
  _AppointmentFormPageState createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final EnhancedFileUploadService _uploadService = EnhancedFileUploadService();
  
  Future<void> _createAppointment() async {
    // 1. Randevu oluştur
    final appointmentId = await _firestoreService.createAppointment(
      appointmentData: appointmentData,
    );
    
    // 2. Belge yükle (opsiyonel)
    if (hasDocument) {
      await _uploadService.uploadAppointmentDocument(
        appointmentId: appointmentId,
        documentType: 'contract',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Form fields...
          
          // Dosya yükleme bölümü
          FileListWidget(
            entityType: 'appointment',
            entityId: appointmentId,
          ),
          
          // Kaydet butonu
          ElevatedButton(
            onPressed: _createAppointment,
            child: Text('Randevu Oluştur'),
          ),
        ],
      ),
    );
  }
}
```

### Batch İşlemler

```dart
// Birden fazla müşteriyi aynı anda içe aktarma
Future<void> importCustomers(List<Map<String, dynamic>> customersData) async {
  final perfService = PerformanceOptimizationService();
  
  // 20'şerli gruplar halinde işlem yap (Firestore batch limiti)
  final chunks = _chunkList(customersData, 20);
  
  for (final chunk in chunks) {
    await perfService.batchCreateDocuments(
      collection: 'customers',
      documentsData: chunk,
    );
  }
}
```

## 🚨 Sorun Giderme

### Yaygın Hatalar

#### 1. Permission Denied
```
PERMISSION_DENIED: Missing or insufficient permissions
```

**Çözüm**: Firestore security rules kontrolü
- Kullanıcı giriş yapmış mı?
- Doğru sahiplik kontrolü var mı?

#### 2. Storage Upload Hatası
```
Firebase Storage: The operation 'putFile' cannot be performed on a reference from a different project.
```

**Çözüm**: Firebase proje yapılandırması kontrolü
- `firebase_options.dart` güncel mi?
- Storage bucket doğru mu?

#### 3. Index Hatası
```
The query requires an index
```

**Çözüm**: Firebase Console'da gerekli indeksi oluşturun

### Debug Araçları

```dart
// Performans metriklerini görüntüleme
PerformanceOptimizationService().logPerformanceMetrics();

// Cache istatistikleri
final stats = PerformanceOptimizationService().getCacheStatistics();
print('Cache entries: ${stats['totalEntries']}');
```

### Log Düzeyleri

```dart
// Debug modunda detaylı loglar
if (kDebugMode) {
  print('Firestore operation: $operation');
  print('Cache hit: $cacheKey');
}
```

## 📊 Monitoring ve Analytics

### Firestore Kullanımı

- Document reads/writes sayısı
- Storage kullanımı
- Bandwidth tüketimi

### Performance Metrics

```dart
// Cache hit rate
final hitRate = perfService.getCacheStatistics()['cacheHitRate'];

// Ortalama response time
final responseTime = await measureResponseTime();
```

## 🔄 Güncellemeler ve Bakım

### Düzenli Bakım

1. **Cache temizliği**: Uygulama başlangıcında
2. **Log dosyası rotasyonu**: Haftalık
3. **Storage kullanım analizi**: Aylık

### Version Control

- Firestore rules versiyonlama
- Storage rules backup
- Schema migration scripts

## 📝 Lisans ve Katkıda Bulunma

Bu entegrasyon açık kaynak projesi kapsamında geliştirilmiştir. Katkıda bulunmak için:

1. Repository fork edin
2. Feature branch oluşturun
3. Değişiklikleri commit edin
4. Pull request gönderin

---

**Not**: Bu dokümantasyon sürekli güncellenmektedir. Son sürüm için repository'yi takip edin. 