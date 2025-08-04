import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 📰 Blog Önizleme Widget
/// Ana sayfada blog yazılarının önizlemesini gösterir
class BlogPreviewWidget extends StatelessWidget {
  final List<Map<String, dynamic>> posts;

  const BlogPreviewWidget({
    Key? key,
    required this.posts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 60,
      ),
      color: Colors.grey.shade50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 📋 Bölüm başlığı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blog & İpuçları',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uzmanlarımızdan faydalı ipuçları ve güncel yazılar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/public/blog'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Tüm Yazılar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 📰 Blog kartları
              isMobile 
                  ? _buildMobileBlogCards()
                  : _buildDesktopBlogCards(),
              
              const SizedBox(height: 24),
              
              // 📱 Mobile "Tüm Yazılar" butonu
              if (isMobile)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/public/blog'),
                    icon: const Icon(Icons.article),
                    label: const Text('Tüm Blog Yazılarını Görüntüle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🖥️ Desktop Blog Kartları
  Widget _buildDesktopBlogCards() {
    return Row(
      children: posts.take(3).map((post) {
        final index = posts.indexOf(post);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < posts.length - 1 ? 24 : 0,
            ),
            child: _buildBlogCard(post, false),
          ),
        );
      }).toList(),
    );
  }

  /// 📱 Mobile Blog Kartları
  Widget _buildMobileBlogCards() {
    return Column(
      children: posts.take(3).map((post) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildBlogCard(post, true),
        );
      }).toList(),
    );
  }

  /// 📰 Blog kartı
  Widget _buildBlogCard(Map<String, dynamic> post, bool isMobile) {
    return GestureDetector(
      onTap: () => _onBlogTap(post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Görsel
            _buildBlogImage(post['image'] as String),
            
            // 📝 İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📅 Tarih ve okuma süresi
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post['date'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post['readTime'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 📍 Başlık
                  Text(
                    post['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 📄 Özet
                  Text(
                    post['excerpt'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 🔗 Okuma linki
                  Row(
                    children: [
                      Text(
                        'Devamını Oku',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppConstants.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🖼️ Blog görseli
  Widget _buildBlogImage(String imagePath) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: imagePath.startsWith('assets/') 
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  /// 🖼️ Placeholder görsel
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article,
          size: 48,
          color: AppConstants.primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  /// 📰 Blog tıklama
  void _onBlogTap(Map<String, dynamic> post) {
    // Blog detay sayfasına yönlendir
    // Navigator.pushNamed(
    //   context,
    //   '/public/blog/${post['slug']}',
    //   arguments: post,
    // );
    
    // Şimdilik placeholder
    debugPrint('Blog tıklandı: ${post['title']}');
  }
}