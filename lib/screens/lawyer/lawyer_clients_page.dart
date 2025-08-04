import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_client_model.dart' hide DosyaDurumuConstants;
import '../../core/models/lawyer_client_model.dart' as LawyerModels
    show DosyaDurumuConstants;
import 'add_edit_client_page.dart';
import 'client_detail_page.dart';

class LawyerClientsPage extends StatefulWidget {
  const LawyerClientsPage({super.key});

  @override
  State<LawyerClientsPage> createState() => _LawyerClientsPageState();
}

class _LawyerClientsPageState extends State<LawyerClientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<LawyerClientModel> _clientList = [];

  List<LawyerClientModel> get filteredClients {
    List<LawyerClientModel> filtered = _clientList;

    // Durum filtreleme
    if (_selectedFilter != 'tumu') {
      filtered = filtered
          .where((client) => client.dosyaDurumu == _selectedFilter)
          .toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((client) =>
              client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              client.phone.contains(_searchQuery) ||
              client.dosyaNo!
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (client.tcNo?.contains(_searchQuery) ?? false))
          .toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Üst başlık ve yeni müvekkil butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Müvekkiller',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddClient(),
                  icon: const Icon(Icons.person_add,
                      size: 18, color: Colors.white),
                  label: const Text('Yeni Müvekkil',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Müvekkil ara (İsim, Telefon, Dosya No, TC)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide:
                      BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtre butonları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', 'tumu'),
                  _buildFilterChip('Devam Eden', 'devam_ediyor'),
                  _buildFilterChip('Tamamlanan', 'tamamlandi'),
                  _buildFilterChip('Kapalı', 'kapandi'),
                ],
              ),
            ),
          ),

          // Müvekkil listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = filteredClients[index];
                          return _buildClientCard(client);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: AppConstants.surfaceColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildClientCard(LawyerClientModel client) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _navigateToClientDetail(client),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - İsim ve durum
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSmall,
                      vertical: AppConstants.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(client.dosyaDurumu)
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadiusSmall),
                      border: Border.all(
                        color: _getStatusColor(client.dosyaDurumu),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      LawyerModels.DosyaDurumuConstants.getDurumDisplayName(
                          client.dosyaDurumu),
                      style: TextStyle(
                        color: _getStatusColor(client.dosyaDurumu),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Bilgiler
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.phone, client.phone),
                        if (client.email != null)
                          _buildInfoRow(Icons.email, client.email!),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (client.dosyaNo != null)
                          _buildInfoRow(Icons.folder, client.dosyaNo!),
                        if (client.tcNo != null)
                          _buildInfoRow(Icons.badge, 'TC: ${client.tcNo}'),
                      ],
                    ),
                  ),
                ],
              ),

              if (client.davaYazisi != null ||
                  client.mahkemeBilgisi != null) ...[
                const SizedBox(height: AppConstants.paddingSmall),
                Divider(color: AppConstants.borderColor),
                const SizedBox(height: AppConstants.paddingSmall),
              ],

              // Dava bilgileri
              if (client.davaYazisi != null)
                _buildInfoRow(Icons.gavel, 'Dava Türü: ${client.davaYazisi}'),

              if (client.mahkemeBilgisi != null)
                _buildInfoRow(Icons.location_city, client.mahkemeBilgisi!),

              // Alt satır - Tarihler ve işlemler
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Oluşturulma: ${_formatDate(client.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToEditClient(client),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, size: 20),
                        onPressed: () => _callClient(client.phone),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingXSmall),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
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
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun müvekkil bulunamadı'
                : 'Henüz müvekkil eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk müvekkilinizi eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'devam_ediyor':
        return Colors.blue;
      case 'tamamlandi':
        return Colors.green;
      case 'kapandi':
        return Colors.grey;
      default:
        return AppConstants.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _navigateToAddClient() {
    Navigator.pushNamed(context, '/lawyer-add-client').then((result) {
      if (result == true) {
        _loadClients();
      }
    });
  }

  void _navigateToEditClient(LawyerClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditClientPage(client: client),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _navigateToClientDetail(LawyerClientModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(client: client),
      ),
    );
  }

  void _callClient(String phoneNumber) {
    // Telefon arama işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phoneNumber aranıyor...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firebase'dan müvekkil verilerini çek
        final querySnapshot = await FirebaseFirestore.instance
            .collection(AppConstants.lawyerClientsCollection)
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        final clients = querySnapshot.docs
            .map((doc) {
              return LawyerClientModel.fromFirestore(doc);
            })
            .toList()
            .cast<LawyerClientModel>();

        setState(() {
          _clientList = clients;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Müvekkil verileri yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müvekkil verileri yüklenirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}
