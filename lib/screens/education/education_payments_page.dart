import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/education_payment_model.dart';
import '../../core/models/education_student_model.dart';

class EducationPaymentsPage extends StatefulWidget {
  const EducationPaymentsPage({super.key});

  @override
  State<EducationPaymentsPage> createState() => _EducationPaymentsPageState();
}

class _EducationPaymentsPageState extends State<EducationPaymentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'tümü';
  String _selectedType = 'tümü';
  bool _isLoading = true;
  List<EducationPayment> _payments = [];
  List<EducationPayment> _filteredPayments = [];
  Map<String, EducationStudent> _studentsMap = {};

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Ödemeler yükle
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationPaymentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('odemeTarihi', descending: true)
          .get();

      // Öğrenciler yükle
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.educationStudentsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _payments = paymentsSnapshot.docs
            .map((doc) => EducationPayment.fromMap(doc.data(), doc.id))
            .toList();

        _studentsMap = Map.fromEntries(
          studentsSnapshot.docs.map((doc) {
            final student = EducationStudent.fromMap(doc.data(), doc.id);
            return MapEntry(student.id, student);
          }),
        );

        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Ödemeler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<EducationPayment> filtered = _payments;

    // Durum filtresi
    if (_selectedStatus != 'tümü') {
      filtered = filtered
          .where((payment) => payment.status == _selectedStatus)
          .toList();
    }

    // Tür filtresi
    if (_selectedType != 'tümü') {
      filtered = filtered
          .where((payment) => payment.odemeTuru == _selectedType)
          .toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final student = _studentsMap[payment.ogrenciId];
        return student?.tamIsim
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            payment.odemeTuruAciklama
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            payment.makbuzNo?.contains(_searchQuery) == true;
      }).toList();
    }

    setState(() {
      _filteredPayments = filtered;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _selectedStatus = value ?? 'tümü';
    });
    _applyFilters();
  }

  void _onTypeFilterChanged(String? value) {
    setState(() {
      _selectedType = value ?? 'tümü';
    });
    _applyFilters();
  }

  Future<void> _deletePayment(EducationPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödemeyi Sil'),
        content:
            const Text('Bu ödeme kaydını silmek istediğinizden emin misiniz?'),
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
            .collection(AppConstants.educationPaymentsCollection)
            .doc(payment.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ödeme kaydı başarıyla silindi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }

        _loadPayments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ödeme silinirken hata: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showPaymentDetails(EducationPayment payment) {
    final student = _studentsMap[payment.ogrenciId];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ödeme Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Öğrenci', student?.tamIsim ?? 'Bilinmeyen'),
              _buildDetailRow('Ödeme Türü', payment.odemeTuruAciklama),
              _buildDetailRow('Tutar', payment.formatliTutar),
              if (payment.indirimVar)
                _buildDetailRow('İndirim', payment.formatliIndirim),
              _buildDetailRow('Ödenecek Tutar', payment.formatliOdenecekTutar),
              _buildDetailRow('Ödeme Tipi', payment.odemeTipiAciklama),
              _buildDetailRow('Durum', payment.statusAciklama),
              _buildDetailRow('Tarih',
                  '${payment.odemeTarihi.day}/${payment.odemeTarihi.month}/${payment.odemeTarihi.year}'),
              if (payment.vadeseTarihi != null)
                _buildDetailRow('Vade Tarihi',
                    '${payment.vadeseTarihi!.day}/${payment.vadeseTarihi!.month}/${payment.vadeseTarihi!.year}'),
              if (payment.taksitliOdeme)
                _buildDetailRow('Taksit', payment.taksitBilgisi),
              if (payment.makbuzNo != null)
                _buildDetailRow('Makbuz No', payment.makbuzNo!),
              if (payment.aciklama != null)
                _buildDetailRow('Açıklama', payment.aciklama!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (payment.odendi)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _generateReceipt(payment);
              },
              child: const Text('Makbuz Yazdır'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _generateReceipt(EducationPayment payment) {
    // Makbuz yazdırma işlemi (placeholder)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Makbuz yazdırma özelliği yakında aktif olacak'),
        backgroundColor: AppConstants.infoColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Ödemeler'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPayments,
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
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Öğrenci veya ödeme ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Durum Filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        onChanged: _onStatusFilterChanged,
                        decoration: InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'tümü', child: Text('Tüm Durumlar')),
                          DropdownMenuItem(
                              value: 'paid', child: Text('Ödendi')),
                          DropdownMenuItem(
                              value: 'pending', child: Text('Bekliyor')),
                          DropdownMenuItem(
                              value: 'partial', child: Text('Kısmi')),
                          DropdownMenuItem(
                              value: 'overdue', child: Text('Vadesi Geçti')),
                          DropdownMenuItem(
                              value: 'cancelled', child: Text('İptal')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tür Filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        onChanged: _onTypeFilterChanged,
                        decoration: InputDecoration(
                          labelText: 'Tür',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'tümü', child: Text('Tüm Türler')),
                          DropdownMenuItem(
                              value: 'ders_ucreti', child: Text('Ders Ücreti')),
                          DropdownMenuItem(
                              value: 'kayit_ucreti',
                              child: Text('Kayıt Ücreti')),
                          DropdownMenuItem(
                              value: 'sinav_ucreti',
                              child: Text('Sınav Ücreti')),
                          DropdownMenuItem(
                              value: 'materyal_ucreti',
                              child: Text('Materyal')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Yeni Ödeme Butonu
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigator.pushNamed(context, '/education-add-payment');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Ödeme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
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
                        'Toplam', _payments.length, const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Ödendi',
                        _payments.where((p) => p.status == 'paid').length,
                        AppConstants.successColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Bekliyor',
                        _payments.where((p) => p.status == 'pending').length,
                        AppConstants.warningColor),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        'Vadesi Geçti',
                        _payments.where((p) => p.status == 'overdue').length,
                        AppConstants.errorColor),
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
                      color: Color(0xFF10B981),
                    ),
                  )
                : _filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentsList(),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.payment,
              size: 64,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedStatus != 'tümü' ||
                    _selectedType != 'tümü'
                ? 'Filtreye uygun ödeme bulunamadı'
                : 'Henüz ödeme kaydı yok',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedStatus != 'tümü' ||
                    _selectedType != 'tümü'
                ? 'Farklı arama kriteri deneyin'
                : 'İlk ödeme kaydınızı ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigator.pushNamed(context, '/education-add-payment');
            },
            icon: const Icon(Icons.add),
            label: const Text('İlk Ödemeyi Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
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

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        final student = _studentsMap[payment.ogrenciId];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showPaymentDetails(payment),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(payment.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          payment.statusEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          student?.tamIsim ?? 'Bilinmeyen Öğrenci',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(payment.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          payment.statusAciklama,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(payment.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.odemeTuruAciklama,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${payment.odemeTarihi.day}/${payment.odemeTarihi.month}/${payment.odemeTarihi.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (payment.vadeseTarihi != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.schedule,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Vade: ${payment.vadeseTarihi!.day}/${payment.vadeseTarihi!.month}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: payment.vadesiGecti
                                          ? AppConstants.errorColor
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            payment.formatliOdenecekTutar,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(payment.status),
                            ),
                          ),
                          if (payment.indirimVar)
                            Text(
                              'İndirimli (${payment.formatliTutar})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (payment.taksitliOdeme || payment.makbuzNo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (payment.taksitliOdeme) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppConstants.infoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payment.taksitBilgisi,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppConstants.infoColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (payment.makbuzNo != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.successColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Makbuz: ${payment.makbuzNo}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppConstants.successColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppConstants.successColor;
      case 'pending':
        return AppConstants.warningColor;
      case 'partial':
        return AppConstants.infoColor;
      case 'overdue':
        return AppConstants.errorColor;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppConstants.textSecondary;
    }
  }
}
