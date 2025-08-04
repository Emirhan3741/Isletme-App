import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/veterinary_patient_model.dart';
import '../../utils/feedback_utils.dart';
import 'add_edit_patient_page.dart';

class PatientDetailPage extends StatefulWidget {
  final VeterinaryPatient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late VeterinaryPatient _patient;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _patient = widget.patient;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _editPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPatientPage(patient: _patient),
      ),
    );

    if (result == true) {
      // Hasta bilgilerini yeniden yükle
      _reloadPatientData();
    }
  }

  Future<void> _reloadPatientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('veterinary_patients')
          .doc(_patient.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _patient = VeterinaryPatient.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
            context, 'Hasta bilgileri yüklenirken hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 200,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF059669)),
                  onPressed: _editPatient,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF111827)),
                  onPressed: () => _showOptionsMenu(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildPatientHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Bilgiler'),
                  Tab(text: 'İşlemler'),
                  Tab(text: 'Aşılar'),
                  Tab(text: 'Ödemeler'),
                ],
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF059669),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBilgilerTab(),
            _buildIslemlerTab(),
            _buildAsilarTab(),
            _buildOdemelerTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    final yas = _patient.dogumTarihi != null
        ? DateTime.now().difference(_patient.dogumTarihi!).inDays ~/ 365
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  _getAnimalIcon(_patient.hayvanTuru),
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patient.hayvanAdi,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_patient.hayvanTuru.toUpperCase()} • ${_patient.hayvanCinsi}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (yas != null)
                      Text(
                        '$yas yaşında',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                  'Sahip: ${_patient.sahipAdi} ${_patient.sahipSoyadi}'),
              const SizedBox(width: 8),
              _buildInfoChip('${_patient.agirlik} kg'),
              const SizedBox(width: 8),
              _buildInfoChip(
                  _patient.saglikDurumu.replaceAll('_', ' ').toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getAnimalIcon(String hayvanTuru) {
    switch (hayvanTuru) {
      case 'köpek':
        return Icons.pets;
      case 'kedi':
        return Icons.pest_control;
      case 'kuş':
        return Icons.airline_stops;
      case 'tavşan':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }

  Widget _buildBilgilerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoSection('Genel Bilgiler', [
            _buildInfoRow('Hayvan Adı', _patient.hayvanAdi),
            _buildInfoRow('Türü', _patient.hayvanTuru),
            _buildInfoRow('Cinsi', _patient.hayvanCinsi),
            _buildInfoRow('Cinsiyeti', _patient.cinsiyet),
            _buildInfoRow('Rengi', _patient.renk),
            _buildInfoRow('Ağırlığı', '${_patient.agirlik} kg'),
            if (_patient.chipNumarasi != null)
              _buildInfoRow('Mikroçip', _patient.chipNumarasi!),
            if (_patient.dogumTarihi != null)
              _buildInfoRow('Doğum Tarihi',
                  '${_patient.dogumTarihi!.day}/${_patient.dogumTarihi!.month}/${_patient.dogumTarihi!.year}'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Sahip Bilgileri', [
            _buildInfoRow(
                'Ad Soyad', '${_patient.sahipAdi} ${_patient.sahipSoyadi}'),
            _buildInfoRow('Telefon', _patient.sahipTelefon),
            if (_patient.sahipEmail != null)
              _buildInfoRow('E-posta', _patient.sahipEmail!),
            if (_patient.sahipAdres != null)
              _buildInfoRow('Adres', _patient.sahipAdres!),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Sağlık Bilgileri', [
            _buildInfoRow(
                'Sağlık Durumu', _patient.saglikDurumu.replaceAll('_', ' ')),
            _buildInfoRow('Kısırlaştırılma',
                _patient.kisirlastirilmis ? 'Evet' : 'Hayır'),
            if (_patient.kisirlastirilmis &&
                _patient.kisirlastirmaTarihi != null)
              _buildInfoRow('Kısırlaştırma Tarihi',
                  '${_patient.kisirlastirmaTarihi!.day}/${_patient.kisirlastirmaTarihi!.month}/${_patient.kisirlastirmaTarihi!.year}'),
            if (_patient.alerjiler != null)
              _buildInfoRow('Alerjiler', _patient.alerjiler!),
            if (_patient.kronikHastalik != null)
              _buildInfoRow('Kronik Hastalıklar', _patient.kronikHastalik!),
            if (_patient.kullandigiIlaclar != null)
              _buildInfoRow('Kullandığı İlaçlar', _patient.kullandigiIlaclar!),
          ]),
          if (_patient.ozelNotlar != null ||
              _patient.veterinerNotu != null) ...[
            const SizedBox(height: 24),
            _buildInfoSection('Notlar', [
              if (_patient.ozelNotlar != null)
                _buildInfoRow('Özel Notlar', _patient.ozelNotlar!),
              if (_patient.veterinerNotu != null)
                _buildInfoRow('Veteriner Notları', _patient.veterinerNotu!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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

  Widget _buildIslemlerTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('veterinary_treatments')
          .where('patientId', isEqualTo: _patient.id)
          .orderBy('treatmentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'Henüz işlem yok',
            'Bu hastaya ait henüz bir işlem kaydı bulunmuyor.',
            Icons.medical_services,
            'İlk İşlemi Ekle',
            () => _addTreatment(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTreatmentCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildAsilarTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('veterinary_vaccinations')
          .where('patientId', isEqualTo: _patient.id)
          .orderBy('vaccinationDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'Henüz aşı yok',
            'Bu hastaya ait aşı kaydı bulunmuyor.',
            Icons.vaccines,
            'İlk Aşıyı Ekle',
            () => _addVaccination(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildVaccinationCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildOdemelerTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('veterinary_payments')
          .where('patientId', isEqualTo: _patient.id)
          .orderBy('paymentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'Henüz ödeme yok',
            'Bu hastaya ait ödeme kaydı bulunmuyor.',
            Icons.payment,
            'İlk Ödemeyi Ekle',
            () => _addPayment(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPaymentCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon,
      String buttonText, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
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
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> data, String id) {
    final date = (data['treatmentDate'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF059669),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['treatmentType'] ?? 'İşlem',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
          if (data['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              data['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (data['cost'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '${data['cost']} ₺',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> data, String id) {
    final date = (data['vaccinationDate'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.vaccines,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['vaccineName'] ?? 'Aşı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
          if (data['nextDueDate'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Sonraki: ${(data['nextDueDate'] as Timestamp).toDate().day}/${(data['nextDueDate'] as Timestamp).toDate().month}/${(data['nextDueDate'] as Timestamp).toDate().year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> data, String id) {
    final date = (data['paymentDate'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['description'] ?? 'Ödeme',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${data['amount']} ₺',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('İşlem Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  _addTreatment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.vaccines),
                title: const Text('Aşı Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  _addVaccination();
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Ödeme Ekle'),
                onTap: () {
                  Navigator.pop(context);
                  _addPayment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Rapor Yazdır'),
                onTap: () {
                  Navigator.pop(context);
                  _printReport();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addTreatment() {
    // TODO: İşlem ekleme sayfası açılacak
    FeedbackUtils.showInfo(context, 'İşlem ekleme sayfası yakında gelecek');
  }

  void _addVaccination() {
    // TODO: Aşı ekleme sayfası açılacak
    FeedbackUtils.showInfo(context, 'Aşı ekleme sayfası yakında gelecek');
  }

  void _addPayment() {
    // TODO: Ödeme ekleme sayfası açılacak
    FeedbackUtils.showInfo(context, 'Ödeme ekleme sayfası yakında gelecek');
  }

  void _printReport() {
    // TODO: PDF rapor oluşturma
    FeedbackUtils.showInfo(context, 'Rapor yazdırma özelliği yakında gelecek');
  }
}
