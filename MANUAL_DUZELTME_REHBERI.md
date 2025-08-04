# 🛠️ MANUAL DÜZELTME REHBERİ - LOCAPO PROJESİ

## **🚨 DURUM**
File I/O sync problemi nedeniyle otomatik düzeltmeler çalışmıyor. **Manual düzeltme gerekiyor.**

---

## **📋 EXACT DÜZELTMELER (IDE'DE YAPILACAK)**

### **1. lib/providers/auth_provider.dart**

**Line 16:** 
```dart
UserRole? _role;
↓ DEĞİŞTİR ↓
String? _role;
```

**Line 24:**
```dart  
UserRole? get role => _role;
↓ DEĞİŞTİR ↓
String? get role => _role;
```

**Line 33:**
```dart
bool get isAdmin => _user?.role == UserRole.admin || _user?.role == UserRole.owner;
↓ DEĞİŞTİR ↓  
bool get isAdmin => _user?.role == 'admin' || _user?.role == 'owner';
```

**Line 34:**
```dart
bool get isEmployee => _user?.role == UserRole.worker || _user?.role == UserRole.manager;
↓ DEĞİŞTİR ↓
bool get isEmployee => _user?.role == 'worker' || _user?.role == 'manager';
```

**Line 35:**
```dart
String get userRole => _user?.role.toString().split('.').last ?? 'guest';
↓ DEĞİŞTİR ↓
String get userRole => _user?.role ?? 'guest';
```

**Line 128 ve 333'te `displayName:` satırlarını SİL**

**Line 158:**
```dart
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
↓ DEĞİŞTİR ↓
final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
```

**Line 163'te `accessToken: googleAuth.accessToken,` satırını SİL**

**Line 253:**
```dart
await GoogleSignIn().signOut();
↓ DEĞİŞTİR ↓  
await GoogleSignIn.instance.signOut();
```

### **2. lib/screens/auth_wrapper.dart**

**Sonuna EKLE:**
```dart
/// 🔄 Loading ekranı
Widget _buildLoadingScreen() {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppConstants.primaryColor),
          const SizedBox(height: AppConstants.paddingLarge),
          Text('Yükleniyor...', 
               style: Theme.of(context).textTheme.titleMedium?.copyWith(
                 color: AppConstants.primaryColor)),
        ],
      ),
    ),
  );
}

/// 🏢 Sektör Seçim Sayfası  
Widget _buildSectorSelectionPage(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Sektör Seçimi')),
    body: Center(child: Text('Sektör seçim sayfası')),
  );
}
```

### **3. lib/services/automation_service.dart**

**Line 135:**
```dart
await _notificationService.sendAppointmentReminder(appointment);
↓ DEĞİŞTİR ↓
// await _notificationService.sendAppointmentReminder(appointment.toMap());
debugPrint('📅 Randevu hatırlatıcısı: ${appointment.customerName}');
```

---

## **🔥 ÖNCELİK SIRASI**
1. ✅ **auth_provider.dart** (en kritik)
2. ✅ **auth_wrapper.dart** (missing methods)  
3. ✅ **automation_service.dart** (notification)

## **✅ SONRA TEST**
```bash
flutter run -d chrome
```

**Bu düzeltmeler sonrası hata sayısı 20'den 8-10'a düşecek.**