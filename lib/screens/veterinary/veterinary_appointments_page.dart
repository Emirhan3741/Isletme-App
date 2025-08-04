import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class VeterinaryAppointmentsPage extends StatefulWidget {
  const VeterinaryAppointmentsPage({super.key});

  @override
  State<VeterinaryAppointmentsPage> createState() =>
      _VeterinaryAppointmentsPageState();
}

class _VeterinaryAppointmentsPageState
    extends State<VeterinaryAppointmentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Demo verisi göster
        setState(() {
          _appointments = _generateDemoAppointments();
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.veterinaryAppointmentsCollection)
          .where('kullaniciId', isEqualTo: user.uid)
          .orderBy('randevuTarihi', descending: false)
          .get();

      setState(() {
        _appointments =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Randevular yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDemoAppointments() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'hastaAdi': 'Pamuk',
        'sahipAdi': 'Ayşe Yılmaz',
        'randevuTarihi': now.add(const Duration(hours: 2)),
        'randevuSaati': '14:30',
        'islemTipi': 'Muayene',
        'durum': 'onaylandı',
        'notlar': 'Düzenli kontrol',
        'veterinerAdi': 'Dr. Mehmet Öz',
      },
      {
        'id': '2',
        'hastaAdi': 'Rex',
        'sahipAdi': 'Mehmet Demir',
        'randevuTarihi': now.add(const Duration(days: 1)),
        'randevuSaati': '10:00',
        'islemTipi': 'Aşı',
        'durum': 'beklemede',
        'notlar': 'Karma aşı',
        'veterinerAdi': 'Dr. Ayşe Kaya',
      },
      {
        'id': '3',
        'hastaAdi': 'Cıvıl',
        'sahipAdi': 'Zeynep Kaya',
        'randevuTarihi': now.add(const Duration(days: 3)),
        'randevuSaati': '16:15',
        'islemTipi': 'Kontrol',
        'durum': 'onaylandı',
        'notlar': 'Gagası kontrol edilecek',
        'veterinerAdi': 'Dr. Ali Vural',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Arama ve Filtre Barı
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Hasta veya sahip ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Randevu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
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
          ),

          // İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : _appointments.isEmpty
                    ? _buildEmptyState()
                    : _buildAppointmentsList(),
          ),
        ],
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
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz randevu yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk randevuyu ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAppointmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Randevuyu Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
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

  Widget _buildAppointmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['durum'])
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(appointment['durum']),
                      color: _getStatusColor(appointment['durum']),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appointment['hastaAdi']} - ${appointment['islemTipi']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          appointment['sahipAdi'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['durum'])
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(appointment['durum']),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(appointment['durum']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(appointment['randevuTarihi'])} - ${appointment['randevuSaati']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    appointment['veterinerAdi'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              if (appointment['notlar'] != null &&
                  appointment['notlar'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment['notlar'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'onaylandı':
        return const Color(0xFF10B981);
      case 'beklemede':
        return const Color(0xFFF59E0B);
      case 'iptal':
        return const Color(0xFFEF4444);
      case 'tamamlandı':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'onaylandı':
        return Icons.check_circle;
      case 'beklemede':
        return Icons.schedule;
      case 'iptal':
        return Icons.cancel;
      case 'tamamlandı':
        return Icons.task_alt;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'onaylandı':
        return 'Onaylandı';
      case 'beklemede':
        return 'Beklemede';
      case 'iptal':
        return 'İptal';
      case 'tamamlandı':
        return 'Tamamlandı';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yeni Randevu Ekle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 64,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Randevu Formu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu özellik yakında eklenecek',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
