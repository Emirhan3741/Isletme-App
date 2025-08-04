# 📁 Belge Yükleme Sistemi Rehberi

## 🎯 Genel Bakış

Randevu ERP uygulaması için kapsamlı belge yükleme sistemi başarıyla tamamlanmıştır. Bu sistem, tüm modüllerde tutarlı ve güvenli dosya yükleme işlemi sağlar.

## ✅ Tamamlanan Modüller

### 🏢 **Employee (Çalışan) Modülü**
- **Dosya**: `lib/screens/admin/add_edit_employee_page.dart`
- **Özellikler**:
  - CV yükleme sistemi
  - İş sözleşmesi yükleme
  - Çalışan detay formu
  - Firebase Storage entegrasyonu

### 💰 **Expense (Gider) Modülü**
- **Dosya**: `lib/screens/expenses/add_edit_expense_page.dart`
- **Özellikler**:
  - Fiş/fatura yükleme
  - Gider belgesi kategorilendirme
  - Muhasebe entegrasyonu

### 💄 **Beauty (Güzellik) Modülü**
- **Dosya**: `lib/screens/beauty/beauty_documents_page.dart`
- **Özellikler**:
  - Müşteri fotoğrafları
  - Önce/sonra karşılaştırma
  - Sertifika belgeleri
  - Ürün bilgileri
  - Tedavi planları
  - Randevu notları

### ⚖️ **Lawyer (Avukat) Modülü**
- **Dosya**: `lib/screens/lawyer/add_edit_case_page.dart`
- **Özellikler**:
  - Dava dosyaları
  - Sözleşme belgeleri
  - Delil ve ek belgeler
  - Mahkeme evrakları

### 🐾 **Veterinary (Veteriner) Modülü**
- **Dosya**: `lib/screens/veterinary/add_edit_patient_page.dart`
- **Özellikler**:
  - Tıbbi kayıtlar
  - Aşı belgeleri
  - Röntgen görüntüleri
  - Hasta dosyaları

### 👥 **Customer (Müşteri) Modülü**
- **Dosya**: `lib/screens/customers/add_edit_customer_page.dart`
- **Özellikler**:
  - Kimlik belgeleri
  - Sözleşme belgeleri
  - Hizmet kayıtları
  - Müşteri dokümanları

## 🛠️ Teknik Altyapı

### 📦 **Merkezi Servisler**

#### 1. **FileUploadService** (`lib/services/file_upload_service.dart`)
```dart
class FileUploadService {
  // Dosya yükleme işlemleri
  // Firebase Storage entegrasyonu
  // Hata yönetimi
  // Dosya doğrulama
}
```

**Özellikler**:
- Desteklenen dosya türleri: PDF, DOC, DOCX, JPG, JPEG, PNG, MP4, MP3
- Maksimum dosya boyutu: 50MB
- Firebase Storage path yapısı: `files/{userId}/{module}/{timestamp}.{extension}`
- Firestore meta veri kaydı

#### 2. **FileUploadWidget** (`lib/widgets/file_upload_widget.dart`)
```dart
class FileUploadWidget extends StatefulWidget {
  // Yeniden kullanılabilir dosya yükleme widget'ı
  // Drag & drop desteği
  // Önizleme özelliği
  // Hata yönetimi
}
```

**Parametreler**:
- `module`: Modül adı (beauty, lawyer, veterinary, vb.)
- `collection`: Firestore koleksiyon adı
- `additionalData`: Ek meta veriler
- `allowedExtensions`: İzin verilen dosya uzantıları
- `isRequired`: Zorunluluk durumu
- `showPreview`: Önizleme gösterimi

## 🗂️ Firebase Storage Yapısı

```
files/
├── {userId}/
│   ├── beauty/
│   │   ├── 1640995200000.jpg
│   │   └── 1640995201000.pdf
│   ├── lawyer/
│   │   ├── case_documents/
│   │   ├── contract_documents/
│   │   └── evidence_documents/
│   ├── veterinary/
│   │   ├── medical_records/
│   │   ├── vaccine_records/
│   │   └── xray_images/
│   ├── employees/
│   │   ├── employee_cvs/
│   │   └── employee_contracts/
│   ├── expenses/
│   │   └── receipts/
│   └── customers/
│       ├── identity_documents/
│       ├── contract_documents/
│       └── service_documents/
```

## 🗄️ Firestore Koleksiyonları

### **Belge Meta Verileri**
Her yüklenen dosya için aşağıdaki koleksiyonlarda meta veri saklanır:

- `beauty_documents`
- `case_documents`
- `contract_documents` 
- `evidence_documents`
- `medical_records`
- `vaccine_records`
- `xray_images`
- `employee_cvs`
- `employee_contracts`
- `expense_receipts`
- `identity_documents`
- `service_documents`

### **Örnek Firestore Dokümanı**
```json
{
  "userId": "user123",
  "fileName": "CV_2024.pdf",
  "fileUrl": "https://firebasestorage.googleapis.com/.../CV_2024.pdf",
  "filePath": "files/user123/employees/1640995200000.pdf",
  "fileSize": 2048576,
  "mimeType": "application/pdf",
  "uploadDate": "2024-01-01T10:00:00Z",
  "module": "employees",
  "documentType": "cv",
  "additionalData": {
    "employeeId": "emp123",
    "employeeName": "Ahmet Yılmaz",
    "position": "Yazılım Geliştirici"
  }
}
```

## 🔒 Güvenlik Önlemleri

### **Dosya Doğrulama**
- Dosya uzantısı kontrolü
- MIME type doğrulama
- Dosya boyutu sınırlaması
- Güvenli dosya adı oluşturma

### **Erişim Kontrolü**
- User ID bazlı dosya yalıtımı
- Firebase Security Rules entegrasyonu
- Yetkilendirme kontrolleri

### **Firebase Security Rules Önerisi**
```javascript
service firebase.storage {
  match /b/{bucket}/o {
    match /files/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 Kullanım Örnekleri

### **1. Employee Modülünde CV Yükleme**
```dart
FileUploadWidget(
  module: 'employees',
  collection: 'employee_cvs',
  additionalData: {
    'employeeId': widget.employee?.id ?? 'new',
    'employeeName': _nameController.text.trim(),
    'documentType': 'cv',
    'position': _positionController.text.trim(),
  },
  allowedExtensions: ['pdf', 'doc', 'docx'],
  onUploadSuccess: () {
    setState(() {
      _hasCvUploaded = true;
    });
  },
  onUploadError: (error) {
    setState(() {
      _hasCvUploaded = false;
    });
  },
  isRequired: false,
  showPreview: true,
),
```

### **2. Beauty Modülünde Belge Yönetimi**
```dart
FileUploadWidget(
  module: 'beauty',
  collection: 'beauty_documents',
  additionalData: {
    'title': _titleController.text.trim(),
    'category': _selectedCategory,
    'customerName': _customerNameController.text.trim(),
  },
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
  onUploadSuccess: () {
    setState(() {
      _hasFileUploaded = true;
    });
  },
  isRequired: true,
  showPreview: true,
),
```

## 📱 Platform Desteği

### **Web Platformu**
- Drag & drop dosya yükleme
- Çoklu dosya seçimi
- İlerleme çubuğu
- Önizleme modal'ı

### **Mobile Platformları (Android/iOS)**
- Galeri ve kamera erişimi
- Dosya yöneticisi entegrasyonu
- Döküman seçici
- Yerel dosya önizlemesi

### **Desteklenen Dosya Türleri**
- **Dokümanlar**: PDF, DOC, DOCX, TXT
- **Resimler**: JPG, JPEG, PNG, GIF
- **Tablolar**: XLS, XLSX, CSV
- **Medya**: MP4, MP3, AVI (limitli)
- **Özel**: DCM (Veteriner röntgen)

## ⚠️ Önemli Dikkat Edilecekler

### **1. Dosya Boyutu Limitleri**
- Maksimum dosya boyutu: 50MB
- Mobil platformlarda performans için 10MB önerilir
- Resim dosyaları için sıkıştırma uygulanabilir

### **2. Ağ Bağlantısı**
- Yavaş internet bağlantılarında timeout ayarları
- Retry mekanizması implementasyonu
- Offline durumda kullanıcı bilgilendirmesi

### **3. Depolama Maliyetleri**
- Firebase Storage ücretlendirme politikası
- Dosya yaşam döngüsü yönetimi
- Eski dosyaların temizlenmesi

### **4. Yedekleme ve Kurtarma**
- Kritik belgeler için yedekleme stratejisi
- Versiyon kontrolü implementasyonu
- Dosya silme işlemlerinde geri dönüş planı

## 🧪 Test Senaryoları

### **Temel Fonksiyonellik Testleri**
1. ✅ Dosya seçimi ve yükleme
2. ✅ Desteklenen dosya türü doğrulama
3. ✅ Dosya boyutu kontrolü
4. ✅ Yükleme ilerleme takibi
5. ✅ Başarılı yükleme sonrası UI güncellemesi

### **Hata Durumu Testleri**
1. ✅ Ağ bağlantısı kesilmesi
2. ✅ Desteklenmeyen dosya türü
3. ✅ Boyut sınırı aşılması
4. ✅ Firebase Storage erişim hatası
5. ✅ Firestore yazma hatası

### **Platform Spesifik Testler**
1. ✅ Web: Drag & drop işlevi
2. ✅ Android: File picker entegrasyonu
3. ✅ iOS: Document picker entegrasyonu
4. ✅ Tüm platformlar: Önizleme işlevi

### **Performance Testleri**
1. ✅ Büyük dosya yükleme performansı
2. ✅ Çoklu dosya yükleme
3. ✅ Bellek kullanımı
4. ✅ UI yanıt verme süresi

## 🔄 Gelecek Geliştirmeler

### **Kısa Vadeli İyileştirmeler**
- [ ] Dosya sıkıştırma özelliği
- [ ] Toplu dosya yükleme
- [ ] Gelişmiş önizleme (PDF viewer)
- [ ] Dosya etiketleme sistemi

### **Orta Vadeli Özellikler**
- [ ] OCR (optik karakter tanıma) entegrasyonu
- [ ] Versiyon kontrolü sistemi
- [ ] Otomatik backup mekanizması
- [ ] QR kod ile dosya paylaşımı

### **Uzun Vadeli Hedefler**
- [ ] AI bazlı dosya kategorilendirme
- [ ] Blockchain tabanlı dosya doğrulama
- [ ] Enterprise güvenlik sertifikaları
- [ ] Multi-cloud destek

## 📞 Destek ve Yardım

### **Hata Raporlama**
Herhangi bir sorun yaşarsanız aşağıdaki bilgileri toplayın:
- Platform (Web/Android/iOS)
- Dosya türü ve boyutu
- Hata mesajı
- Tekrarlama adımları

### **Performans İzleme**
Firebase Console üzerinden şu metrikleri takip edin:
- Dosya yükleme başarı oranı
- Ortalama yükleme süresi
- Storage kullanım miktarı
- Hata oranları

---

**📝 Not**: Bu dokümantasyon, belge yükleme sistemi için kapsamlı bir rehberdir. Sistem sürekli geliştirilmekte olup, yeni özellikler eklendiğinde dokümantasyon güncellenecektir.

**📅 Son Güncelleme**: Aralık 2024  
**🔖 Versiyon**: 1.0.0  
**👨‍💻 Geliştirici**: Flutter ERP Team 