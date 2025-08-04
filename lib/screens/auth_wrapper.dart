import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import 'auth/login_page.dart';
import 'dashboard/dashboard_page.dart';

/// 🔐 Authentication Wrapper - Firebase Auth State Management
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        }
        
        // Hata durumu
        if (snapshot.hasError) {
          return _buildErrorScreen(context, snapshot.error.toString());
        }
        
        // Kullanıcı giriş yapmış mı kontrol et
        if (snapshot.hasData && snapshot.data != null) {
          // Provider ile kullanıcı bilgilerini senkronize et
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              // Provider'daki kullanıcı bilgisi Firebase ile senkron değilse güncelle
              if (authProvider.user == null) {
                // Async olarak kullanıcı bilgilerini yükle
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authProvider.signInSilently();
                });
                return _buildLoadingScreen(context);
              }
              
              // Kullanıcı role'ü kontrol et
              if (authProvider.user?.role.isEmpty ?? true) {
                return _buildSectorSelectionPage(context);
              }
              
              // Ana dashboard'a yönlendir
              return const DashboardPage();
            },
          );
        } else {
          // Kullanıcı giriş yapmamış - Login sayfasına yönlendir
          return const LoginPage();
        }
      },
    );
  }

  /// 🔄 Loading Screen
  Widget _buildLoadingScreen(BuildContext context) {
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
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              AppLocalizations.of(context)?.loading ?? 'Yükleniyor...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Lütfen bekleyin...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ❌ Error Screen
  Widget _buildErrorScreen(BuildContext context, String error) {
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
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton(
              onPressed: () {
                // Uygulamayı yeniden başlat
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                  (route) => false,
                );
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

  /// 🏢 Sector Selection Screen
  Widget _buildSectorSelectionPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.sector ?? 'Sektör Seçimi'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              // Çıkış yap
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 100,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
              Text(
                'Hoş Geldiniz! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                AppLocalizations.of(context)?.pleaseSelectSectorOrContactAdmin ??
                    'Lütfen sektörünüzü seçin veya yönetici ile iletişime geçin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: AppConstants.paddingXLarge),
              
              // Sektör Seçim Butonları
              _buildSectorButton(
                context, 
                'Güzellik & SPA', 
                Icons.spa, 
                () => _selectSector(context, 'beauty')
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildSectorButton(
                context, 
                'Spor & Fitness', 
                Icons.fitness_center, 
                () => _selectSector(context, 'sports')
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildSectorButton(
                context, 
                'Sağlık & Medikal', 
                Icons.local_hospital, 
                () => _selectSector(context, 'medical')
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildSectorButton(
                context, 
                'Diğer', 
                Icons.more_horiz, 
                () => _selectSector(context, 'other')
              ),
              
              const SizedBox(height: AppConstants.paddingXLarge),
              
              // Yardım butonu
              TextButton.icon(
                onPressed: () {
                  _showHelpDialog(context);
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Yardıma ihtiyacım var'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏢 Sektör Seçim Butonu
  Widget _buildSectorButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.primaryColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppConstants.primaryColor, width: 1),
          ),
        ),
      ),
    );
  }

  /// 🎯 Sektör Seçim İşlemi
  void _selectSector(BuildContext context, String sector) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // TODO: Sektör bilgisini kullanıcı profiline kaydet
    debugPrint('Seçilen sektör: $sector');
    
    // Geçici olarak dashboard'a yönlendir
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardPage()),
    );
  }

  /// 💬 Yardım Dialog'u
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: const Text(
          'Sektörünüzü bulamıyor musunuz?\n\n'
          'Lütfen sistem yöneticisi ile iletişime geçin veya '
          'destek ekibimize ulaşın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.back ?? 'Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Destek sayfasına yönlendir
              debugPrint('Destek sayfasına yönlendiriliyor...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('İletişim'),
          ),
        ],
      ),
    );
  }
}