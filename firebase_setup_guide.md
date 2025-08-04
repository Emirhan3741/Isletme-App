# Firebase Setup Rehberi - Belge Yükleme Sistemi

## 🔧 Firebase Konfigürasyonu

### 1. Firebase Console Ayarları

1. [Firebase Console](https://console.firebase.google.com/) üzerinden projenizi açın
2. Authentication, Firestore Database ve Storage servislerini aktifleştirin

### 2. Firestore Database Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar koleksiyonu
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Belgeler koleksiyonu
    match /documents/{documentId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
        request.writeFields.hasOnly(['status', 'approvedBy', 'updatedAt']);
    }
    
    // Randevular koleksiyonu (örnek)
    match /appointments/{appointmentId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Kullanıcı belgeleri
    match /client_documents/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Genel dosyalar (profil fotoğrafları vb.)
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Firestore Index'leri

Firebase Console > Firestore Database > Indexes bölümünde şu index'leri oluşturun:

#### Documents Collection Indexes

1. **Kullanıcı Belgelerini Filtreleme**
   - Collection ID: `documents`
   - Fields:
     - `userId` (Ascending)
     - `uploadedAt` (Descending)

2. **Panel Bazlı Filtreleme**
   - Collection ID: `documents`
   - Fields:
     - `userId` (Ascending)
     - `panel` (Ascending)
     - `uploadedAt` (Descending)

3. **Durum Bazlı Filtreleme**
   - Collection ID: `documents`
   - Fields:
     - `userId` (Ascending)
     - `status` (Ascending)
     - `uploadedAt` (Descending)

4. **Belge Türü Filtreleme**
   - Collection ID: `documents`
   - Fields:
     - `userId` (Ascending)
     - `documentType` (Ascending)
     - `uploadedAt` (Descending)

5. **Admin Panel İçin**
   - Collection ID: `documents`
   - Fields:
     - `status` (Ascending)
     - `uploadedAt` (Descending)

6. **Panel Context Filtreleme**
   - Collection ID: `documents`
   - Fields:
     - `panelContextId` (Ascending)
     - `uploadedAt` (Descending)

### 5. CORS Konfigürasyonu

Mevcut `cors.json` dosyanızı güncelleyin:

```json
[
  {
    "origin": [
      "http://localhost:57813",
      "http://127.0.0.1:57813", 
      "http://localhost:3000",
      "http://localhost:8080",
      "https://your-project.firebaseapp.com",
      "https://your-project.web.app"
    ],
    "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "maxAgeSeconds": 3600,
    "responseHeader": [
      "Content-Type", 
      "Authorization", 
      "x-goog-resumable", 
      "x-goog-acl", 
      "origin", 
      "x-requested-with",
      "x-goog-content-length-range"
    ]
  }
]
```

CORS ayarlarını uygulayın:
```bash
gsutil cors set cors.json gs://your-bucket-name
```

### 6. Firebase SDK Initialization

`lib/main.dart` dosyanızda Firebase'i başlatın:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutter fire configure ile oluşturulan dosya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### 7. Authentication Setup

Kullanıcı giriş kontrolü için:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return MainApp(); // Ana uygulama
        } else {
          return LoginScreen(); // Giriş ekranı
        }
      },
    );
  }
}
```

### 8. Environment Variables (Opsiyonel)

Farklı ortamlar için `.env` dosyası:

```env
# Development
FIREBASE_PROJECT_ID=your-dev-project
FIREBASE_STORAGE_BUCKET=your-dev-project.appspot.com

# Production  
# FIREBASE_PROJECT_ID=your-prod-project
# FIREBASE_STORAGE_BUCKET=your-prod-project.appspot.com
```

### 9. Test Verisi

İlk kullanım için test verisi oluşturun:

```dart
// Test kullanıcısı oluşturma
Future<void> createTestUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'role': 'user', // veya 'admin'
      'panels': ['lawyer', 'beauty'], // Kullanıcının erişebileceği paneller
      'createdAt': DateTime.now(),
    });
  }
}
```

### 10. Güvenlik Önerileri

1. **API Key Güvenliği**: Firebase API anahtarlarınızı güvenli tutun
2. **Rules Testing**: Firebase Console'da rules'ları test edin
3. **Rate Limiting**: Firestore ve Storage için kullanım limitlerini ayarlayın
4. **Monitoring**: Firebase Console'dan kullanım istatistiklerini takip edin
5. **Backup**: Düzenli olarak Firestore verilerini yedekleyin

Bu konfigürasyonlar ile belge yükleme sistemi güvenli bir şekilde çalışacaktır.