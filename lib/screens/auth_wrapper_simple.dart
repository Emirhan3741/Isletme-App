import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import 'auth/login_page.dart';
import 'landing/landing_page.dart';
import 'auth/sector_selection_page.dart';

/// 🔐 Simplified Authentication Wrapper - No Provider Dependencies
class AuthWrapperSimple extends StatelessWidget {
  const AuthWrapperSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        // Hata durumu
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }
        
        // Kullanıcı giriş yapmış mı kontrol et
        if (snapshot.hasData && snapshot.data != null) {
          // Kullanıcı giriş yapmış - Sektör seçimine yönlendir
          return const SectorSelectionPage();
        } else {
          // Kullanıcı giriş yapmamış - Landing sayfasına yönlendir
          return const LandingPage();
        }
      },
    );
  }

  /// 🔄 Loading Screen
  Widget _buildLoadingScreen() {
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
              'Yükleniyor...',
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
                // Uygulamayı yeniden başlat - StatelessWidget olduğu için basit
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