import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as auth_provider;
import 'auth/login_page.dart';
import 'dashboard/dashboard_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        // Auth state stream dinle
        return StreamBuilder<User?>(
          stream: authProvider.authStateChanges,
          builder: (context, snapshot) {
            // Bağlantı durumu kontrol et
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Yükleniyor...'),
                    ],
                  ),
                ),
              );
            }

            // Hata durumu kontrol et
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bir hata oluştu',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Sayfayı yenile
                          authProvider.loadCurrentUser();
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Auth durumu kontrolü
            final User? user = snapshot.data;
            
            if (user != null) {
              // Kullanıcı giriş yapmış
              // AuthProvider'daki kullanıcı bilgilerini güncelle
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authProvider.user == null) {
                  authProvider.loadCurrentUser();
                }
              });

              // Dashboard'a yönlendir
              return const DashboardPage();
            } else {
              // Kullanıcı giriş yapmamış
              // AuthProvider'daki kullanıcı bilgilerini temizle
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authProvider.user != null) {
                  authProvider.signOut();
                }
              });

              // Login sayfasına yönlendir
              return const LoginPage();
            }
          },
        );
      },
    );
  }
} 