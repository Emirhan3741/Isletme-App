import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/veterinary_patient_model.dart';

class VeterinaryPatientsPage extends StatefulWidget {
  const VeterinaryPatientsPage({super.key});

  @override
  State<VeterinaryPatientsPage> createState() => _VeterinaryPatientsPageState();
}

class _VeterinaryPatientsPageState extends State<VeterinaryPatientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  bool _isLoading = true;
  List<VeterinaryPatient> _patients = [];
  List<VeterinaryPatient> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Demo verisi göster
        setState(() {
          _patients = _generateDemoPatients();
          _filteredPatients = _patients;
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.veterinaryPatientsCollection)
          .where('kullaniciId', isEqualTo: user.uid)
          .where('aktif', isEqualTo: true)
          .orderBy('kayitTarihi', descending: true)
          .get();

      setState(() {
        _patients = snapshot.docs
            .map((doc) => VeterinaryPatient.fromMap(doc.data(), doc.id))
            .toList();
        _filteredPatients = _patients;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Hastalar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  List<VeterinaryPatient> _generateDemoPatients() {
    return [
      VeterinaryPatient(
        id: '1',
        kullaniciId: 'demo',
        hayvanAdi: 'Pamuk',
        hayvanTuru: 'kedi',
        hayvanCinsi: 'Persian',
        chipNumarasi: '123456789',
        dogumTarihi: DateTime(2020, 5, 15),
        cinsiyet: 'dişi',
        agirlik: 4.2,
        renk: 'Beyaz',
        sahipAdi: 'Ayşe',
        sahipSoyadi: 'Yılmaz',
        sahipTelefon: '0532 123 4567',
        sahipEmail: 'ayse@email.com',
        saglikDurumu: 'sağlıklı',
        kisirlastirilmis: true,
        kayitTarihi: DateTime.now().subtract(const Duration(days: 30)),
        guncellemeTarihi: DateTime.now(),
        aktif: true,
      ),
      VeterinaryPatient(
        id: '2',
        kullaniciId: 'demo',
        hayvanAdi: 'Rex',
        hayvanTuru: 'köpek',
        hayvanCinsi: 'Golden Retriever',
        dogumTarihi: DateTime(2019, 8, 22),
        cinsiyet: 'erkek',
        agirlik: 28.5,
        renk: 'Altın Sarısı',
        sahipAdi: 'Mehmet',
        sahipSoyadi: 'Demir',
        sahipTelefon: '0533 987 6543',
        saglikDurumu: 'kontrol_altında',
        kronikHastalik: 'Kalça displazisi',
        kisirlastirilmis: false,
        kayitTarihi: DateTime.now().subtract(const Duration(days: 60)),
        guncellemeTarihi: DateTime.now(),
        aktif: true,
      ),
      VeterinaryPatient(
        id: '3',
        kullaniciId: 'demo',
        hayvanAdi: 'Cıvıl',
        hayvanTuru: 'kuş',
        hayvanCinsi: 'Muhabbet Kuşu',
        dogumTarihi: DateTime(2022, 3, 10),
        cinsiyet: 'erkek',
        agirlik: 0.035,
        renk: 'Mavi-Beyaz',
        sahipAdi: 'Zeynep',
        sahipSoyadi: 'Kaya',
        sahipTelefon: '0534 555 7788',
        saglikDurumu: 'sağlıklı',
        kisirlastirilmis: false,
        kayitTarihi: DateTime.now().subtract(const Duration(days: 15)),
        guncellemeTarihi: DateTime.now(),
        aktif: true,
      ),
    ];
  }

  void _filterPatients() {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        // Arama filtresi
        bool matchesSearch = _searchQuery.isEmpty ||
            patient.hayvanAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            patient.sahipTamAdi
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            patient.hayvanTuru
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        // Tür filtresi
        bool matchesFilter =
            _selectedFilter == 'tümü' || patient.hayvanTuru == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
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
                      _filterPatients();
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

                // Tür Filtresi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    underline: const SizedBox(),
                    hint: const Text('Tür'),
                    items: [
                      const DropdownMenuItem(
                          value: 'tümü', child: Text('Tüm Türler')),
                      ...AnimalTypes.tumuTurler.map((tur) => DropdownMenuItem(
                            value: tur,
                            child: Text(
                                '${AnimalTypes.getTurEmoji(tur)} ${tur.toUpperCase()}'),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      _filterPatients();
                    },
                  ),
                ),
                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/veterinary/add-patient'),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Hasta'),
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

          // İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF059669),
                    ),
                  )
                : _filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : _buildPatientsList(),
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
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pets,
              size: 64,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz hasta yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerinize uygun hasta bulunamadı'
                : 'İlk hastanızı ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/veterinary/add-patient'),
              icon: const Icon(Icons.add),
              label: const Text('İlk Hastayı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
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

  Widget _buildPatientsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildPatientCard(VeterinaryPatient patient) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/veterinary/patient-detail',
        arguments: patient.id,
      ),
      child: Container(
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
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AnimalTypes.getTurEmoji(patient.hayvanTuru),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.hayvanAdi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${patient.hayvanTuru} - ${patient.hayvanCinsi}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  patient.saglikDurumuEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sahip Bilgisi
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    patient.sahipTamAdi,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Yaş ve Ağırlık
            Row(
              children: [
                const Icon(
                  Icons.cake,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  patient.yasMetni,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.monitor_weight,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  '${patient.agirlik}kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Chip ve Kısırlaştırma
            Row(
              children: [
                if (patient.chipliMi)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Chipli',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (patient.kisirlastirilmis)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Kısır',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
