import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_enhanced.dart';
import '../core/routing/app_router.dart';
import '../core/constants/app_constants.dart';

/// 🏠 Role-Based Home Widget
class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderEnhanced>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        if (user == null) {
          return _buildNotLoggedInView(context);
        }

        return _buildLoggedInView(context, authProvider);
      },
    );
  }

  /// 🔐 Giriş yapmamış kullanıcı görünümü
  Widget _buildNotLoggedInView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu ERP'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Lütfen giriş yapın',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 Giriş yapmış kullanıcı görünümü
  Widget _buildLoggedInView(BuildContext context, AuthProviderEnhanced authProvider) {
    final user = authProvider.user!;
    final selectedPanel = authProvider.getCurrentUserSelectedPanel();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getWelcomeMessage(user.name, user.role)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _buildUserMenu(context, authProvider),
        ],
      ),
      body: selectedPanel != null 
        ? _buildPanelDashboard(context, selectedPanel, user.role)
        : _buildPanelSelection(context),
    );
  }

  /// 👋 Karşılama mesajı
  String _getWelcomeMessage(String userName, String userRole) {
    final roleText = _getRoleText(userRole);
    return 'Hoş geldin, $userName ($roleText)';
  }

  /// 🏷️ Role text çevirisi
  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'owner': return 'İşletme Sahibi';
      case 'admin': return 'Admin';
      case 'employee': return 'Çalışan';
      case 'worker': return 'Personel';
      case 'viewer': return 'Görüntüleyici';
      default: return role;
    }
  }

  /// 👤 Kullanıcı menüsü
  Widget _buildUserMenu(BuildContext context, AuthProviderEnhanced authProvider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle),
      onSelected: (value) => _handleUserMenuAction(context, value, authProvider),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'change-panel',
          child: ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Panel Değiştir'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Ayarlar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// 🎯 Kullanıcı menü aksiyonları
  void _handleUserMenuAction(
    BuildContext context, 
    String action, 
    AuthProviderEnhanced authProvider,
  ) async {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
        
      case 'change-panel':
        Navigator.pushNamed(context, '/sector-selection');
        break;
        
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
        
      case 'logout':
        await _handleLogout(context, authProvider);
        break;
    }
  }

  /// 🚪 Çıkış işlemi
  Future<void> _handleLogout(
    BuildContext context, 
    AuthProviderEnhanced authProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/landing', 
          (route) => false,
        );
      }
    }
  }

  /// 🎯 Panel seçimi görünümü
  Widget _buildPanelSelection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 80,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Bir panel seçin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sector-selection');
            },
            child: const Text('Panel Seç'),
          ),
        ],
      ),
    );
  }

  /// 📱 Panel dashboard görünümü
  Widget _buildPanelDashboard(BuildContext context, String selectedPanel, String userRole) {
    final routeInfo = AppRouter.getRouteInfo(
      AppRouter.getRecommendedRoute(selectedPanel, userRole: userRole) ?? '/dashboard'
    );

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: routeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Icon(
                      routeInfo.icon,
                      color: routeInfo.color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeInfo.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Panel: $selectedPanel',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppRouter.navigateToPanel(context, selectedPanel, userRole: userRole);
                    },
                    child: const Text('Panele Git'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Quick Actions
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppConstants.paddingMedium),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              children: _buildQuickActions(context, selectedPanel),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Hızlı aksiyonlar
  List<Widget> _buildQuickActions(BuildContext context, String selectedPanel) {
    return [
      _buildQuickActionCard(
        title: 'Randevular',
        icon: Icons.calendar_today,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/appointments'),
      ),
      _buildQuickActionCard(
        title: 'Müşteriler',
        icon: Icons.people,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/customers'),
      ),
      _buildQuickActionCard(
        title: 'İşlemler',
        icon: Icons.receipt,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/transactions'),
      ),
      _buildQuickActionCard(
        title: 'Raporlar',
        icon: Icons.bar_chart,
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/reports'),
      ),
    ];
  }

  /// 🎯 Hızlı aksiyon kartı
  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}