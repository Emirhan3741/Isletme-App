import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/education_course_model.dart';

class EducationCoursesPage extends StatefulWidget {
  const EducationCoursesPage({super.key});

  @override
  State<EducationCoursesPage> createState() => _EducationCoursesPageState();
}

class _EducationCoursesPageState extends State<EducationCoursesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  String _selectedCategory = 'tümü';
  bool _isLoading = true;
  List<EducationCourse> _courses = [];
  List<EducationCourse> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationCoursesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _courses = snapshot.docs
            .map((doc) => EducationCourse.fromMap(doc.data(), doc.id))
            .toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Dersler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<EducationCourse> filtered = _courses;

    // Durum filtresi
    if (_selectedFilter != 'tümü') {
      filtered =
          filtered.where((course) => course.status == _selectedFilter).toList();
    }

    // Kategori filtresi
    if (_selectedCategory != 'tümü') {
      filtered = filtered
          .where((course) => course.kategori.toLowerCase() == _selectedCategory)
          .toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) {
        return course.dersAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            course.kategori
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            course.seviye.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            course.sinifDuzeyi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredCourses = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Dersler'),
        backgroundColor: const Color(0xFF764BA2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre Barı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Arama
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Ders ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Kategori Filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) {
                          setState(() => _selectedCategory = value ?? 'tümü');
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'tümü', child: Text('Tüm Kategoriler')),
                          DropdownMenuItem(
                              value: 'matematik', child: Text('Matematik')),
                          DropdownMenuItem(
                              value: 'ingilizce', child: Text('İngilizce')),
                          DropdownMenuItem(
                              value: 'türkçe', child: Text('Türkçe')),
                          DropdownMenuItem(value: 'fen', child: Text('Fen')),
                          DropdownMenuItem(
                              value: 'müzik', child: Text('Müzik')),
                          DropdownMenuItem(
                              value: 'resim', child: Text('Resim')),
                          DropdownMenuItem(value: 'spor', child: Text('Spor')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Durum Filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        onChanged: (value) {
                          setState(() => _selectedFilter = value ?? 'tümü');
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'tümü', child: Text('Tümü')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Aktif')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('Pasif')),
                          DropdownMenuItem(
                              value: 'suspended', child: Text('Askıda')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Yeni Ders Butonu
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/education-add-course');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Ders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF764BA2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // İstatistikler
                Row(
                  children: [
                    _buildStatCard(
                        'Toplam', _courses.length, const Color(0xFF764BA2)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Aktif',
                        _courses.where((c) => c.status == 'active').length,
                        AppConstants.successColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Grup',
                        _courses.where((c) => c.grupDersi).length,
                        AppConstants.infoColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Özel',
                        _courses.where((c) => !c.grupDersi).length,
                        AppConstants.warningColor),
                  ],
                ),
              ],
            ),
          ),

          // İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF764BA2),
                    ),
                  )
                : _filteredCourses.isEmpty
                    ? _buildEmptyState()
                    : _buildCoursesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF764BA2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.book,
              size: 64,
              color: Color(0xFF764BA2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedFilter != 'tümü' ||
                    _selectedCategory != 'tümü'
                ? 'Filtreye uygun ders bulunamadı'
                : 'Henüz ders yok',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedFilter != 'tümü' ||
                    _selectedCategory != 'tümü'
                ? 'Farklı arama kriteri deneyin'
                : 'İlk dersinizi ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigator.pushNamed(context, '/education-add-course');
            },
            icon: const Icon(Icons.add),
            label: const Text('İlk Dersi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF764BA2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF764BA2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  course.kategoriEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    course.dersAdi,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: course.isActive
                        ? AppConstants.successColor.withValues(alpha: 0.1)
                        : AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${course.statusEmoji} ${course.statusAciklama}',
                    style: TextStyle(
                      fontSize: 12,
                      color: course.isActive
                          ? AppConstants.successColor
                          : AppConstants.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.categoryDisplayName),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.seviye),
                    const SizedBox(width: 16),
                    Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.sinifDuzeyi),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.formatliSure),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.formatliUcret),
                    const SizedBox(width: 16),
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(course.dersTipi),
                  ],
                ),
                if (course.aciklama.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    course.aciklama,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // Navigator.pushNamed(context, '/education-edit-course', arguments: course);
                    break;
                  case 'delete':
                    // _deleteCourse(course);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      const SizedBox(width: 8),
                      Text('Düzenle'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          size: 16, color: AppConstants.errorColor),
                      const SizedBox(width: 8),
                      Text('Sil',
                          style: TextStyle(color: AppConstants.errorColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
