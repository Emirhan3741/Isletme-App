import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider_enhanced.dart';
import '../providers/locale_provider.dart';
import '../widgets/ai_support_chat_widget.dart';
import 'auth/login_page.dart';
import 'landing/landing_page.dart';
import 'auth/sector_selection_enhanced.dart';

/// 🔐 Enhanced Authentication Wrapper with Smart Routing
class AuthWrapperEnhanced extends StatelessWidget {
  const AuthWrapperEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Consumer<AuthProviderEnhanced>(
          builder: (context, authProvider, child) {
            // Loading durumu
            if (authProvider.isLoading) {
              return _buildLoadingScreen();
            }
            
            // Hata durumu
            if (authProvider.error != null) {
              return _buildErrorScreen(authProvider.error!);
            }
            
            // Kullanıcı giriş yapmış mı kontrol et
            if (authProvider.isLoggedIn) {
              return _buildLoggedInFlow(context, authProvider);
            } else {
              // Kullanıcı giriş yapmamış - Landing sayfasına yönlendir
              return const LandingPage();
            }
          },
        ),
        
        // Global AI Support Chat Widget
        const AISupportChatWidget(),
      ],
    );
  }

  Widget _buildLoggedInFlow(BuildContext context, AuthProviderEnhanced authProvider) {
    // Kullanıcının dil tercihini uygula
    _applyUserLanguagePreference(context, authProvider);
    
    // Panel seçimi kontrolü
    final selectedPanel = authProvider.getCurrentUserSelectedPanel();
    
    debugPrint('🔍 AuthWrapper: selectedPanel = $selectedPanel');
    
    if (selectedPanel == null || selectedPanel.isEmpty) {
      debugPrint('📋 Panel seçilmemiş, SectorSelection gösteriliyor');
      // Panel seçilmemiş - Sektör seçim sayfasına yönlendir
      return const SectorSelectionEnhanced();
    } else {
      debugPrint('✅ Panel seçilmiş: $selectedPanel, yönlendiriliyor');
      // Panel seçilmiş - Doğru dashboard'a yönlendir
      final recommendedRoute = authProvider.getRecommendedRoute();
      if (recommendedRoute != null) {
        return _buildDashboardNavigation(recommendedRoute);
      } else {
        debugPrint('❌ Route bulunamadı, SectorSelection gösteriliyor');
        return const SectorSelectionEnhanced();
      }
    }
  }

  void _applyUserLanguagePreference(BuildContext context, AuthProviderEnhanced authProvider) {
    final userLanguage = authProvider.getCurrentUserLanguage();
    debugPrint('🌐 AuthWrapper: Kullanıcı dil tercihi = $userLanguage');
    
    if (userLanguage != null && userLanguage.isNotEmpty) {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      final currentLanguage = localeProvider.locale.languageCode;
      
      debugPrint('🌐 Mevcut dil: $currentLanguage, Hedef dil: $userLanguage');
      
      if (currentLanguage != userLanguage) {
        // Kullanıcının dil tercihini uygula
        debugPrint('✅ Dil değiştiriliyor: $currentLanguage -> $userLanguage');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await localeProvider.setLocale(Locale(userLanguage));
            debugPrint('✅ Dil başarıyla uygulandı: $userLanguage');
          } catch (e) {
            debugPrint('❌ Dil uygulama hatası: $e');
          }
        });
      } else {
        debugPrint('ℹ️ Dil zaten doğru, değişiklik yapılmadı');
      }
    } else {
      debugPrint('⚠️ Kullanıcı dil tercihi bulunamadı');
    }
  }

  Widget _buildDashboardNavigation(String routeName) {
    return Builder(
      builder: (context) {
        // Navigation'ı post-frame callback'te yap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(routeName);
        });
        
        // Geçici loading ekranı
        return _buildLoadingScreen(message: 'Dashboard\'a yönlendiriliyor...');
      },
    );
  }

  /// 🔄 Loading Screen
  Widget _buildLoadingScreen({String message = 'Yükleniyor...'}) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppConstants.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lütfen bekleyin...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Error Screen
  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Uygulamayı yeniden başlat
                debugPrint('Tekrar dene tıklandı');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}