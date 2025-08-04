import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import 'auth/login_page.dart';
import 'dashboard/dashboard_page.dart';

/// 🔐 Authentication Wrapper - Basit Versiyon
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _silentSignInAttempted = false;

  @override
  void initState() {
    super.initState();
    _attemptSilentSignIn();
  }

  Future<void> _attemptSilentSignIn() async {
    if (_silentSignInAttempted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInSilently();
      
      if (mounted) {
        setState(() {
          _silentSignInAttempted = true;
        });
      }
    } catch (e) {
      debugPrint('Silent sign-in hatası: $e');
      if (mounted) {
        setState(() {
          _silentSignInAttempted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!_silentSignInAttempted) {
          return _buildLoadingScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            final user = snapshot.data;
            if (user != null && authProvider.isAuthenticated) {
              return const DashboardPage();
            } else {
              return const LoginPage();
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Yükleniyor...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorSelectionPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sektör Seçimi'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            const Text(
              'Lütfen sektörünüzü seçin veya yönetici ile iletişime geçin.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton(
              onPressed: () {
                debugPrint('Sektör seçim sayfasına yönlendiriliyor...');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Sektör Seç'),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Geri'),
            ),
          ],
        ),
      ),
    );
  }
}