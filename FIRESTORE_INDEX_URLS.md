# 🔥 FIRESTORE INDEX SORUNU ÇÖZÜMÜ

## 🚨 ACİL DURUM: Index Hatası

Proje çalıştırıldığında şu hatayı alıyorsanız:
```
[cloud_firestore/failed-precondition] The query requires an index.
```

## 🔧 HIZLI ÇÖZÜM

### Yöntem 1: Otomatik Index Oluşturma
1. Terminal'de projeyi çalıştırın:
   ```bash
   flutter run -d chrome
   ```

2. Hata mesajında verilen URL'yi kopyalayın ve tarayıcıda açın

3. "Create Index" butonuna tıklayın

4. 1-2 dakika bekleyin

### Yöntem 2: Manuel Firebase Console
1. [Firebase Console](https://console.firebase.google.com/) açın
2. Projenizi seçin
3. Firestore Database → Indexes bölümüne gidin
4. Aşağıdaki index'leri manuel olarak oluşturun:

## 📋 GEREKLİ INDEX'LER

### Appointments Collection
```
Collection: appointments
Fields: 
- userId (Ascending)
- date (Ascending) 
- status (Ascending)
```

### Beauty Transactions
```
Collection: beauty_transactions  
Fields:
- userId (Ascending)
- date (Descending)
- type (Ascending)
```

### Beauty Customers
```
Collection: beauty_customers
Fields:
- userId (Ascending) 
- createdAt (Descending)
- isActive (Ascending)
```

### AI Chat Sessions
```
Collection: ai_chat_sessions
Fields:
- userEmail (Ascending)
- createdAt (Descending)
```

## ⚡ OTOMATİK ÇÖZÜM SCRIPTI

Proje `scripts/deploy_firestore_indexes.bat` dosyasını çalıştırın:

```bash
cd scripts
deploy_firestore_indexes.bat
```

## 📞 YARDIM

Sorun devam ederse:
1. Firebase proje izinlerinizi kontrol edin
2. Internet bağlantınızı kontrol edin
3. Firebase CLI'nin güncel olduğundan emin olun

---
✅ **BAŞARILI**: Index'ler oluşturulduktan sonra uygulama sorunsuz çalışacaktır.