# Belge Yükleme Sistemi Entegrasyon Rehberi

Bu rehber, Flutter Randevu ERP projesinde belge yükleme sisteminin tüm panellere nasıl entegre edileceğini açıklar.

## 📁 Dosya Yapısı

```
lib/
├── models/
│   └── document_model.dart           # Belge veri modeli
├── services/
│   └── document_service.dart         # Firebase entegrasyon servisi
├── providers/
│   └── document_provider.dart        # State management
├── widgets/
│   ├── document_upload_widget.dart   # Belge yükleme widget'ı
│   └── document_list_widget.dart     # Belge listeleme widget'ı
├── screens/
│   ├── lawyer/
│   │   └── lawyer_documents_screen.dart    # Avukat paneli örneği
│   └── beauty/
│       └── beauty_documents_screen.dart    # Güzellik paneli örneği
├── utils/
│   └── document_integration_helper.dart    # Entegrasyon yardımcısı
└── core/
    └── constants/
        └── app_constants.dart        # Uygulama sabitleri
```

## 🚀 Hızlı Başlangıç

### 1. Provider'ı main.dart'a Ekleyin

```dart
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        // Diğer provider'larınız...
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Firebase Bağımlılıklarını Ekleyin

`pubspec.yaml` dosyasına ekleyin:
```yaml
dependencies:
  cloud_firestore: ^4.13.6
  firebase_auth: ^4.15.3
  firebase_storage: ^11.6.0
  file_picker: ^6.1.1
  provider: ^6.1.1
  intl: ^0.19.0
```

## 📋 Panel Entegrasyonu

### Yöntem 1: Hazır Helper Kullanımı

En kolay yöntem, `DocumentIntegrationHelper` sınıfını kullanmaktır:

```dart
import '../utils/document_integration_helper.dart';

class VeterinaryAppointmentScreen extends StatelessWidget {
  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Diğer içerikler...
          
          // Veteriner belgelerini entegre et
          DocumentIntegrationHelper.buildVeterinaryDocumentSection(
            context,
            appointmentId: appointmentId,
          ),
        ],
      ),
    );
  }
}
```

### Yöntem 2: Widget'ları Doğrudan Kullanım

```dart
import '../widgets/document_upload_widget.dart';
import '../widgets/document_list_widget.dart';

class CustomDocumentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Belge yükleme
          DocumentUploadWidget(
            panel: 'veterinary',
            panelContextId: 'appointment_123',
            allowedTypes: ['reçete', 'kan_tahlili', 'röntgen'],
            onDocumentUploaded: (document) {
              print('Belge yüklendi: ${document.documentType}');
            },
          ),
          
          // Belge listesi
          Expanded(
            child: DocumentListWidget(
              panel: 'veterinary',
              showFilters: true,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Yöntem 3: Dialog Olarak Gösterim

```dart
// Belge yükleme dialog'u göster
final uploadedDocument = await DocumentIntegrationHelper.showUploadDialog(
  context: context,
  panel: 'education',
  panelContextId: 'course_456',
  allowedTypes: ['diploma', 'sertifika'],
);

if (uploadedDocument != null) {
  print('Yüklenen belge: ${uploadedDocument.documentType}');
}
```

## 🎯 Panel Özel Konfigürasyonları

### Avukat Paneli
```dart
allowedTypes: [
  'kimlik',
  'ikametgah', 
  'dava_evrakı',
  'sözleşme',
  'mahkeme_kararı',
  'vekaletname'
]
```

### Güzellik Paneli
```dart
allowedTypes: [
  'kimlik',
  'sağlık_raporu',
  'öncesi_fotoğraf',
  'sonrası_fotoğraf', 
  'onay_formu'
]
```

### Veteriner Paneli
```dart
allowedTypes: [
  'kimlik',
  'hayvan_kimlik',
  'aşı_kartı',
  'reçete',
  'kan_tahlili',
  'röntgen',
  'muayene_raporu'
]
```

### Eğitim Paneli
```dart
allowedTypes: [
  'kimlik',
  'diploma',
  'sertifika',
  'cv', 
  'referans_mektubu',
  'transkript'
]
```

### Spor Paneli
```dart
allowedTypes: [
  'kimlik',
  'sağlık_raporu',
  'spor_lisansı',
  'antrenman_programı',
  'beslenme_planı'
]
```

### Danışmanlık Paneli
```dart
allowedTypes: [
  'kimlik',
  'şirket_evrakı',
  'mali_tablo',
  'sözleşme',
  'proje_dosyası'
]
```

### Emlak Paneli
```dart
allowedTypes: [
  'kimlik',
  'tapu',
  'yapı_ruhsatı',
  'iskan_ruhsatı',
  'emlak_ekspertiz',
  'mülk_fotoğrafları'
]
```

## 🔧 Programatik Kullanım

### Doğrudan Dosya Yükleme

```dart
import 'dart:io';
import '../utils/document_integration_helper.dart';

Future<void> uploadDocumentProgrammatically(File file) async {
  final document = await DocumentIntegrationHelper.quickUpload(
    context: context,
    panel: 'lawyer',
    file: file,
    documentType: 'dava_evrakı',
    description: 'Dava dosyası eki',
    panelContextId: 'case_789',
  );
  
  if (document != null) {
    print('Başarıyla yüklendi: ${document.filePath}');
  }
}
```

### Provider Kullanımı

```dart
class MyDocumentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        return Column(
          children: [
            // Yükleme durumu
            if (documentProvider.isLoading)
              LinearProgressIndicator(
                value: documentProvider.uploadProgress,
              ),
            
            // Hata mesajı
            if (documentProvider.error != null)
              Text(
                documentProvider.error!,
                style: TextStyle(color: Colors.red),
              ),
            
            // Belgeler listesi
            ListView.builder(
              shrinkWrap: true,
              itemCount: documentProvider.documents.length,
              itemBuilder: (context, index) {
                final doc = documentProvider.documents[index];
                return ListTile(
                  title: Text(doc.documentType),
                  subtitle: Text(doc.status),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => documentProvider.deleteDocument(doc.id!),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

## 🔒 Firebase Güvenlik Kuralları

`firestore.rules` dosyasına ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Belge koleksiyonu kuralları
    match /documents/{documentId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

`storage.rules` dosyasına ekleyin:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /client_documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## 📊 Admin Panel Entegrasyonu

Admin kullanıcıları için belge onaylama sistemi:

```dart
class AdminDocumentApprovalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('status', isEqualTo: 'waiting')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = DocumentModel.fromFirestore(snapshot.data!.docs[index]);
            
            return Card(
              child: ListTile(
                title: Text('${doc.documentType} - ${doc.panel}'),
                subtitle: Text('Kullanıcı: ${doc.userId}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveDocument(doc.id!),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectDocument(doc.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _approveDocument(String documentId) async {
    await DocumentService().updateDocumentStatus(
      documentId: documentId,
      status: 'approved',
      approvedBy: FirebaseAuth.instance.currentUser!.uid,
    );
  }
  
  Future<void> _rejectDocument(String documentId) async {
    await DocumentService().updateDocumentStatus(
      documentId: documentId,
      status: 'rejected',
      approvedBy: FirebaseAuth.instance.currentUser!.uid,
    );
  }
}
```

## 🎨 Özelleştirme

### Yeni Belge Türü Ekleme

`DocumentService.getDocumentTypesForPanel()` metodunu güncelleyin:

```dart
case 'yeni_panel':
  return [
    'kimlik',
    'özel_belge_1',
    'özel_belge_2',
  ];
```

### Özel Validasyon Ekleme

`DocumentUploadWidget` içinde özel validasyon kuralları:

```dart
bool _validateFile(File file, String documentType) {
  // Dosya boyutu kontrolü
  if (file.lengthSync() > AppConstants.maxFileSizeInBytes) {
    return false;
  }
  
  // Belge türüne özel validasyonlar
  if (documentType == 'kimlik') {
    // Kimlik belgeleri için özel kontroller
    return file.path.toLowerCase().endsWith('.pdf');
  }
  
  return true;
}
```

Bu rehber ile belge yükleme sistemi tüm panellere kolayca entegre edilebilir ve özelleştirilebilir.