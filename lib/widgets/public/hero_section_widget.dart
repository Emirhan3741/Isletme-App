import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 🎯 Hero Section Widget
/// Ana sayfanın en üst bölümü - ana başlık ve CTA butonları
class HeroSectionWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onFindService;
  final VoidCallback? onProvideService;

  const HeroSectionWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    this.onFindService,
    this.onProvideService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
            Colors.indigo.shade600,
          ],
        ),
      ),
      child: Column(
        children: [
          // 📱 Ana İçerik
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
          ),
        ],
      ),
    );
  }

  /// 🖥️ Desktop Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sol taraf - Metin içeriği
        Expanded(
          flex: 6,
          child: _buildTextContent(context, false),
        ),
        
        const SizedBox(width: 60),
        
        // Sağ taraf - Görsel/İllüstrasyon
        Expanded(
          flex: 4,
          child: _buildHeroImage(),
        ),
      ],
    );
  }

  /// 📱 Mobile Layout
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildTextContent(context, true),
        const SizedBox(height: 40),
        _buildHeroImage(),
      ],
    );
  }

  /// 📝 Text İçeriği
  Widget _buildTextContent(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // 🏷️ Üst etiket
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🚀 Hızlı • Güvenilir • Kaliteli',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 📍 Ana başlık
        Text(
          title,
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 📄 Alt başlık
        Text(
          subtitle,
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 16 : 20,
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // 🔘 CTA Butonları
        isMobile ? _buildMobileButtons() : _buildDesktopButtons(),
        
        const SizedBox(height: 24),
        
        // 📊 İstatistikler
        _buildStats(isMobile),
      ],
    );
  }

  /// 🖥️ Desktop Butonları
  Widget _buildDesktopButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: onFindService,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.search, size: 20),
          label: const Text(
            'Hizmet Bul',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        OutlinedButton.icon(
          onPressed: onProvideService,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.work_outline, size: 20),
          label: const Text(
            'Hizmet Ver',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 📱 Mobile Butonları
  Widget _buildMobileButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onFindService,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.search, size: 20),
            label: const Text(
              'Hizmet Bul',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onProvideService,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.work_outline, size: 20),
            label: const Text(
              'Hizmet Ver',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📊 İstatistikler
  Widget _buildStats(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: isMobile
          ? Column(children: _buildStatItems())
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildStatItems(),
            ),
    );
  }

  /// 📈 İstatistik öğeleri
  List<Widget> _buildStatItems() {
    final stats = [
      {'number': '10K+', 'label': 'Mutlu Müşteri'},
      {'number': '2K+', 'label': 'Uzman Hizmet Veren'},
      {'number': '50+', 'label': 'Hizmet Kategorisi'},
      {'number': '25+', 'label': 'Şehir'},
    ];

    return stats.map((stat) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            stat['number']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            stat['label']!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    )).toList();
  }

  /// 🖼️ Hero Görseli
  Widget _buildHeroImage() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_repair_service,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  '🔧 Hizmet Platformu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}