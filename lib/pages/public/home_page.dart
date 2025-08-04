import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/public/hero_section_widget.dart';
import '../../widgets/public/search_form_widget.dart';
import '../../widgets/public/advantages_section_widget.dart';
import '../../widgets/public/how_it_works_widget.dart';
import '../../widgets/public/testimonials_widget.dart';
import '../../widgets/public/blog_preview_widget.dart';
import '../../widgets/public/public_footer_widget.dart';
import '../../widgets/public/public_header_widget.dart';

/// 🏠 Ana Sayfa - Landing Page
/// Hizmet platformunun ana tanıtım sayfası
class PublicHomePage extends StatefulWidget {
  const PublicHomePage({Key? key}) : super(key: key);

  @override
  State<PublicHomePage> createState() => _PublicHomePageState();
}

class _PublicHomePageState extends State<PublicHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 📱 Header
          const SliverToBoxAdapter(
            child: PublicHeaderWidget(),
          ),
          
          // 🎯 Hero Section
          SliverToBoxAdapter(
            child: HeroSectionWidget(
              title: 'En Yakın Hizmeti Bulun ve Anında Randevu Alın',
              subtitle: 'Güvenilir uzmanlardan hızlı ve kaliteli hizmet almanın en kolay yolu',
              onFindService: () => _scrollToSection('search'),
              onProvideService: () => Navigator.pushNamed(context, '/register'),
            ),
          ),
          
          // 🔍 Arama/Rezervasyon Formu
          const SliverToBoxAdapter(
            child: SearchFormWidget(),
          ),
          
          // ⭐ Avantajlar
          SliverToBoxAdapter(
            child: AdvantagesSectionWidget(
              advantages: [
                {
                  'icon': Icons.verified_user,
                  'title': 'Güvenilir Uzmanlar',
                  'description': 'Tüm hizmet verenlerimiz kimlik ve referans doğrulamasından geçer',
                },
                {
                  'icon': Icons.access_time,
                  'title': 'Hızlı Hizmet',
                  'description': '24 saat içinde size en yakın uzmanı bulur ve randevunuzu ayarlarız',
                },
                {
                  'icon': Icons.shield,
                  'title': 'Güvenli Ödeme',
                  'description': 'Ödemeleriniz güvenli altyapımız ile korunur ve garanti altındadır',
                },
                {
                  'icon': Icons.star,
                  'title': 'Kalite Garantisi',
                  'description': 'Hizmet kalitesinden memnun kalmazsa ücretinizi iade ediyoruz',
                },
              ],
            ),
          ),
          
          // 📋 Nasıl Çalışır
          SliverToBoxAdapter(
            child: HowItWorksWidget(
              steps: [
                {
                  'number': '1',
                  'title': 'Hizmet Seç',
                  'description': 'İhtiyacınız olan hizmeti seçin ve konumunuzu belirleyin',
                  'icon': Icons.search,
                },
                {
                  'number': '2',
                  'title': 'Teklif Al',
                  'description': 'Size yakın uzmanlardan fiyat teklifleri alın',
                  'icon': Icons.local_offer,
                },
                {
                  'number': '3',
                  'title': 'Randevu Ayarla',
                  'description': 'Beğendiğiniz uzmanla randevu ayarlayın',
                  'icon': Icons.calendar_today,
                },
                {
                  'number': '4',
                  'title': 'Öde ve Değerlendir',
                  'description': 'Hizmeti alın, güvenli ödeme yapın ve değerlendirin',
                  'icon': Icons.payment,
                },
              ],
            ),
          ),
          
          // 💬 Müşteri Yorumları
          SliverToBoxAdapter(
            child: TestimonialsWidget(
              testimonials: [
                {
                  'name': 'Ayşe Yılmaz',
                  'city': 'İstanbul',
                  'comment': 'Ev temizliği için bulduğum uzman gerçekten profesyoneldi. Kesinlikle tavsiye ederim!',
                  'rating': 5,
                  'avatar': '👩‍💼',
                },
                {
                  'name': 'Mehmet Kaya',
                  'city': 'Ankara',
                  'comment': 'Klima tamiri için hızlıca uzman buldum. Fiyat da çok uygundu.',
                  'rating': 5,
                  'avatar': '👨‍🔧',
                },
                {
                  'name': 'Fatma Demir',
                  'city': 'İzmir',
                  'comment': 'Nakliye hizmeti için kullandım. Eşyalarım güvenli şekilde taşındı.',
                  'rating': 4,
                  'avatar': '👩‍💻',
                },
              ],
            ),
          ),
          
          // 📰 Blog Önizleme
          SliverToBoxAdapter(
            child: BlogPreviewWidget(
              posts: [
                {
                  'title': 'Ev Temizliği İçin 10 Altın Kural',
                  'excerpt': 'Evinizi temiz tutmak için bilmeniz gereken temel kurallar...',
                  'image': 'assets/images/blog1.jpg',
                  'date': '15 Aralık 2024',
                  'readTime': '5 dk',
                },
                {
                  'title': 'Güvenilir Tamirci Nasıl Bulunur?',
                  'excerpt': 'Evinizdeki arızalar için doğru tamirciyi seçmenin yolları...',
                  'image': 'assets/images/blog2.jpg',
                  'date': '10 Aralık 2024',
                  'readTime': '7 dk',
                },
                {
                  'title': 'Taşınma Öncesi Yapılması Gerekenler',
                  'excerpt': 'Sorunsuz bir taşınma için hazırlık listesi...',
                  'image': 'assets/images/blog3.jpg',
                  'date': '5 Aralık 2024',
                  'readTime': '4 dk',
                },
              ],
            ),
          ),
          
          // 📞 Footer
          const SliverToBoxAdapter(
            child: PublicFooterWidget(),
          ),
        ],
      ),
      
      // 💬 Floating Action Button (İletişim)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/public/contact'),
        icon: const Icon(Icons.support_agent),
        label: const Text('Yardım'),
      ),
    );
  }

  /// 📍 Belirli bölüme scroll
  void _scrollToSection(String section) {
    // Basit scroll implementasyonu
    // Gerçek uygulamada section'ları track edebilirsiniz
    _scrollController.animateTo(
      800, // Yaklaşık search form pozisyonu
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }
}