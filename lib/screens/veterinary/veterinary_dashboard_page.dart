import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/veterinary_patient_model.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';
import 'veterinary_patients_page.dart';
import 'veterinary_appointments_page.dart';
import 'veterinary_treatments_page.dart';
import 'veterinary_vaccinations_page.dart';
import 'veterinary_calendar_page.dart';
import 'veterinary_payments_page.dart';
import 'veterinary_expenses_page.dart';
import 'veterinary_inventory_page.dart';
import 'veterinary_documents_page.dart';
import 'veterinary_notes_page.dart';
import 'veterinary_reports_page.dart';
import 'veterinary_settings_page.dart';

class VeterinaryDashboardPage extends StatefulWidget {
  const VeterinaryDashboardPage({super.key});

  @override
  State<VeterinaryDashboardPage> createState() =>
      _VeterinaryDashboardPageState();
}

class _VeterinaryDashboardPageState extends State<VeterinaryDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  // İstatistikler
  int _toplamHasta = 0;
  int _bugunRandevu = 0;
  int _bekleyenAsi = 0;
  int _aktifTedavi = 0;
  double _aylikGelir = 0.0;
  List<VeterinaryPatient> _sonHastalar = [];

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.dashboard,
      'color': const Color(0xFF059669),
    },
    {
      'title': 'Hastalar',
      'icon': Icons.pets,
      'color': const Color(0xFF059669),
    },
    {
      'title': 'Randevular',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Tedaviler',
      'icon': Icons.medical_services,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Aşılar',
      'icon': Icons.vaccines,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Takvim',
      'icon': Icons.event,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Ödemeler',
      'icon': Icons.payment,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Giderler',
      'icon': Icons.money_off,
      'color': const Color(0xFFEF4444),
    },
    {
      'title': 'Stok',
      'icon': Icons.inventory,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Belgeler',
      'icon': Icons.description,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Notlar',
      'icon': Icons.note,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Raporlar',
      'icon': Icons.assessment,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Ayarlar',
      'icon': Icons.settings,
      'color': const Color(0xFF6B7280),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Demo verisi göster
        setState(() {
          _toplamHasta = 127;
          _bugunRandevu = 8;
          _bekleyenAsi = 15;
          _aktifTedavi = 3;
          _aylikGelir = 45750.0;
          _isLoading = false;
        });
        return;
      }

      // Firebase'den istatistikleri yükle
      await Future.wait([
        _loadPatientStats(),
        _loadAppointmentStats(),
        _loadVaccinationStats(),
        _loadTreatmentStats(),
        _loadIncomeStats(),
        _loadRecentPatients(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Dashboard verisi yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPatientStats() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryPatientsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('aktif', isEqualTo: true)
        .get();
    _toplamHasta = snapshot.docs.length;
  }

  Future<void> _loadAppointmentStats() async {
    final user = FirebaseAuth.instance.currentUser!;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryAppointmentsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('randevuTarihi',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('randevuTarihi', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    _bugunRandevu = snapshot.docs.length;
  }

  Future<void> _loadVaccinationStats() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryVaccinationsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('durum', isEqualTo: 'planlandı')
        .get();
    _bekleyenAsi = snapshot.docs.length;
  }

  Future<void> _loadTreatmentStats() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryTreatmentsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('durum', isEqualTo: 'devam_ediyor')
        .get();
    _aktifTedavi = snapshot.docs.length;
  }

  Future<void> _loadIncomeStats() async {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryPaymentsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('odemeTarihi',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
        .get();

    _aylikGelir = snapshot.docs.fold(0.0, (sum, doc) {
      return sum + (doc.data()['tutar'] ?? 0.0).toDouble();
    });
  }

  Future<void> _loadRecentPatients() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.veterinaryPatientsCollection)
        .where('kullaniciId', isEqualTo: user.uid)
        .where('aktif', isEqualTo: true)
        .orderBy('kayitTarihi', descending: true)
        .limit(5)
        .get();

    _sonHastalar = snapshot.docs
        .map((doc) => VeterinaryPatient.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sol Menü
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Veteriner Kliniği',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Hasta Yönetimi',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
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

                // Menü Öğeleri
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? const Color(0xFF059669).withValues(alpha: 0.1)
                              : Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'],
                                    color: isSelected
                                        ? const Color(0xFF059669)
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF059669)
                                            : Colors.grey.shade700,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Çıkış Butonu
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.red.shade50,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/landing', (route) => false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Çıkış Yap',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ana İçerik
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const VeterinaryPatientsPage();
      case 2:
        return const VeterinaryAppointmentsPage();
      case 3:
        return const VeterinaryTreatmentsPage();
      case 4:
        return const VeterinaryVaccinationsPage();
      case 5:
        return const VeterinaryCalendarPage();
      case 6:
        return const VeterinaryPaymentsPage();
      case 7:
        return const VeterinaryExpensesPage();
      case 8:
        return const VeterinaryInventoryPage();
      case 9:
        return const VeterinaryDocumentsPage(customerId: '');
      case 10:
        return const VeterinaryNotesPage();
      case 11:
        return const VeterinaryReportsPage();
      case 12:
        return const VeterinarySettingsPage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF059669),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İstatistik Kartları
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Daha uygun oran
            children: [
              _buildStatCard(
                'Toplam Hasta',
                _toplamHasta.toString(),
                Icons.pets,
                const Color(0xFF059669),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                'Bugün Randevu',
                _bugunRandevu.toString(),
                Icons.calendar_today,
                const Color(0xFF3B82F6),
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _buildStatCard(
                'Bekleyen Aşı',
                _bekleyenAsi.toString(),
                Icons.vaccines,
                const Color(0xFFF59E0B),
                onTap: () => setState(() => _selectedIndex = 4),
              ),
              _buildStatCard(
                'Aktif Tedavi',
                _aktifTedavi.toString(),
                Icons.medical_services,
                const Color(0xFF8B5CF6),
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildStatCard(
                'Aylık Gelir',
                '₺${_aylikGelir.toStringAsFixed(0)}',
                Icons.attach_money,
                const Color(0xFF10B981),
                onTap: () => setState(() => _selectedIndex = 6),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Hızlı İşlemler ve Son Hastalar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hızlı İşlemler
              Expanded(
                flex: 2,
                child: _buildQuickActions(),
              ),
              const SizedBox(width: 24),
              // Son Hastalar
              Expanded(
                flex: 3,
                child: _buildRecentPatients(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // Padding azaltıldı
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Eşit dağılım
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Padding azaltıldı
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18, // Icon boyutu azaltıldı
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14, // Icon boyutu azaltıldı
                    color: Colors.grey[400],
                  ),
              ],
            ),
            const SizedBox(height: 8), // Spacing azaltıldı
            Text(
              value,
              style: const TextStyle(
                fontSize: 20, // Font boyutu azaltıldı
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12, // Font boyutu azaltıldı
                color: Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
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
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionItem(
            'Yeni Hasta Kayıt',
            Icons.add_circle_outline,
            const Color(0xFF059669),
            () => setState(() => _selectedIndex = 1),
          ),
          _buildQuickActionItem(
            'Randevu Ekle',
            Icons.event_note,
            const Color(0xFF3B82F6),
            () => setState(() => _selectedIndex = 2),
          ),
          _buildQuickActionItem(
            'Aşı Takvimi',
            Icons.vaccines,
            const Color(0xFFF59E0B),
            () => setState(() => _selectedIndex = 4),
          ),
          _buildQuickActionItem(
            'Stok Yönetimi',
            Icons.inventory,
            const Color(0xFF8B5CF6),
            () => setState(() => _selectedIndex = 8),
          ),
          _buildQuickActionItem(
            'Raporlar',
            Icons.assessment,
            const Color(0xFF10B981),
            () => setState(() => _selectedIndex = 11),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPatients() {
    return Container(
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
              const Text(
                'Son Kayıt Olan Hastalar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_sonHastalar.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz hasta kaydı yok',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_sonHastalar.map((hasta) => _buildPatientItem(hasta)).toList()),
        ],
      ),
    );
  }

  Widget _buildPatientItem(VeterinaryPatient hasta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AnimalTypes.getTurEmoji(hasta.hayvanTuru),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasta.hayvanAdi,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '${hasta.hayvanTuru} - ${hasta.sahipTamAdi}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              hasta.saglikDurumuEmoji,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }
}
