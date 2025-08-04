# 🚀 Randevu ERP Beta Yayın Rehberi

Bu dokümantasyon Randevu ERP uygulamasının beta test sürecini ve yayın adımlarını kapsamaktadır.

## 📋 İçindekiler

1. [Beta Sürüm Özeti](#beta-sürüm-özeti)
2. [Teknik Gereksinimler](#teknik-gereksinimler)
3. [Beta Deployment](#beta-deployment)
4. [Test Kullanıcıları](#test-kullanıcıları)
5. [Test Senaryoları](#test-senaryoları)
6. [Bilinen Sorunlar](#bilinen-sorunlar)
7. [Feedback Süreci](#feedback-süreci)
8. [Troubleshooting](#troubleshooting)

## 📱 Beta Sürüm Özeti

### Versiyon: 1.0.0-beta.1
### Build: 1
### Yayın Tarihi: [TARIH]

### ✅ Dahil Edilen Core Özellikler

#### 1. 📊 Dashboard
- Gerçek zamanlı istatistikler
- Bugünkü randevular, aylık gelir, bekleyen ödemeler
- Hızlı işlem butonları
- Son aktiviteler görüntüleme
- Modern ve responsive tasarım

#### 2. 👥 Müşteri Yönetimi
- Müşteri ekleme, düzenleme, silme
- Gelişmiş arama ve filtreleme
- Export özelliği (CSV, PDF, JSON)
- Müşteri detay sayfası
- İletişim bilgileri yönetimi

#### 3. 📅 Randevu Yönetimi
- Randevu oluşturma ve düzenleme
- Takvim görünümü
- Randevu durumu takibi
- Çakışma kontrolü
- Müşteri ve hizmet entegrasyonu

#### 4. 💰 Finansal İşlemler
- Gelir/gider kayıtları
- Real-time finansal özet
- Pagination sistemi
- Kategori bazlı filtreleme
- Ödeme yöntemi takibi

#### 5. 📝 Not Yönetimi
- Kategori bazlı not sistemi
- Öncelik seviyeleri
- Hatırlatıcı sistemi
- Yapılacaklar listesi
- Arama ve filtreleme

### 🏢 Desteklenen Sektörler

- **Güzellik Salonu**: Saç, cilt, tırnak bakım hizmetleri
- **Klinik**: Muayene, tahlil, tedavi hizmetleri
- **Spor**: Antrenman, grup dersleri, fitness hizmetleri

## 🔧 Teknik Gereksinimler

### Development Environment
- **Flutter**: 3.24.0+ 
- **Dart**: 3.5.0+
- **Firebase**: Latest CLI
- **Node.js**: 16+ (Firebase CLI için)

### Minimum Device Requirements

#### Android
- **OS**: Android 5.0 (API level 21)+
- **RAM**: 2GB+
- **Storage**: 100MB boş alan
- **Network**: Internet bağlantısı gerekli

#### Web
- **Browsers**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **RAM**: 4GB+
- **Network**: Broadband internet

### Firebase Configuration
```json
{
  "development": {
    "projectId": "randevu-erp-dev",
    "storageBucket": "randevu-erp-dev.appspot.com"
  },
  "beta": {
    "projectId": "randevu-erp-beta", 
    "storageBucket": "randevu-erp-beta.appspot.com"
  }
}
```

## 🚀 Beta Deployment

### Web Deployment

#### Otomatik Deployment
```bash
# Script'i çalıştırılabilir yap
chmod +x scripts/deploy_beta_web.sh

# Beta web deployment'ı başlat
./scripts/deploy_beta_web.sh
```

#### Manuel Deployment
```bash
# Dependencies güncelle
flutter pub get

# Beta konfigürasyonunu aktif et
# lib/config/app_config.dart içinde Environment.beta olarak ayarla

# Web build oluştur
flutter build web --release --web-renderer canvaskit

# Firebase hosting'e deploy et
firebase use randevu-erp-beta
firebase deploy --only hosting
```

### Android Deployment

#### Otomatik Deployment
```bash
# Script'i çalıştırılabilir yap
chmod +x scripts/deploy_beta_android.sh

# Beta Android deployment'ı başlat
./scripts/deploy_beta_android.sh
```

#### Manuel Deployment
1. **Build Configuration**
   ```gradle
   // android/app/build.gradle
   applicationId "com.randevuerp.beta"
   versionCode 1
   versionName "1.0.0-beta.1"
   ```

2. **Build Commands**
   ```bash
   # APK build
   flutter build apk --release --split-per-abi
   
   # AAB build (Play Store için)
   flutter build appbundle --release
   ```

3. **Play Console Upload**
   - Google Play Console → Internal Testing
   - AAB dosyasını yükle: `build/app/outputs/bundle/release/app-release.aab`
   - Release notes ekle
   - Test grubunu seç

## 👤 Test Kullanıcıları

### Hazır Test Hesapları

#### Güzellik Salonu Testi
- **Email**: `test.beauty@randevuerp.com`
- **Password**: `TestBeauty123!`
- **Role**: Beauty Salon Owner
- **Test Data**: ✅ Otomatik oluşturulur

#### Klinik Testi
- **Email**: `test.clinic@randevuerp.com`
- **Password**: `TestClinic123!`
- **Role**: Clinic Doctor
- **Test Data**: ✅ Otomatik oluşturulur

#### Spor Merkezi Testi
- **Email**: `test.sports@randevuerp.com`
- **Password**: `TestSports123!`
- **Role**: Sports Coach
- **Test Data**: ✅ Otomatik oluşturulur

### Test Data İçeriği

Her test hesabı için otomatik olarak oluşturulan veriler:
- **20 müşteri** (rastgele isimler ve bilgiler)
- **7 hizmet** (sektöre uygun)
- **25 randevu** (15 geçmiş, 10 gelecek)
- **30 finansal işlem** (20 gelir, 10 gider)
- **10 not** (çeşitli kategorilerde)

### Beta Limitleri

Beta test süresince aşağıdaki limitler geçerlidir:
- **Müşteri**: Max 100
- **Randevu**: Max 500
- **İşlem**: Max 1,000
- **Not**: Max 200
- **Hizmet**: Max 50
- **Çalışan**: Max 10
- **Dosya Upload**: Max 10MB
- **Günlük API Call**: Max 5,000

## 🧪 Test Senaryoları

### 1. Kullanıcı Kaydı ve Giriş
- [ ] Yeni hesap oluşturma
- [ ] Email doğrulama
- [ ] Şifre sıfırlama
- [ ] Test hesapları ile giriş
- [ ] Çıkış yapma

### 2. Dashboard Testi
- [ ] İstatistiklerin doğru yüklenmesi
- [ ] Hızlı işlem butonlarının çalışması
- [ ] Grafik ve verilerin güncel olması
- [ ] Responsive tasarımın mobilde çalışması

### 3. Müşteri Yönetimi
- [ ] Yeni müşteri ekleme
- [ ] Müşteri bilgilerini güncelleme
- [ ] Müşteri silme
- [ ] Arama ve filtreleme
- [ ] Export işlemleri (CSV, PDF)
- [ ] Pagination çalışması

### 4. Randevu Yönetimi
- [ ] Yeni randevu oluşturma
- [ ] Randevu düzenleme
- [ ] Çakışma kontrolü
- [ ] Takvim görünümü
- [ ] Randevu durumu değiştirme
- [ ] Müşteri seçimi

### 5. Finansal İşlemler
- [ ] Gelir kaydı ekleme
- [ ] Gider kaydı ekleme
- [ ] İşlem düzenleme
- [ ] Filtreleme ve arama
- [ ] Özetlerin doğru hesaplanması
- [ ] Pagination sistem

### 6. Not Yönetimi
- [ ] Not ekleme (tüm kategoriler)
- [ ] Not düzenleme
- [ ] Öncelik seviyesi ayarlama
- [ ] Hatırlatıcı ekleme
- [ ] Yapılacak işaretleme
- [ ] Filtreleme ve arama

### 7. Performance Testi
- [ ] Sayfa yükleme süreleri (< 3 saniye)
- [ ] Large data set'lerde performans
- [ ] Memory usage kontrolü
- [ ] Network request optimizasyonu
- [ ] Offline davranış (PWA)

### 8. UI/UX Testi
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Touch gestures (mobile)
- [ ] Keyboard navigation
- [ ] Color contrast accessibility
- [ ] Error message clarity
- [ ] Loading states

## ⚠️ Bilinen Sorunlar

### 🐛 Bug'lar
1. **Customer Detail Page**: Tabbed navigation dispose issue (Fixed ✅)
2. **Memory Leaks**: TextEditingController disposal (Fixed ✅)
3. **Pagination**: Performance optimization needed for large datasets
4. **Offline Mode**: Limited offline functionality

### 🚧 Eksik Özellikler (v1.0 için)
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Advanced reporting
- [ ] Voice notes
- [ ] Video call integration
- [ ] AI assistant
- [ ] Bulk operations
- [ ] Data import/export wizard

### 📱 Platform Specific Issues

#### Android
- Notification permissions (Android 13+)
- File picker permissions
- Camera permissions

#### Web
- File download behavior varies by browser
- PWA installation prompts
- IndexedDB storage limits

## 📋 Feedback Süreci

### Feedback Channels

1. **Google Form**: [https://forms.google.com/randevu-erp-beta-feedback](https://forms.google.com/randevu-erp-beta-feedback)
2. **GitHub Issues**: [https://github.com/randevu-erp/issues](https://github.com/randevu-erp/issues)
3. **Email**: beta@randevu-erp.com
4. **Support**: support@randevu-erp.com

### Bug Reporting Template

```markdown
**Environment:**
- Platform: [Android/Web/iOS]
- Version: 1.0.0-beta.1
- Device: [Device model]
- Browser: [Browser version if web]

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Screenshots:**
[If applicable]

**Additional Context:**
[Any other relevant information]
```

### Feature Request Template

```markdown
**Feature Title:**
[Brief title]

**Description:**
[Detailed description]

**Use Case:**
[Why is this needed?]

**Priority:**
[Low/Medium/High]

**Sector:**
[Beauty/Clinic/Sports/All]
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Login Problems
**Problem**: Cannot login with test accounts
**Solution**: 
- Clear browser cache/app data
- Check internet connection
- Verify credentials are correct
- Try different test account

#### 2. Data Not Loading
**Problem**: Dashboard shows no data
**Solution**:
- Check network connection
- Refresh the page/app
- Logout and login again
- Contact support if persists

#### 3. Performance Issues
**Problem**: App is slow or unresponsive
**Solution**:
- Close other apps/tabs
- Check device RAM usage
- Clear app cache
- Try on different device/browser

#### 4. Build Issues (Developers)
**Problem**: Build fails during deployment
**Solution**:
```bash
# Clear cache
flutter clean

# Update dependencies
flutter pub get
flutter pub upgrade

# Check Flutter doctor
flutter doctor

# Rebuild
flutter build [platform] --release
```

### Emergency Contacts

- **Technical Lead**: developer@randevu-erp.com
- **Beta Coordinator**: beta@randevu-erp.com
- **Support Team**: support@randevu-erp.com

### Debug Mode

Beta uygulamasında debug bilgileri:
```dart
// AppConfig.dart içinde
static bool get enableDebugTools => true; // Beta'da aktif
```

Debug panel'de:
- Network requests log
- Performance metrics
- Error tracking
- Feature flags

## 📊 Success Metrics

### Beta Test Goals

#### Technical Metrics
- [ ] Crash rate < 1%
- [ ] ANR rate < 0.5%
- [ ] Page load time < 3s
- [ ] API response time < 1s
- [ ] Memory usage < 200MB

#### User Experience Metrics  
- [ ] Task completion rate > 90%
- [ ] User satisfaction > 4.0/5.0
- [ ] Bug severity distribution
- [ ] Feature usage analytics
- [ ] Retention rate > 70%

#### Business Metrics
- [ ] Core feature adoption > 80%
- [ ] Data entry accuracy > 95%
- [ ] Support ticket volume < 10/week
- [ ] User feedback sentiment analysis

### Test Completion Criteria

Beta test başarıyla tamamlanmış sayılır:
- ✅ Tüm critical bug'lar çözülmüş
- ✅ Core features test edilmiş
- ✅ Performance targets karşılanmış
- ✅ User feedback incorporated
- ✅ Security review completed

## 🎯 Next Steps (Post-Beta)

### v1.0 Production Release
1. **Bug Fixes**: Beta feedback ile gelen kritik bug'lar
2. **Performance Optimization**: Load time improvements
3. **UI Polish**: Minor design improvements
4. **Documentation**: User guides ve video tutorials
5. **Marketing Materials**: Store listings, screenshots
6. **Production Deployment**: Live environment setup

### v1.1 Feature Roadmap
- Advanced reporting dashboard
- Multi-language support (EN, DE, FR)
- Dark mode theme
- Offline data sync
- Bulk operations
- Mobile app store release

## 📞 Support

Beta test sürecinde herhangi bir sorun yaşarsanız:

**İletişim Kanalları:**
- 📧 Email: beta@randevu-erp.com
- 🐛 Bug Report: GitHub Issues
- 💬 Feedback: Google Forms
- 📞 Acil Durum: support@randevu-erp.com

**Response Times:**
- Critical issues: 2 hours
- High priority: 24 hours  
- Medium priority: 48 hours
- Low priority: 1 week

---

**Beta Test Period**: 30 gün
**Start Date**: [TARİH]
**End Date**: [TARİH]

> **Not**: Bu dokümantasyon beta test süresince güncellenecektir. Güncel versiyonu GitHub repository'den takip edebilirsiniz. 