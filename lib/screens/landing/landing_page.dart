import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  void _showSectorInfo(BuildContext context, String sectorName, String route) {
    // Sektör isimlerini sektör kodlarına çevir
    String sectorCode = _getSectorCode(sectorName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.visibility,
              color: AppConstants.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sectorName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu sektör panelini demo modda görüntüleyebilir veya giriş yaparak tam özelliklerden yararlanabilirsiniz.',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                  color: AppConstants.successColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo modda tüm panel özelliklerini test edebilirsiniz!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register',
                  arguments: {'sector': sectorCode});
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: BorderSide(color: AppConstants.primaryColor),
            ),
            child: const Text('Kayıt Ol'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Demo Görüntüle'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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

  String _getSectorCode(String sectorName) {
    switch (sectorName) {
      case 'Güzellik Salonu & Kuaför':
        return 'güzellik_salon';
      case 'Avukat & Hukuk Büroları':
        return 'avukat';
      case 'Psikoloji & Danışmanlık':
        return 'psikoloji';
      case 'Spor & Antrenörlük':
        return 'fitness';
      case 'Sağlık & Klinik':
        return 'sağlık';
      case 'Veteriner Kliniği':
        return 'veteriner';
      case 'Emlak Ofisi':
        return 'emlak';
      case 'Eğitim & Kurs':
        return 'eğitim';
      default:
        return 'güzellik_salon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Navigation Bar
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppConstants.appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/login'),
                                child: const Text(
                                  'Giriş Yap',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/register'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppConstants.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadiusLarge),
                                  ),
                                  elevation: AppConstants.elevationMedium,
                                ),
                                child: const Text(
                                  'Kayıt Ol',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hero Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'İşletmeniz İçin Akıllı Yönetim',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Randevularınızı, müşterilerinizi ve finansınızı tek platformda yönetin.\nModern, güvenli ve kullanıcı dostu arayüz.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 18,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // CTA Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppConstants.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.borderRadiusXLarge),
                                    ),
                                    elevation: AppConstants.elevationLarge,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.rocket_launch),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ücretsiz Başla',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Colors.white, width: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.borderRadiusXLarge),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.login),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Giriş Yap',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sectors Section
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 80,
                horizontal: AppConstants.paddingXLarge,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    'Hangi Sektörlerle Çalışıyoruz?',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Farklı sektörlere özel çözümlerle iş süreçlerinizi optimize edin',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Sector Cards
                  Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    children: [
                      _SectorCard(
                        icon: Icons.cut,
                        title: 'Güzellik Salonu & Kuaför',
                        description:
                            'Randevu yönetimi, müşteri takibi, servis tanımları',
                        color: Colors.pink,
                        onTap: () => _showSectorInfo(context,
                            'Güzellik Salonu & Kuaför', '/beauty-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.scale,
                        title: 'Avukat & Hukuk Büroları',
                        description:
                            'Müvekkil takibi, dava yönetimi, duruşma takvimi',
                        color: Colors.blue,
                        onTap: () => _showSectorInfo(context,
                            'Avukat & Hukuk Büroları', '/lawyer-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.psychology,
                        title: 'Psikoloji & Danışmanlık',
                        description:
                            'Danışan takibi, seans yönetimi, terapi planlaması',
                        color: Colors.purple,
                        onTap: () => _showSectorInfo(context,
                            'Psikoloji & Danışmanlık', '/psychology-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.fitness_center,
                        title: 'Spor & Antrenörlük',
                        description:
                            'Üye yönetimi, antrenman programları, ödeme takibi',
                        color: Colors.orange,
                        onTap: () => _showSectorInfo(
                            context, 'Spor & Antrenörlük', '/sports-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.medical_services,
                        title: 'Sağlık & Klinik',
                        description:
                            'Hasta yönetimi, muayene randevuları, tedavi takibi',
                        color: Colors.green,
                        onTap: () => _showSectorInfo(
                            context, 'Sağlık & Klinik', '/clinic-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.pets,
                        title: 'Veteriner Kliniği',
                        description:
                            'Hayvan hasta takibi, aşı yönetimi, sahip iletişimi',
                        color: Colors.teal.shade700,
                        onTap: () => _showSectorInfo(context,
                            'Veteriner Kliniği', '/veterinary-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.business,
                        title: 'Emlak Ofisi',
                        description:
                            'İlan yönetimi, müşteri takibi, gösterim randevuları, sözleşmeler',
                        color: Colors.orange.shade700,
                        onTap: () => _showSectorInfo(
                            context, 'Emlak Ofisi', '/real-estate-dashboard'),
                      ),
                      _SectorCard(
                        icon: Icons.school,
                        title: 'Eğitim & Kurs',
                        description:
                            'Öğrenci takibi, ders programları, ödeme yönetimi',
                        color: Colors.teal,
                        onTap: () => _showSectorInfo(
                            context, 'Eğitim & Kurs', '/education-dashboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Features Section
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 80,
                horizontal: AppConstants.paddingXLarge,
              ),
              color: AppConstants.backgroundColor,
              child: Column(
                children: [
                  Text(
                    'Neden Randevu ERP?',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Feature Cards
                  Wrap(
                    spacing: 40,
                    runSpacing: 40,
                    children: [
                      _FeatureCard(
                        icon: Icons.calendar_today,
                        title: 'Akıllı Randevu Yönetimi',
                        description:
                            'Randevularınızı kolayca planlayın, müşterilerinize otomatik hatırlatmalar gönderin.',
                        color: AppConstants.primaryColor,
                      ),
                      _FeatureCard(
                        icon: Icons.people,
                        title: 'Müşteri Yönetimi',
                        description:
                            'Müşteri bilgilerini güvenle saklayın, geçmiş randevuları takip edin.',
                        color: AppConstants.successColor,
                      ),
                      _FeatureCard(
                        icon: Icons.analytics,
                        title: 'Finansal Raporlar',
                        description:
                            'Gelir-gider analizleri, detaylı raporlar ve iş zekası araçları.',
                        color: AppConstants.secondaryColor,
                      ),
                      _FeatureCard(
                        icon: Icons.security,
                        title: 'Güvenli & Bulut Tabanlı',
                        description:
                            'Verileriniz güvenli bulut altyapısında, her yerden erişim.',
                        color: AppConstants.warningColor,
                      ),
                      _FeatureCard(
                        icon: Icons.mobile_friendly,
                        title: 'Çoklu Platform',
                        description:
                            'Web, mobil ve desktop uygulamaları ile her cihazdan erişim.',
                        color: AppConstants.primaryColor,
                      ),
                      _FeatureCard(
                        icon: Icons.support_agent,
                        title: '7/24 Destek',
                        description:
                            'Uzman ekibimiz her zaman yanınızda, hızlı çözüm garantisi.',
                        color: AppConstants.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingXLarge),
              color: AppConstants.textPrimary,
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '© 2024 ${AppConstants.appName}. Tüm hakları saklıdır.',
                    style: TextStyle(
                      color: AppConstants.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SectorCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      child: Card(
        elevation: AppConstants.elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Keşfet',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(AppConstants.paddingXLarge),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMedium),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
