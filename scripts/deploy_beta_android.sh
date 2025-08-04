#!/bin/bash

# Beta Android Deployment Script for Randevu ERP
# Bu script Flutter Android uygulamasını Google Play Console'a beta olarak deploy eder

set -e  # Hata durumunda scripti durdur

echo "🚀 Randevu ERP Beta Android Deployment Başlatılıyor..."

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Gerekli araçları kontrol et
check_requirements() {
    echo -e "${BLUE}📋 Gereksinimler kontrol ediliyor...${NC}"
    
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter bulunamadı. Lütfen Flutter'ı yükleyin.${NC}"
        exit 1
    fi
    
    # Android SDK kontrolü
    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${RED}❌ ANDROID_HOME bulunamadı. Android SDK'yı kurun.${NC}"
        exit 1
    fi
    
    # Keystore dosyası kontrolü
    if [ ! -f "android/app/key.properties" ]; then
        echo -e "${RED}❌ key.properties bulunamadı. Signing key'leri yapılandırın.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Tüm gereksinimler tamam.${NC}"
}

# Flutter dependencies'leri güncelle
update_dependencies() {
    echo -e "${BLUE}📦 Dependencies güncelleniyor...${NC}"
    flutter pub get
    flutter pub upgrade
    echo -e "${GREEN}✅ Dependencies güncellendi.${NC}"
}

# Beta konfigürasyonunu kontrol et
check_beta_config() {
    echo -e "${BLUE}⚙️ Beta konfigürasyonu kontrol ediliyor...${NC}"
    
    # AppConfig'de beta environment'ın aktif olduğunu kontrol et
    if grep -q "Environment.beta" lib/config/app_config.dart; then
        echo -e "${GREEN}✅ Beta konfigürasyonu aktif.${NC}"
    else
        echo -e "${YELLOW}⚠️ Beta konfigürasyonu aktif değil. Değiştiriliyor...${NC}"
        # Environment'ı beta'ya çevir
        sed -i 's/Environment.development/Environment.beta/g' lib/config/app_config.dart
        echo -e "${GREEN}✅ Beta konfigürasyonu aktif edildi.${NC}"
    fi
}

# Android build konfigürasyonunu güncelle
update_android_config() {
    echo -e "${BLUE}🤖 Android build konfigürasyonu güncelleniyor...${NC}"
    
    # build.gradle'daki version'ı güncelle
    GRADLE_FILE="android/app/build.gradle"
    
    # Version Code'u artır
    CURRENT_VERSION_CODE=$(grep -oP 'versionCode \K\d+' $GRADLE_FILE || echo "1")
    NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
    
    # Version Name'i beta olarak ayarla
    VERSION_NAME="1.0.0-beta.1"
    
    # Gradle dosyasını güncelle
    sed -i "s/versionCode $CURRENT_VERSION_CODE/versionCode $NEW_VERSION_CODE/g" $GRADLE_FILE
    sed -i "s/versionName \"[^\"]*\"/versionName \"$VERSION_NAME\"/g" $GRADLE_FILE
    
    # Application ID'yi beta için değiştir
    sed -i 's/applicationId "com.randevuerp"/applicationId "com.randevuerp.beta"/g' $GRADLE_FILE
    
    echo -e "${GREEN}✅ Android konfigürasyonu güncellendi (v$VERSION_NAME, build $NEW_VERSION_CODE).${NC}"
}

# Manifest dosyasını beta için ayarla
update_manifest() {
    echo -e "${BLUE}📋 Android Manifest beta için ayarlanıyor...${NC}"
    
    MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
    
    # App label'ı beta için değiştir
    sed -i 's/android:label="randevu_erp"/android:label="Randevu ERP (Beta)"/g' $MANIFEST_FILE
    
    # Internet permission'ı kontrol et
    if ! grep -q "android.permission.INTERNET" $MANIFEST_FILE; then
        echo -e "${YELLOW}⚠️ Internet permission ekleniyor...${NC}"
        sed -i '/<manifest/a \    <uses-permission android:name="android.permission.INTERNET" />' $MANIFEST_FILE
    fi
    
    echo -e "${GREEN}✅ Manifest güncellendi.${NC}"
}

# Android build oluştur
build_android() {
    echo -e "${BLUE}🔨 Android APK ve AAB build'leri oluşturuluyor...${NC}"
    
    # Build klasörünü temizle
    flutter clean
    
    # APK build (internal testing için)
    echo -e "${BLUE}📱 APK build oluşturuluyor...${NC}"
    flutter build apk --release --split-per-abi
    
    # AAB build (Play Store için)
    echo -e "${BLUE}📦 AAB bundle oluşturuluyor...${NC}"
    flutter build appbundle --release
    
    echo -e "${GREEN}✅ Android build'ler tamamlandı.${NC}"
}

# Fastlane ile Play Console'a yükle
deploy_to_play_store() {
    echo -e "${BLUE}🏪 Google Play Console'a yükleniyor...${NC}"
    
    # Fastlane kurulu mu kontrol et
    if ! command -v fastlane &> /dev/null; then
        echo -e "${YELLOW}⚠️ Fastlane bulunamadı. Manuel yükleme talimatları gösteriliyor...${NC}"
        show_manual_upload_instructions
        return
    fi
    
    # Fastlane ile beta track'e yükle
    cd android
    fastlane beta
    cd ..
    
    echo -e "${GREEN}✅ Play Store beta track'e yükleme tamamlandı.${NC}"
}

# Manuel yükleme talimatları
show_manual_upload_instructions() {
    echo -e "${BLUE}📋 Manuel Yükleme Talimatları:${NC}"
    echo ""
    echo -e "${YELLOW}1. Google Play Console'a gidin: https://play.google.com/console${NC}"
    echo -e "${YELLOW}2. Randevu ERP (Beta) uygulamasını seçin${NC}"
    echo -e "${YELLOW}3. 'Internal testing' veya 'Closed testing' seçin${NC}"
    echo -e "${YELLOW}4. 'Create new release' tıklayın${NC}"
    echo -e "${YELLOW}5. AAB dosyasını yükleyin: $(pwd)/build/app/outputs/bundle/release/app-release.aab${NC}"
    echo -e "${YELLOW}6. Release notes'u ekleyin${NC}"
    echo -e "${YELLOW}7. 'Review and rollout' tıklayın${NC}"
    echo ""
    echo -e "${GREEN}📱 APK dosya konumu (internal sharing için):${NC}"
    echo -e "${BLUE}   • ARM64: $(pwd)/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk${NC}"
    echo -e "${BLUE}   • ARMv7: $(pwd)/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk${NC}"
    echo -e "${BLUE}   • x64: $(pwd)/build/app/outputs/flutter-apk/app-x86_64-release.apk${NC}"
}

# Fastlane konfigürasyonu oluştur
create_fastlane_config() {
    echo -e "${BLUE}⚡ Fastlane konfigürasyonu oluşturuluyor...${NC}"
    
    mkdir -p android/fastlane
    
    # Fastfile oluştur
    cat > android/fastlane/Fastfile << 'EOF'
default_platform(:android)

platform :android do
  desc "Deploy a new beta version to Google Play"
  lane :beta do
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      release_status: 'draft'
    )
  end
  
  desc "Deploy to closed testing"
  lane :closed_beta do
    upload_to_play_store(
      track: 'beta',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end
end
EOF

    # Appfile oluştur
    cat > android/fastlane/Appfile << 'EOF'
json_key_file("path/to/service-account-key.json") # Google Play API key
package_name("com.randevuerp.beta") # Beta package name
EOF

    echo -e "${GREEN}✅ Fastlane konfigürasyonu oluşturuldu.${NC}"
    echo -e "${YELLOW}⚠️ Google Play API key'ini android/fastlane/Appfile'da yapılandırın.${NC}"
}

# Test APK'yı test cihazlarına dağıt
distribute_test_apk() {
    echo -e "${BLUE}📱 Test APK'ları dağıtılıyor...${NC}"
    
    # Firebase App Distribution kullanarak dağıt
    if command -v firebase &> /dev/null; then
        echo -e "${BLUE}🔥 Firebase App Distribution ile dağıtılıyor...${NC}"
        
        firebase appdistribution:distribute \
            build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
            --app 1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID \
            --groups "beta-testers" \
            --release-notes "Beta sürüm v1.0.0-beta.1 - Core features ready for testing"
            
        echo -e "${GREEN}✅ Firebase App Distribution'a yüklendi.${NC}"
    else
        echo -e "${YELLOW}⚠️ Firebase CLI bulunamadı. APK'lar local'de hazır:${NC}"
        echo -e "${BLUE}   ARM64: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk${NC}"
        echo -e "${BLUE}   ARMv7: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk${NC}"
    fi
}

# Test kullanıcıları için QR kod oluştur
generate_qr_codes() {
    echo -e "${BLUE}📱 Test için QR kodları oluşturuluyor...${NC}"
    
    # QR kod oluşturma için Python/Node.js gerekli
    # Bu kısım opsiyonel, manual olarak QR kod oluşturabilirsiniz
    
    echo -e "${GREEN}ℹ️ Test linkleri:${NC}"
    echo -e "${YELLOW}  • Play Store Internal Test: https://play.google.com/apps/internaltest/YOUR_LINK${NC}"
    echo -e "${YELLOW}  • Firebase App Distribution: https://appdistribution.firebase.dev/YOUR_LINK${NC}"
}

# Beta test kullanıcıları bildir
notify_beta_testers() {
    echo -e "${BLUE}📧 Beta testerları bilgilendiriliyor...${NC}"
    
    echo -e "${GREEN}ℹ️ Beta test bilgileri:${NC}"
    echo -e "${YELLOW}  📱 Platform: Android${NC}"
    echo -e "${YELLOW}  📋 Version: 1.0.0-beta.1${NC}"
    echo -e "${YELLOW}  👥 Test grubu: Internal testers${NC}"
    echo -e "${YELLOW}  📅 Test süresi: 30 gün${NC}"
    echo ""
    echo -e "${GREEN}📧 Test hesapları:${NC}"
    echo -e "${YELLOW}  • test.beauty@randevuerp.com (TestBeauty123!)${NC}"
    echo -e "${YELLOW}  • test.clinic@randevuerp.com (TestClinic123!)${NC}"
    echo -e "${YELLOW}  • test.sports@randevuerp.com (TestSports123!)${NC}"
}

# Cleanup sonrası
cleanup() {
    echo -e "${BLUE}🧹 Cleanup yapılıyor...${NC}"
    
    # Geçici dosyaları temizle
    flutter clean
    
    # Config dosyalarını development'a geri çevir
    sed -i 's/Environment.beta/Environment.development/g' lib/config/app_config.dart
    sed -i 's/applicationId "com.randevuerp.beta"/applicationId "com.randevuerp"/g' android/app/build.gradle
    sed -i 's/android:label="Randevu ERP (Beta)"/android:label="randevu_erp"/g' android/app/src/main/AndroidManifest.xml
    
    echo -e "${GREEN}✅ Cleanup tamamlandı.${NC}"
}

# Ana fonksiyon
main() {
    echo -e "${GREEN}=== RANDEVU ERP BETA ANDROID DEPLOYMENT ===${NC}"
    echo -e "${BLUE}Tarih: $(date)${NC}"
    echo -e "${BLUE}Platform: Android${NC}"
    echo -e "${BLUE}Versiyon: 1.0.0-beta.1${NC}"
    echo ""
    
    check_requirements
    update_dependencies
    check_beta_config
    update_android_config
    update_manifest
    build_android
    
    # Deployment seçenekleri
    echo -e "${BLUE}📋 Deployment seçenekleri:${NC}"
    echo -e "${YELLOW}1. Google Play Console (manuel)${NC}"
    echo -e "${YELLOW}2. Firebase App Distribution${NC}"
    echo -e "${YELLOW}3. Her ikisi${NC}"
    
    read -p "Seçiminizi yapın (1-3): " choice
    
    case $choice in
        1)
            show_manual_upload_instructions
            ;;
        2)
            distribute_test_apk
            ;;
        3)
            show_manual_upload_instructions
            distribute_test_apk
            ;;
        *)
            echo -e "${RED}❌ Geçersiz seçim. Manuel yükleme talimatları gösteriliyor.${NC}"
            show_manual_upload_instructions
            ;;
    esac
    
    generate_qr_codes
    notify_beta_testers
    
    echo ""
    echo -e "${GREEN}🎉 Beta Android deployment hazırlıkları tamamlandı!${NC}"
    echo -e "${BLUE}📱 APK Dosyaları: build/app/outputs/flutter-apk/app-*-release.apk${NC}"
    echo -e "${BLUE}📦 AAB Bundle: build/app/outputs/bundle/release/app-release.aab${NC}"
    echo -e "${BLUE}📋 Feedback: https://forms.google.com/randevu-erp-beta-feedback${NC}"
    
    # Cleanup yapmak isteyip istemediğini sor
    read -p "Cleanup yapmak istiyor musunuz? (y/n): " cleanup_choice
    if [[ $cleanup_choice =~ ^[Yy]$ ]]; then
        cleanup
    fi
}

# Script'i çalıştır
main "$@" 