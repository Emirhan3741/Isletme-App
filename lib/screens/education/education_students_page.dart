import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/education_student_model.dart';
import 'add_edit_student_page.dart';

class EducationStudentsPage extends StatefulWidget {
  const EducationStudentsPage({super.key});

  @override
  State<EducationStudentsPage> createState() => _EducationStudentsPageState();
}

class _EducationStudentsPageState extends State<EducationStudentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  bool _isLoading = true;
  List<EducationStudent> _students = [];
  List<EducationStudent> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationStudentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _students = snapshot.docs
            .map((doc) => EducationStudent.fromMap(doc.data(), doc.id))
            .toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Öğrenciler yüklenirken hata: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öğrenciler yüklenirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<EducationStudent> filtered = _students;

    // Durum filtresi
    if (_selectedFilter != 'tümü') {
      filtered = filtered
          .where((student) => student.status == _selectedFilter)
          .toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        return student.tamIsim
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            student.telefon.contains(_searchQuery) ||
            student.sinif.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            student.seviye.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredStudents = filtered;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _onFilterChanged(String? value) {
    setState(() {
      _selectedFilter = value ?? 'tümü';
    });
    _applyFilters();
  }

  Future<void> _deleteStudent(EducationStudent student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text(
            '${student.tamIsim} adlı öğrenciyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.educationStudentsCollection)
            .doc(student.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Öğrenci başarıyla silindi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }

        _loadStudents();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Öğrenci silinirken hata: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddEdit([EducationStudent? student]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStudentPage(student: student),
      ),
    );

    if (result == true) {
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Öğrenciler'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre Barı
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Öğrenci ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Filtre
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        onChanged: _onFilterChanged,
                        decoration: InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'tümü', child: Text('Tümü')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Aktif')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('Pasif')),
                          DropdownMenuItem(
                              value: 'graduated', child: Text('Mezun')),
                          DropdownMenuItem(
                              value: 'dropped', child: Text('Ayrıldı')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Yeni Öğrenci Butonu
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddEdit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Öğrenci'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
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
                        'Toplam', _students.length, const Color(0xFF667EEA)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Aktif',
                        _students.where((s) => s.status == 'active').length,
                        AppConstants.successColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'VIP',
                        _students.where((s) => s.vipOgrenci).length,
                        AppConstants.warningColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Burslu',
                        _students.where((s) => s.bursluOgrenci).length,
                        AppConstants.infoColor),
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
                      color: Color(0xFF667EEA),
                    ),
                  )
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsList(),
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
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people,
              size: 64,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'tümü'
                ? 'Filtreye uygun öğrenci bulunamadı'
                : 'Henüz öğrenci yok',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'tümü'
                ? 'Farklı arama kriteri deneyin'
                : 'İlk öğrencinizi ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddEdit(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Öğrenciyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
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

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
              backgroundImage: student.fotoUrl != null
                  ? NetworkImage(student.fotoUrl!)
                  : null,
              child: student.fotoUrl == null
                  ? Text(
                      student.ad.isNotEmpty ? student.ad[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    student.tamIsim,
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
                    color: student.isActive
                        ? AppConstants.successColor.withValues(alpha: 0.1)
                        : AppConstants.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${student.statusEmoji} ${student.statusAciklama}',
                    style: TextStyle(
                      fontSize: 12,
                      color: student.isActive
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
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(student.telefon),
                    const SizedBox(width: 16),
                    Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(student.sinif),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(student.seviye),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${student.yas} yaş'),
                    const SizedBox(width: 16),
                    Icon(Icons.label, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(student.ogrenciTipi),
                    if (student.kayitliDersler.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.book, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${student.kayitliDersler.length} ders'),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _navigateToAddEdit(student);
                    break;
                  case 'delete':
                    _deleteStudent(student);
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
