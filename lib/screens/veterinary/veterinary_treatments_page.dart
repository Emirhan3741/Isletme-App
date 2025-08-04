import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class VeterinaryTreatmentsPage extends StatefulWidget {
  const VeterinaryTreatmentsPage({super.key});

  @override
  State<VeterinaryTreatmentsPage> createState() =>
      _VeterinaryTreatmentsPageState();
}

class _VeterinaryTreatmentsPageState extends State<VeterinaryTreatmentsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _treatments = [];

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _treatments = _generateDemoTreatments();
          _isLoading = false;
        });
        return;
      }

      // Firebase'den tedavileri yükle
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.veterinaryTreatmentsCollection)
          .where('kullaniciId', isEqualTo: user.uid)
          .orderBy('tedaviTarihi', descending: true)
          .get();

      setState(() {
        _treatments =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Tedaviler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDemoTreatments() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'hastaAdi': 'Pamuk',
        'sahipAdi': 'Ayşe Yılmaz',
        'tedaviTarihi': now.subtract(const Duration(days: 2)),
        'tedaviTipi': 'Muayene',
        'sikayet': 'İştahsızlık ve halsizlik',
        'tani': 'Hafif soğuk algınlığı',
        'tedaviPlani': 'Antibiyotik tedavisi',
        'durum': 'tamamlandi',
        'veterinerAdi': 'Dr. Mehmet Öz',
        'tedaviUcreti': 250.0,
      },
      {
        'id': '2',
        'hastaAdi': 'Rex',
        'sahipAdi': 'Mehmet Demir',
        'tedaviTarihi': now.subtract(const Duration(days: 7)),
        'tedaviTipi': 'Ameliyat',
        'sikayet': 'Topallama',
        'tani': 'Kalça displazisi',
        'tedaviPlani': 'Cerrahi müdahale',
        'durum': 'devam_ediyor',
        'veterinerAdi': 'Dr. Ayşe Kaya',
        'tedaviUcreti': 1500.0,
      },
      {
        'id': '3',
        'hastaAdi': 'Cıvıl',
        'sahipAdi': 'Zeynep Kaya',
        'tedaviTarihi': now.subtract(const Duration(days: 1)),
        'tedaviTipi': 'Kontrol',
        'sikayet': 'Gaga problemi',
        'tani': 'Gaga aşırı uzama',
        'tedaviPlani': 'Gaga kesimi',
        'durum': 'tamamlandi',
        'veterinerAdi': 'Dr. Ali Vural',
        'tedaviUcreti': 100.0,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tedavi Kayıtları',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Hasta tedavi geçmişi ve aktif tedaviler',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTreatmentDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Tedavi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _treatments.isEmpty
                    ? _buildEmptyState()
                    : _buildTreatmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 64, color: Color(0xFF8B5CF6)),
          const SizedBox(height: 16),
          Text('Henüz tedavi kaydı yok'),
        ],
      ),
    );
  }

  Widget _buildTreatmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _treatments.length,
      itemBuilder: (context, index) {
        final treatment = _treatments[index];
        return _buildTreatmentCard(treatment);
      },
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> treatment) {
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
                  color: _getTreatmentColor(treatment['tedaviTipi'])
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTreatmentIcon(treatment['tedaviTipi']),
                  color: _getTreatmentColor(treatment['tedaviTipi']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${treatment['hastaAdi']} - ${treatment['tedaviTipi']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      treatment['sahipAdi'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₺${treatment['tedaviUcreti'].toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Şikayet ve Tanı
          _buildInfoRow('Şikayet', treatment['sikayet']),
          if (treatment['tani'] != null)
            _buildInfoRow('Tanı', treatment['tani']),
          if (treatment['tedaviPlani'] != null)
            _buildInfoRow('Tedavi Planı', treatment['tedaviPlani']),

          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(treatment['tedaviTarihi']),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                treatment['veterinerAdi'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(treatment['durum'])
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(treatment['durum']),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(treatment['durum']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTreatmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'muayene':
        return const Color(0xFF3B82F6);
      case 'ameliyat':
        return const Color(0xFFEF4444);
      case 'kontrol':
        return const Color(0xFF10B981);
      case 'aşı':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getTreatmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'muayene':
        return Icons.search;
      case 'ameliyat':
        return Icons.local_hospital;
      case 'kontrol':
        return Icons.assignment;
      case 'aşı':
        return Icons.vaccines;
      default:
        return Icons.medical_services;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'tamamlandi':
        return const Color(0xFF10B981);
      case 'devam_ediyor':
        return const Color(0xFF3B82F6);
      case 'iptal':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'tamamlandi':
        return 'Tamamlandı';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'iptal':
        return 'İptal';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddTreatmentDialog() {
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
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yeni Tedavi Ekle',
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
                      Icons.medical_services,
                      size: 64,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tedavi Formu',
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
}
