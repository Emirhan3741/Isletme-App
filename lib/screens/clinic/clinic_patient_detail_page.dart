import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicPatientDetailPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const ClinicPatientDetailPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ClinicPatientDetailPage> createState() =>
      _ClinicPatientDetailPageState();
}

class _ClinicPatientDetailPageState extends State<ClinicPatientDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _treatments = [];
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Hasta bilgilerini yükle
      final patientDoc = await FirebaseFirestore.instance
          .collection(AppConstants.clinicClientsCollection)
          .doc(widget.patientId)
          .get();

      if (patientDoc.exists) {
        _patientData = patientDoc.data();
      }

      // Tedavileri yükle
      final treatmentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicTreatmentsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('treatmentDate', descending: true)
          .get();

      _treatments = treatmentsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Randevuları yükle
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicAppointmentsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('appointmentDate', descending: true)
          .limit(10)
          .get();

      _appointments = appointmentsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Belgeleri yükle
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicDocumentsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('uploadDate', descending: true)
          .get();

      _documents = documentsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Hasta verileri yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Bilgiler'),
            Tab(icon: Icon(Icons.medical_services), text: 'Tedaviler'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Randevular'),
            Tab(icon: Icon(Icons.folder), text: 'Belgeler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPatientInfoTab(),
                _buildTreatmentsTab(),
                _buildAppointmentsTab(),
                _buildDocumentsTab(),
              ],
            ),
    );
  }

  Widget _buildPatientInfoTab() {
    if (_patientData == null) {
      return const Center(
        child: Text('Hasta bilgileri bulunamadı'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hasta Kartı
          Container(
            padding: const EdgeInsets.all(24),
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patientData!['name'] ?? 'İsimsiz',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hasta ID: ${widget.patientId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Kişisel Bilgiler
                _buildInfoSection('Kişisel Bilgiler', [
                  _buildInfoRow(
                      'Telefon', _patientData!['phone'] ?? 'Belirtilmemiş'),
                  _buildInfoRow(
                      'E-posta', _patientData!['email'] ?? 'Belirtilmemiş'),
                  _buildInfoRow('Yaş',
                      _patientData!['age']?.toString() ?? 'Belirtilmemiş'),
                  _buildInfoRow(
                      'Cinsiyet', _patientData!['gender'] ?? 'Belirtilmemiş'),
                ]),

                const SizedBox(height: 24),

                // Tıbbi Bilgiler
                _buildInfoSection('Tıbbi Bilgiler', [
                  _buildInfoRow('Kan Grubu',
                      _patientData!['bloodType'] ?? 'Belirtilmemiş'),
                  _buildInfoRow(
                      'Alerjiler', _patientData!['allergies'] ?? 'Yok'),
                  _buildInfoRow('Kronik Hastalıklar',
                      _patientData!['chronicDiseases'] ?? 'Yok'),
                  _buildInfoRow('Kullanılan İlaçlar',
                      _patientData!['medications'] ?? 'Yok'),
                ]),

                if (_patientData!['notes'] != null &&
                    _patientData!['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoSection('Notlar', [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _patientData!['notes'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsTab() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tedavi Geçmişi (${_treatments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Yeni tedavi ekle
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Tedavi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Tedavi Listesi
        Expanded(
          child: _treatments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz tedavi kaydı yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _treatments.length,
                  itemBuilder: (context, index) {
                    final treatment = _treatments[index];
                    final date =
                        (treatment['treatmentDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.medical_services,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  treatment['treatmentName'] ??
                                      'İsimsiz Tedavi',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (treatment['description'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              treatment['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          if (treatment['medications'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.medication,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'İlaç: ${treatment['medications']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Son Randevular (${_appointments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Yeni randevu ekle
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Randevu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Randevu Listesi
        Expanded(
          child: _appointments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz randevu kaydı yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final date =
                        (appointment['appointmentDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getAppointmentStatusColor(
                                      appointment['status'])
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getAppointmentStatusIcon(appointment['status']),
                              size: 20,
                              color: _getAppointmentStatusColor(
                                  appointment['status']),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment['appointmentType'] ??
                                      'Genel Muayene',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAppointmentStatusColor(
                                  appointment['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getAppointmentStatusText(appointment['status']),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Belgeler (${_documents.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Yeni belge ekle
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Belge Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Belge Listesi
        Expanded(
          child: _documents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz belge yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final document = _documents[index];
                    final date = (document['uploadDate'] as Timestamp).toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.description,
                              size: 20,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document['fileName'] ?? 'İsimsiz Belge',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Belgeyi aç/indir
                            },
                            icon: const Icon(
                              Icons.download,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getAppointmentStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getAppointmentStatusIcon(String? status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getAppointmentStatusText(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Onaylandı';
      case 'pending':
        return 'Bekliyor';
      case 'cancelled':
        return 'İptal';
      default:
        return 'Bilinmeyen';
    }
  }
}
