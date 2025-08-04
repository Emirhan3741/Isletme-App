#!/bin/bash

# Beta Web Deployment Script for Randevu ERP
# Bu script Flutter web uygulamasını Firebase Hosting'e beta olarak deploy eder

set -e  # Hata durumunda scripti durdur

echo "🚀 Randevu ERP Beta Web Deployment Başlatılıyor..."

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
    
    if ! command -v firebase &> /dev/null; then
        echo -e "${RED}❌ Firebase CLI bulunamadı. Lütfen 'npm install -g firebase-tools' çalıştırın.${NC}"
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

# Web build oluştur
build_web() {
    echo -e "${BLUE}🔨 Web build oluşturuluyor...${NC}"
    
    # Build klasörünü temizle
    flutter clean
    
    # Web için optimize edilmiş build
    flutter build web \
        --release \
        --web-renderer canvaskit \
        --base-href "/" \
        --source-maps \
        --pwa-strategy=offline-first
    
    echo -e "${GREEN}✅ Web build tamamlandı.${NC}"
}

# Firebase hosting için hazırla
prepare_firebase() {
    echo -e "${BLUE}🔥 Firebase deployment hazırlanıyor...${NC}"
    
    # Firebase projesi seç (beta environment)
    firebase use randevu-erp-beta --add
    
    # Firebase.json'ı kontrol et veya oluştur
    if [ ! -f "firebase.json" ]; then
        echo -e "${YELLOW}⚠️ firebase.json bulunamadı. Oluşturuluyor...${NC}"
        create_firebase_config
    fi
    
    echo -e "${GREEN}✅ Firebase hazırlıkları tamamlandı.${NC}"
}

# Firebase.json dosyasını oluştur
create_firebase_config() {
    cat > firebase.json << EOF
{
  "hosting": {
    "site": "randevu-erp-beta",
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=3600"
          }
        ]
      },
      {
        "source": "**/*.@(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000"
          }
        ]
      }
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
EOF
    echo -e "${GREEN}✅ firebase.json oluşturuldu.${NC}"
}

# Beta versiyonu deploy et
deploy_to_firebase() {
    echo -e "${BLUE}🚀 Firebase Hosting'e deploy ediliyor...${NC}"
    
    # Beta channel'a deploy et
    firebase deploy --only hosting --project randevu-erp-beta
    
    echo -e "${GREEN}✅ Beta deployment tamamlandı!${NC}"
    echo -e "${BLUE}🌐 Beta URL: https://randevu-erp-beta.web.app${NC}"
}

# Beta test kullanıcıları bildir
notify_beta_testers() {
    echo -e "${BLUE}📧 Beta testerları bilgilendiriliyor...${NC}"
    
    # Burada beta testerlarına email gönderme veya Slack bildirimi
    # yapılabilir (opsiyonel)
    
    echo -e "${GREEN}ℹ️ Beta test hesapları:${NC}"
    echo -e "${YELLOW}  • test.beauty@randevuerp.com (TestBeauty123!)${NC}"
    echo -e "${YELLOW}  • test.clinic@randevuerp.com (TestClinic123!)${NC}"
    echo -e "${YELLOW}  • test.sports@randevuerp.com (TestSports123!)${NC}"
}

# Rollback fonksiyonu
rollback() {
    echo -e "${RED}❌ Deployment sırasında hata oluştu. Rollback yapılıyor...${NC}"
    
    # Önceki versiyona geri dön
    firebase hosting:channel:deploy previous --project randevu-erp-beta
    
    echo -e "${YELLOW}⚠️ Önceki versiyon geri yüklendi.${NC}"
    exit 1
}

# Ana fonksiyon
main() {
    echo -e "${GREEN}=== RANDEVU ERP BETA WEB DEPLOYMENT ===${NC}"
    echo -e "${BLUE}Tarih: $(date)${NC}"
    echo -e "${BLUE}Versiyon: 1.0.0-beta.1${NC}"
    echo ""
    
    # Hata durumunda rollback yap
    trap rollback ERR
    
    check_requirements
    update_dependencies
    check_beta_config
    build_web
    prepare_firebase
    deploy_to_firebase
    notify_beta_testers
    
    echo ""
    echo -e "${GREEN}🎉 Beta deployment başarıyla tamamlandı!${NC}"
    echo -e "${BLUE}📱 Test URL: https://randevu-erp-beta.web.app${NC}"
    echo -e "${BLUE}📋 Feedback: https://forms.google.com/randevu-erp-beta-feedback${NC}"
    echo -e "${BLUE}🐛 Bug Report: https://github.com/randevu-erp/issues${NC}"
}

# Script'i çalıştır
main "$@" 