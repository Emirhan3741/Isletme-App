import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// 🎯 Advanced App Router with Role-Based Navigation
class AppRouter {
  AppRouter._();

  /// 🚀 Panel seçimi sonrası doğru route'a yönlendirme
  static String? getRecommendedRoute(String? selectedPanel, {String? userRole}) {
    if (selectedPanel == null || selectedPanel.isEmpty) return null;

    final baseRoute = _getBaseRoute(selectedPanel);
    
    // Role-based modifikasyon (opsiyonel)
    if (userRole != null) {
      return _modifyRouteByRole(baseRoute, userRole);
    }
    
    return baseRoute;
  }

  /// 📱 Panel koduna göre temel route belirleme
  static String? _getBaseRoute(String panel) {
    switch (panel.toLowerCase()) {
      case 'beauty':
      case 'güzellik':
      case 'güzellik_salon':
      case 'beauty_salon':
        return '/beauty-dashboard';
        
      case 'lawyer':
      case 'avukat':
      case 'hukuk':
      case 'law':
        return '/lawyer-dashboard';
        
      case 'psychology':
      case 'psikoloji':
      case 'psikolog':
      case 'psychologist':
        return '/psychology-dashboard';
        
      case 'veterinary':
      case 'veteriner':
      case 'veterinarianism':
      case 'vet':
        return '/veterinary-dashboard';
        
      case 'sports':
      case 'spor':
      case 'gym':
      case 'fitness':
        return '/sports-dashboard';
        
      case 'clinic':
      case 'klinik':
      case 'health':
      case 'hospital':
        return '/clinic-dashboard';
        
      case 'education':
      case 'eğitim':
      case 'school':
      case 'okul':
        return '/education-dashboard';
        
      case 'real_estate':
      case 'emlak':
      case 'real-estate':
        return '/real-estate-dashboard';
        
      default:
        return null;
    }
  }

  /// 👤 Role göre route modifikasyonu
  static String _modifyRouteByRole(String? baseRoute, String userRole) {
    if (baseRoute == null) return '/landing';
    
    switch (userRole.toLowerCase()) {
      case 'admin':
      case 'owner':
        // Owner/Admin kullanıcılar tüm panellere erişebilir
        return baseRoute;
        
      case 'employee':
      case 'worker':
        // Employee kullanıcılar kısıtlı erişime sahip
        // Gerekirse özel employee dashboard'a yönlendir
        return baseRoute; // Şimdilik aynı dashboard
        
      case 'viewer':
      case 'guest':
        // Viewer'lar sadece okuma yetkisine sahip
        return '$baseRoute?mode=readonly';
        
      default:
        return baseRoute;
    }
  }

  /// 🗺️ Tüm route'ları listele
  static Map<String, WidgetBuilder> getAllRoutes() {
    return {
      // Auth Routes
      '/': (context) => _routeResolver(context),
      '/landing': (context) => _loadPage('landing'),
      '/login': (context) => _loadPage('login'),
      '/register': (context) => _loadPage('register'),
      '/sector-selection': (context) => _loadPage('sector-selection'),
      
      // Dashboard Routes
      '/beauty-dashboard': (context) => _loadPage('beauty-dashboard'),
      '/lawyer-dashboard': (context) => _loadPage('lawyer-dashboard'),
      '/psychology-dashboard': (context) => _loadPage('psychology-dashboard'),
      '/veterinary-dashboard': (context) => _loadPage('veterinary-dashboard'),
      '/sports-dashboard': (context) => _loadPage('sports-dashboard'),
      '/clinic-dashboard': (context) => _loadPage('clinic-dashboard'),
      '/education-dashboard': (context) => _loadPage('education-dashboard'),
      '/real-estate-dashboard': (context) => _loadPage('real-estate-dashboard'),
      
      // Module Routes
      '/customers': (context) => _loadPage('customers'),
      '/appointments': (context) => _loadPage('appointments'),
      '/calendar': (context) => _loadPage('calendar'),
      '/transactions': (context) => _loadPage('transactions'),
      '/expenses': (context) => _loadPage('expenses'),
      '/reports': (context) => _loadPage('reports'),
      '/settings': (context) => _loadPage('settings'),
      '/profile': (context) => _loadPage('profile'),
    };
  }

  /// 🔄 Smart route resolver (kullanıcı durumuna göre yönlendirme)
  static Widget _routeResolver(BuildContext context) {
    // AuthWrapperEnhanced bu mantığı zaten yapıyor
    // Bu method backup olarak kalıyor
    return _loadPage('auth-wrapper')(context);
  }

  /// 📄 Page loader (lazy loading desteği)
  static WidgetBuilder _loadPage(String pageName) {
    return (BuildContext context) {
      switch (pageName) {
        case 'auth-wrapper':
          return const Placeholder(child: Text('AuthWrapper'));
        case 'landing':
          return const Placeholder(child: Text('Landing Page'));
        case 'login':
          return const Placeholder(child: Text('Login Page'));
        case 'beauty-dashboard':
          return const Placeholder(child: Text('Beauty Dashboard'));
        case 'lawyer-dashboard':
          return const Placeholder(child: Text('Lawyer Dashboard'));
        // Diğer sayfalar buraya eklenecek...
        default:
          return const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          );
      }
    };
  }

  /// 🔍 Route validation
  static bool isValidRoute(String route) {
    return getAllRoutes().containsKey(route);
  }

  /// 📱 Platform-aware navigation
  static void navigateToPanel(
    BuildContext context, 
    String panelCode, {
    String? userRole,
    bool replace = true,
  }) {
    final route = getRecommendedRoute(panelCode, userRole: userRole);
    
    if (route != null && isValidRoute(route)) {
      if (replace) {
        Navigator.pushReplacementNamed(context, route);
      } else {
        Navigator.pushNamed(context, route);
      }
    } else {
      // Fallback: Sektör seçim sayfasına yönlendir
      Navigator.pushReplacementNamed(context, '/sector-selection');
    }
  }

  /// 🎨 Route ile ilgili UI bilgileri
  static RouteInfo getRouteInfo(String route) {
    switch (route) {
      case '/beauty-dashboard':
        return RouteInfo(
          title: 'Güzellik Salonu',
          icon: Icons.face_retouching_natural,
          color: Colors.pink,
        );
      case '/lawyer-dashboard':
        return RouteInfo(
          title: 'Avukatlık',
          icon: Icons.gavel,
          color: Colors.blue,
        );
      case '/psychology-dashboard':
        return RouteInfo(
          title: 'Psikoloji',
          icon: Icons.psychology,
          color: Colors.purple,
        );
      case '/veterinary-dashboard':
        return RouteInfo(
          title: 'Veterinarianism',
          icon: Icons.pets,
          color: Colors.green,
        );
      default:
        return RouteInfo(
          title: 'Bilinmeyen',
          icon: Icons.help,
          color: Colors.grey,
        );
    }
  }
}

/// 📋 Route bilgi modeli
class RouteInfo {
  final String title;
  final IconData icon;
  final Color color;
  final String? description;

  const RouteInfo({
    required this.title,
    required this.icon,
    required this.color,
    this.description,
  });
}