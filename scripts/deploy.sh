#!/bin/bash

# Production Deployment Script for Locapo ERP

echo "🚀 Starting Locapo ERP Production Deployment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Generate localization files
print_status "Generating localization files..."
flutter gen-l10n

# Run code analysis
print_status "Running code analysis..."
flutter analyze --no-pub

ANALYSIS_EXIT_CODE=$?
if [ $ANALYSIS_EXIT_CODE -ne 0 ]; then
    print_warning "Code analysis found issues, but continuing deployment..."
fi

# Run tests
print_status "Running unit tests..."
flutter test

TEST_EXIT_CODE=$?
if [ $TEST_EXIT_CODE -ne 0 ]; then
    print_error "Tests failed! Deployment aborted."
    exit 1
fi

# Build for different platforms
echo ""
print_status "Building for different platforms..."

# Web Build
print_status "Building for Web..."
flutter build web --release --web-renderer canvaskit --source-maps

if [ $? -eq 0 ]; then
    print_status "✅ Web build completed successfully!"
else
    print_error "❌ Web build failed!"
    exit 1
fi

# Android Build (APK)
print_status "Building Android APK..."
flutter build apk --release --split-per-abi

if [ $? -eq 0 ]; then
    print_status "✅ Android APK build completed successfully!"
else
    print_error "❌ Android APK build failed!"
    exit 1
fi

# Android Build (App Bundle)
print_status "Building Android App Bundle..."
flutter build appbundle --release

if [ $? -eq 0 ]; then
    print_status "✅ Android App Bundle build completed successfully!"
else
    print_error "❌ Android App Bundle build failed!"
    exit 1
fi

# Create deployment package
print_status "Creating deployment package..."
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PACKAGE_NAME="locapo_erp_v1.0.0_$TIMESTAMP"

mkdir -p "deploy/$PACKAGE_NAME"

# Copy build artifacts
cp -r build/web "deploy/$PACKAGE_NAME/"
cp build/app/outputs/flutter-apk/*.apk "deploy/$PACKAGE_NAME/"
cp build/app/outputs/bundle/release/*.aab "deploy/$PACKAGE_NAME/"

# Create deployment info
cat > "deploy/$PACKAGE_NAME/deployment_info.txt" << EOF
Locapo ERP Deployment Package
============================
Build Date: $(date)
Flutter Version: $(flutter --version | head -n 1)
Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")
Git Branch: $(git branch --show-current 2>/dev/null || echo "N/A")

Build Contents:
- Web build (build/web/)
- Android APK (split per ABI)
- Android App Bundle (AAB)

Deployment Instructions:
1. Upload web/ folder to your web hosting service
2. Upload APK to Google Play Console or distribute directly
3. Upload AAB to Google Play Console for optimized delivery

Notes:
- Web build uses CanvasKit renderer for better performance
- Android builds are release-optimized with ProGuard
- All localization files are included
EOF

# Archive the package
cd deploy
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
cd ..

print_status "✅ Deployment package created: deploy/$PACKAGE_NAME.tar.gz"

# Performance report
print_status "📊 Build Performance Report:"
echo "Web build size: $(du -sh build/web | cut -f1)"
echo "APK sizes:"
ls -lh build/app/outputs/flutter-apk/*.apk | awk '{print $9 ": " $5}'

# Final success message
echo ""
print_status "🎉 Deployment completed successfully!"
print_status "Package location: deploy/$PACKAGE_NAME.tar.gz"
print_status "Ready for production deployment!"

# Optional: Upload to cloud storage or deployment service
# Uncomment and configure as needed
# print_status "Uploading to deployment service..."
# gsutil cp "deploy/$PACKAGE_NAME.tar.gz" gs://your-deployment-bucket/
# firebase deploy --only hosting

echo ""
print_status "Deployment script completed. Check the deploy/ folder for all build artifacts."