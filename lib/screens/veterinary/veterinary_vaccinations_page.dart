import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/veterinary_vaccination_model.dart';

class VeterinaryVaccinationsPage extends StatefulWidget {
  const VeterinaryVaccinationsPage({super.key});

  @override
  State<VeterinaryVaccinationsPage> createState() =>
      _VeterinaryVaccinationsPageState();
}

class _VeterinaryVaccinationsPageState
    extends State<VeterinaryVaccinationsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tümü';
  bool _isLoading = true;
  List<VeterinaryVaccination> _vaccinations = [];

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Demo verisi göster
        setState(() {
          _vaccinations = _generateDemoVaccinations();
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.veterinaryVaccinationsCollection)
          .where('kullaniciId', isEqualTo: user.uid)
          .where('aktif', isEqualTo: true)
          .orderBy('uygulamaTarihi', descending: true)
          .get();

      setState(() {
        _vaccinations = snapshot.docs
            .map((doc) => VeterinaryVaccination.fromMap(doc.data(), doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Aşılar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  List<VeterinaryVaccination> _generateDemoVaccinations() {
    final now = DateTime.now();
    return [
      VeterinaryVaccination(
        id: '1',
        kullaniciId: 'demo',
        hastaId: 'hasta1',
        asiAdi: 'DHPP Karma Aşısı',
        asiMarkasi: 'Nobivac',
        uygulamaTarihi: now.subtract(const Duration(days: 30)),
        tekrarTarihi: now.add(const Duration(days: 335)),
        uygulananBolge: 'Boyun',
        veterinerAdi: 'Dr. Mehmet Öz',
        durum: 'uygulandi',
        asiUcreti: 150.0,
        asiKartiNumarasi: 'AK001',
        asiKartindaMi: true,
        kayitTarihi: now.subtract(const Duration(days: 30)),
        guncellemeTarihi: now,
        aktif: true,
      ),
      VeterinaryVaccination(
        id: '2',
        kullaniciId: 'demo',
        hastaId: 'hasta2',
        asiAdi: 'Kuduz Aşısı',
        asiMarkasi: 'Rabisin',
        uygulamaTarihi: now.add(const Duration(days: 7)),
        tekrarTarihi: now.add(const Duration(days: 372)),
        uygulananBolge: 'Arka bacak',
        veterinerAdi: 'Dr. Ayşe Kaya',
        durum: 'planlandı',
        asiUcreti: 100.0,
        asiKartiNumarasi: 'AK002',
        asiKartindaMi: true,
        kayitTarihi: now.subtract(const Duration(days: 7)),
        guncellemeTarihi: now,
        aktif: true,
      ),
      VeterinaryVaccination(
        id: '3',
        kullaniciId: 'demo',
        hastaId: 'hasta3',
        asiAdi: 'Kedi Üçlü Aşısı',
        asiMarkasi: 'Felocell',
        uygulamaTarihi: now.subtract(const Duration(days: 15)),
        tekrarTarihi: now.add(const Duration(days: 350)),
        uygulananBolge: 'Boyun',
        durum: 'uygulandi',
        asiUcreti: 120.0,
        asiKartiNumarasi: 'AK003',
        asiKartindaMi: true,
        kayitTarihi: now.subtract(const Duration(days: 15)),
        guncellemeTarihi: now,
        aktif: true,
      ),
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
                      hintText: 'Aşı ara...',
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

                // Durum Filtresi
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
                    hint: const Text('Durum'),
                    items: const [
                      DropdownMenuItem(value: 'tümü', child: Text('Tümü')),
                      DropdownMenuItem(
                          value: 'uygulandi', child: Text('Uygulandı')),
                      DropdownMenuItem(
                          value: 'planlandı', child: Text('Planlandı')),
                      DropdownMenuItem(
                          value: 'gecikti', child: Text('Gecikti')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                ElevatedButton.icon(
                  onPressed: () => _showAddVaccinationDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Aşı'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
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
                      color: Color(0xFFF59E0B),
                    ),
                  )
                : _vaccinations.isEmpty
                    ? _buildEmptyState()
                    : _buildVaccinationsList(),
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
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.vaccines,
              size: 64,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz aşı kaydı yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'İlk aşı kaydını ekleyerek başlayın',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddVaccinationDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Aşıyı Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
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

  Widget _buildVaccinationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _vaccinations.length,
      itemBuilder: (context, index) {
        final vaccination = _vaccinations[index];
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vaccination.durumEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaccination.asiAdi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (vaccination.asiMarkasi != null)
                          Text(
                            vaccination.asiMarkasi!,
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
                      color: Color(int.parse(
                              '0xFF${vaccination.durumRenk.substring(1)}'))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vaccination.durum.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(int.parse(
                            '0xFF${vaccination.durumRenk.substring(1)}')),
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
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Uygulama: ${vaccination.formatliUygulamaTarihi}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tekrar: ${vaccination.formatliTekrarTarihi}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vaccination.uygulananBolge,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vaccination.formatliUcret,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              if (vaccination.veterinerAdi != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vaccination.veterinerAdi!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
              if (vaccination.asiNotu != null &&
                  vaccination.asiNotu!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vaccination.asiNotu!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddVaccinationDialog() {
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.vaccines,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yeni Aşı Ekle',
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
                      Icons.medical_information,
                      size: 64,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aşı Kayıt Formu',
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
