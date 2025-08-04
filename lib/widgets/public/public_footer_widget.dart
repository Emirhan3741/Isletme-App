import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 📞 Public Footer Widget
/// Marketing sayfalarının alt kısmı
class PublicFooterWidget extends StatelessWidget {
  const PublicFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      color: Colors.grey.shade900,
      child: Column(
        children: [
          // 📧 Newsletter bölümü
          _buildNewsletterSection(isMobile),
          
          // 📋 Ana footer içeriği
          _buildMainFooter(context, isMobile),
          
          // 📄 Alt kısım - copyright
          _buildBottomSection(),
        ],
      ),
    );
  }

  /// 📧 Newsletter bölümü
  Widget _buildNewsletterSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile 
              ? _buildMobileNewsletter()
              : _buildDesktopNewsletter(),
        ),
      ),
    );
  }

  /// 🖥️ Desktop Newsletter
  Widget _buildDesktopNewsletter() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Güncel Kalın!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yeni hizmetler ve özel fırsatlardan ilk siz haberdar olun',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 40),
        
        Expanded(
          flex: 2,
          child: _buildNewsletterForm(),
        ),
      ],
    );
  }

  /// 📱 Mobile Newsletter
  Widget _buildMobileNewsletter() {
    return Column(
      children: [
        const Text(
          'Güncel Kalın!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni hizmetler ve özel fırsatlardan ilk siz haberdar olun',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildNewsletterForm(),
      ],
    );
  }

  /// 📧 Newsletter formu
  Widget _buildNewsletterForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'E-posta adresinizi girin',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _onNewsletterSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Abone Ol',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// 📋 Ana footer
  Widget _buildMainFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile 
              ? _buildMobileFooter(context)
              : _buildDesktopFooter(context),
        ),
      ),
    );
  }

  /// 🖥️ Desktop Footer
  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol - Şirket bilgileri
        Expanded(
          flex: 2,
          child: _buildCompanyInfo(),
        ),
        
        // Orta - Hızlı linkler
        Expanded(
          child: _buildQuickLinks(context),
        ),
        
        // Sağ orta - Hizmetler
        Expanded(
          child: _buildServicesLinks(context),
        ),
        
        // Sağ - İletişim
        Expanded(
          child: _buildContactInfo(),
        ),
      ],
    );
  }

  /// 📱 Mobile Footer
  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      children: [
        _buildCompanyInfo(),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildQuickLinks(context)),
            const SizedBox(width: 24),
            Expanded(child: _buildServicesLinks(context)),
          ],
        ),
        const SizedBox(height: 32),
        _buildContactInfo(),
      ],
    );
  }

  /// 🏢 Şirket bilgileri
  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(
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
            const Text(
              'Locapo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Türkiye\'nin en güvenilir hizmet platformu. '
          'Size en yakın uzmanları bulun, randevu alın ve kaliteli hizmet deneyimi yaşayın.',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Sosyal medya
        Row(
          children: [
            _buildSocialButton(Icons.facebook, 'Facebook'),
            const SizedBox(width: 12),
            _buildSocialButton(Icons.language, 'Twitter'),
            const SizedBox(width: 12),
            _buildSocialButton(Icons.camera_alt, 'Instagram'),
            const SizedBox(width: 12),
            _buildSocialButton(Icons.play_arrow, 'YouTube'),
          ],
        ),
      ],
    );
  }

  /// 🔗 Hızlı linkler
  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Linkler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink('Ana Sayfa', () => Navigator.pushNamed(context, '/public/home')),
        _buildFooterLink('Hakkımızda', () => Navigator.pushNamed(context, '/public/about')),
        _buildFooterLink('Nasıl Çalışır', () => Navigator.pushNamed(context, '/public/how-it-works')),
        _buildFooterLink('SSS', () => Navigator.pushNamed(context, '/public/faq')),
        _buildFooterLink('İletişim', () => Navigator.pushNamed(context, '/public/contact')),
      ],
    );
  }

  /// 🛠️ Hizmetler
  Widget _buildServicesLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hizmetler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink('Ev Temizliği', () {}),
        _buildFooterLink('Tamir/Onarım', () {}),
        _buildFooterLink('Taşıma/Nakliye', () {}),
        _buildFooterLink('Bahçe Bakımı', () {}),
        _buildFooterLink('Tüm Hizmetler', () => Navigator.pushNamed(context, '/public/services')),
      ],
    );
  }

  /// 📞 İletişim bilgileri
  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İletişim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildContactItem(Icons.phone, '+90 (212) 123 45 67'),
        _buildContactItem(Icons.email, 'info@locapo.com'),
        _buildContactItem(Icons.location_on, 'İstanbul, Türkiye'),
        _buildContactItem(Icons.access_time, '7/24 Müşteri Desteği'),
      ],
    );
  }

  /// 📱 Sosyal medya butonu
  Widget _buildSocialButton(IconData icon, String tooltip) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.grey.shade400),
        onPressed: () {}, // Sosyal medya linkini aç
        tooltip: tooltip,
      ),
    );
  }

  /// 🔗 Footer link
  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// 📞 İletişim öğesi
  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Alt bölüm
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2024 Locapo. Tüm hakları saklıdır.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  _buildBottomLink('Gizlilik Politikası'),
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  _buildBottomLink('Kullanım Şartları'),
                  const Text(' • ', style: TextStyle(color: Colors.grey)),
                  _buildBottomLink('Çerez Politikası'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔗 Alt link
  Widget _buildBottomLink(String text) {
    return GestureDetector(
      onTap: () {}, // Sayfa yönlendirmesi
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
    );
  }

  /// 📧 Newsletter form submit
  void _onNewsletterSubmit() {
    // Newsletter kaydı implementasyonu
    debugPrint('Newsletter kaydı');
  }
}