import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/psychology_client_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PsychologyClientsPage extends StatefulWidget {
  const PsychologyClientsPage({super.key});

  @override
  State<PsychologyClientsPage> createState() => _PsychologyClientsPageState();
}

class _PsychologyClientsPageState extends State<PsychologyClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedType = 'all';
  bool _isLoading = true;
  List<PsychologyClient> _clients = [];
  List<PsychologyClient> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final clients = snapshot.docs
          .map((doc) => PsychologyClient.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        _clients = clients;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Danışanlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _clients.where((client) {
      final matchesSearch = _searchQuery.isEmpty ||
          client.tamAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.telefon.contains(_searchQuery);

      final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && client.status == 'active') ||
          (_selectedFilter == 'inactive' && client.status == 'inactive') ||
          (_selectedFilter == 'urgent' && client.oncelikDurumu == 'acil');

      final matchesType =
          _selectedType == 'all' || client.danisanTipi == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    setState(() {
      _filteredClients = filtered;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _showAddClientDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddClientDialog(
        onClientAdded: () {
          _loadClients();
        },
      ),
    );
  }

  void _showClientDetail(PsychologyClient client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ClientDetailPage(client: client),
      ),
    ).then((_) => _loadClients());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(localizations.clients),
        backgroundColor: const Color(0xFF6A5ACD),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddClientDialog,
            tooltip: localizations.addMember,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre Bölümü
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Arama Çubuğu
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: localizations.searchPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtreler
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: localizations.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(localizations.all),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(localizations.active),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(localizations.inactive),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text(localizations.urgent),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: localizations.type,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(localizations.all),
                          ),
                          DropdownMenuItem(
                            value: 'bireysel',
                            child: Text(localizations.individual),
                          ),
                          DropdownMenuItem(
                            value: 'cift',
                            child: Text(localizations.couple),
                          ),
                          DropdownMenuItem(
                            value: 'aile',
                            child: Text(localizations.family),
                          ),
                          DropdownMenuItem(
                            value: 'grup',
                            child: Text(localizations.group),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sonuç sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppConstants.backgroundColor,
            child: Row(
              children: [
                Text(
                  '${_filteredClients.length} danışan',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty ||
                    _selectedFilter != 'all' ||
                    _selectedType != 'all')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _selectedFilter = 'all';
                        _selectedType = 'all';
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Filtreleri Temizle'),
                  ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A5ACD),
                    ),
                  )
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadClients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return _buildClientCard(client);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        backgroundColor: const Color(0xFF6A5ACD),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6A5ACD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFF6A5ACD),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama sonucu bulunamadı'
                : 'Henüz danışan yok',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyin'
                : 'İlk danışanınızı ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddClientDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('İlk Danışanı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(PsychologyClient client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showClientDetail(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A5ACD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        client.cinsiyetEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.tamAd,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              client.statusEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (client.oncelikDurumu == 'acil') ...[
                              const SizedBox(width: 4),
                              Text(
                                client.oncelikEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.danisanTipiAciklama,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6A5ACD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // İletişim ve detaylar
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 14,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    client.telefronFormatli,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (client.yas != null) ...[
                    Icon(
                      Icons.cake,
                      size: 14,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      client.yasMetni,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),

              if (client.sonSeanstarihi != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Son seans: ${client.sonSeansMetni}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],

              if (client.notlar != null && client.notlar!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.notlar!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Danışan ekleme dialog'u
class _AddClientDialog extends StatefulWidget {
  final VoidCallback onClientAdded;

  const _AddClientDialog({required this.onClientAdded});

  @override
  State<_AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<_AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _notlarController = TextEditingController();

  String _selectedType = 'bireysel';
  String _selectedGender = 'belirtmek_istemez';
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu açmamış';

      final clientId = FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .doc()
          .id;

      final client = PsychologyClient(
        id: clientId,
        userId: user.uid,
        createdAt: DateTime.now(),
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
        telefon: _telefonController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        dogumTarihi: _birthDate,
        cinsiyet: _selectedGender,
        danisanTipi: _selectedType,
        notlar: _notlarController.text.trim().isEmpty
            ? null
            : _notlarController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .doc(clientId)
          .set(client.toMap());

      if (mounted) {
        Navigator.pop(context);
        widget.onClientAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Danışan başarıyla eklendi'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.addClient),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adController,
                        decoration: InputDecoration(
                          labelText: '${localizations.firstName} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return '${localizations.firstName} ${localizations.required.toLowerCase()}';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _soyadController,
                        decoration: InputDecoration(
                          labelText: '${localizations.lastName} *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return '${localizations.lastName} ${localizations.required.toLowerCase()}';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonController,
                  decoration: InputDecoration(
                    labelText: '${localizations.phoneNumber} *',
                    border: const OutlineInputBorder(),
                    prefixText: '+90 ',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return '${localizations.phoneNumber} ${localizations.required.toLowerCase()}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: localizations.email,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Terapi Türü',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'bireysel', child: Text('Bireysel')),
                          DropdownMenuItem(value: 'cift', child: Text('Çift')),
                          DropdownMenuItem(value: 'aile', child: Text('Aile')),
                          DropdownMenuItem(value: 'grup', child: Text('Grup')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'erkek', child: Text('Erkek')),
                          DropdownMenuItem(
                              value: 'kadın', child: Text('Kadın')),
                          DropdownMenuItem(
                              value: 'belirtmek_istemez',
                              child: Text('Belirtmek İstemez')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notlarController,
                  decoration: const InputDecoration(
                    labelText: 'İlk Notlar',
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Anksiyete problemi, ilk görüşme',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveClient,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A5ACD),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}

// Danışan detay sayfası placeholder
class _ClientDetailPage extends StatelessWidget {
  final PsychologyClient client;

  const _ClientDetailPage({required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(client.tamAd),
        backgroundColor: const Color(0xFF6A5ACD),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              client.tamAd,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Detay sayfası yakında aktif olacak'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
