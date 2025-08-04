import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 💬 Müşteri Yorumları Widget
/// Carousel şeklinde müşteri yorumlarını gösterir
class TestimonialsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> testimonials;

  const TestimonialsWidget({
    Key? key,
    required this.testimonials,
  }) : super(key: key);

  @override
  State<TestimonialsWidget> createState() => _TestimonialsWidgetState();
}

class _TestimonialsWidgetState extends State<TestimonialsWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 🔄 Otomatik kaydırma
  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && widget.testimonials.isNotEmpty) {
        final nextIndex = (_currentIndex + 1) % widget.testimonials.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoSlide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (widget.testimonials.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 60,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 📋 Bölüm başlığı
              Text(
                'Müşterilerimiz Ne Diyor?',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Binlerce mutlu müşterimizin deneyimlerini keşfedin',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // 💬 Testimonial Carousel
              SizedBox(
                height: isMobile ? 300 : 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.testimonials.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final testimonial = widget.testimonials[index];
                    return _buildTestimonialCard(testimonial, isMobile);
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 🔵 Sayfa göstergeleri
              _buildPageIndicators(),
              
              const SizedBox(height: 24),
              
              // ⬅️➡️ Manuel kontroller
              if (!isMobile) _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 💭 Testimonial kartı
  Widget _buildTestimonialCard(Map<String, dynamic> testimonial, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: isMobile 
          ? _buildMobileTestimonial(testimonial)
          : _buildDesktopTestimonial(testimonial),
    );
  }

  /// 🖥️ Desktop testimonial layout
  Widget _buildDesktopTestimonial(Map<String, dynamic> testimonial) {
    return Row(
      children: [
        // Sol taraf - Avatar ve bilgiler
        Container(
          width: 120,
          child: Column(
            children: [
              _buildAvatar(testimonial['avatar'] as String),
              const SizedBox(height: 12),
              Text(
                testimonial['name'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                testimonial['city'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _buildStarRating(testimonial['rating'] as int),
            ],
          ),
        ),
        
        const SizedBox(width: 32),
        
        // Sağ taraf - Yorum
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote,
                size: 32,
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                testimonial['comment'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📱 Mobile testimonial layout
  Widget _buildMobileTestimonial(Map<String, dynamic> testimonial) {
    return Column(
      children: [
        // Üst kısım - Avatar ve yıldızlar
        Row(
          children: [
            _buildAvatar(testimonial['avatar'] as String),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testimonial['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    testimonial['city'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStarRating(testimonial['rating'] as int),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Alt kısım - Yorum
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.format_quote,
                size: 24,
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                testimonial['comment'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 👤 Avatar
  Widget _buildAvatar(String avatar) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.2),
            AppConstants.primaryColor.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          avatar,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  /// ⭐ Yıldız puanlama
  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  /// 🔵 Sayfa göstergeleri
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.testimonials.asMap().entries.map((entry) {
        final index = entry.key;
        final isActive = index == _currentIndex;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive 
                ? AppConstants.primaryColor 
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }

  /// ⬅️➡️ Navigasyon butonları
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _previousTestimonial,
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          onPressed: _nextTestimonial,
          icon: Icon(
            Icons.arrow_forward_ios,
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  /// ⬅️ Önceki testimonial
  void _previousTestimonial() {
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        _currentIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ➡️ Sonraki testimonial
  void _nextTestimonial() {
    if (_currentIndex < widget.testimonials.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}