import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 📱 Public Header Widget
/// Marketing sayfalarının üst menü çubuğu
class PublicHeaderWidget extends StatefulWidget {
  const PublicHeaderWidget({Key? key}) : super(key: key);

  @override
  State<PublicHeaderWidget> createState() => _PublicHeaderWidgetState();
}

class _PublicHeaderWidgetState extends State<PublicHeaderWidget> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
        child: Row(
          children: [
            // 🏷️ Logo ve isim
            _buildLogo(),
            
            const Spacer(),
            
            // 🖥️ Desktop menü
            if (!isMobile) _buildDesktopMenu(),
            
            // 📱 Mobile menü butonu
            if (isMobile) _buildMobileMenuButton(),
          ],
        ),
      ),
    );
  }

  /// 🏷️ Logo
  Widget _buildLogo() {
    return GestureDetector(
      onTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/public/home',
        (route) => false,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_repair_service,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Locapo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Hizmet Platformu',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🖥️ Desktop Menü
  Widget _buildDesktopMenu() {
    final menuItems = [
      {'title': 'Ana Sayfa', 'route': '/public/home'},
      {'title': 'Hizmetler', 'route': '/public/services'},
      {'title': 'Hakkımızda', 'route': '/public/about'},
      {'title': 'Blog', 'route': '/public/blog'},
      {'title': 'İletişim', 'route': '/public/contact'},
    ];

    return Row(
      children: [
        ...menuItems.map((item) => _buildMenuItem(
          item['title']!,
          item['route']!,
        )),
        
        const SizedBox(width: 24),
        
        // 🔘 CTA Butonları
        _buildActionButtons(false),
      ],
    );
  }

  /// 📱 Mobile Menü Butonu
  Widget _buildMobileMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.menu,
        color: AppConstants.primaryColor,
      ),
      onSelected: (value) {
        if (value.startsWith('/')) {
          Navigator.pushNamed(context, value);
        } else {
          _handleAction(value);
        }
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem('Ana Sayfa', '/public/home', Icons.home),
        _buildPopupMenuItem('Hizmetler', '/public/services', Icons.design_services),
        _buildPopupMenuItem('Hakkımızda', '/public/about', Icons.info),
        _buildPopupMenuItem('Blog', '/public/blog', Icons.article),
        _buildPopupMenuItem('İletişim', '/public/contact', Icons.contact_mail),
        const PopupMenuDivider(),
        _buildPopupMenuItem('Giriş Yap', 'login', Icons.login),
        _buildPopupMenuItem('Kayıt Ol', 'register', Icons.person_add),
        _buildPopupMenuItem('İşletme Girişi', 'business_login', Icons.business),
      ],
    );
  }

  /// 📋 Menü öğesi
  Widget _buildMenuItem(String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 🔘 Aksiyon butonları
  Widget _buildActionButtons(bool isMobile) {
    if (isMobile) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        TextButton(
          onPressed: () => _handleAction('login'),
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
          ),
          child: const Text('Giriş Yap'),
        ),
        
        const SizedBox(width: 8),
        
        ElevatedButton(
          onPressed: () => _handleAction('register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Kayıt Ol'),
        ),
        
        const SizedBox(width: 8),
        
        OutlinedButton(
          onPressed: () => _handleAction('business_login'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            side: BorderSide(color: AppConstants.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('İşletme Girişi'),
        ),
      ],
    );
  }

  /// 📋 Popup menü öğesi
  PopupMenuItem<String> _buildPopupMenuItem(
    String title,
    String value,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }

  /// 🎯 Aksiyon işleme
  void _handleAction(String action) {
    switch (action) {
      case 'login':
        Navigator.pushNamed(context, '/login');
        break;
      case 'register':
        Navigator.pushNamed(context, '/register');
        break;
      case 'business_login':
        // İşletme girişi için özel flow
        _showBusinessLoginDialog();
        break;
    }
  }

  /// 🏢 İşletme giriş dialog'u
  void _showBusinessLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşletme Girişi'),
        content: const Text(
          'İşletme hesabınız var mı?\n\n'
          '• Zaten hesabınız varsa giriş yapın\n'
          '• Yeni işletme hesabı oluşturmak için kayıt olun',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/register');
            },
            child: const Text('Kayıt Ol'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }
}