import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/psychology_session_model.dart';
import '../../core/models/psychology_client_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PsychologySessionsPage extends StatefulWidget {
  const PsychologySessionsPage({super.key});

  @override
  State<PsychologySessionsPage> createState() => _PsychologySessionsPageState();
}

class _PsychologySessionsPageState extends State<PsychologySessionsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedType = 'all';
  bool _isLoading = true;
  List<PsychologySession> _sessions = [];
  List<PsychologySession> _filteredSessions = [];
  List<PsychologyClient> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSessions(),
      _loadClients(),
    ]);
  }

  Future<void> _loadSessions() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('seansTarihi', descending: true)
          .get();

      final sessions = snapshot.docs
          .map((doc) => PsychologySession.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        _sessions = sessions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Seanslar yüklenirken hata: $e');
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

  Future<void> _loadClients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.psychologyClientsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('ad')
          .get();

      final clients = snapshot.docs
          .map((doc) => PsychologyClient.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        _clients = clients;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Danışanlar yüklenirken hata: $e');
    }
  }

  void _applyFilters() {
    var filtered = _sessions.where((session) {
      final client = _clients.firstWhere(
        (c) => c.id == session.danisanId,
        orElse: () => PsychologyClient(
          id: '',
          userId: '',
          createdAt: DateTime.now(),
          ad: 'Bilinmeyen',
          soyad: 'Danışan',
          telefon: '',
        ),
      );

      final matchesSearch = _searchQuery.isEmpty ||
          client.tamAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          session.seansTuru
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (session.konular?.any((k) =>
                  k.toLowerCase().contains(_searchQuery.toLowerCase())) ??
              false);

      final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'completed' && session.tamamlandi) ||
          (_selectedFilter == 'upcoming' &&
              !session.tamamlandi &&
              session.seansTarihi.isAfter(DateTime.now())) ||
          (_selectedFilter == 'missed' &&
              !session.tamamlandi &&
              session.seansTarihi.isBefore(DateTime.now()));

      final matchesType =
          _selectedType == 'all' || session.seansTuru == _selectedType;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _applyFilters();
  }

  void _showAddSessionDialog() {
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce danışan eklemeniz gerekir'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddSessionDialog(
        clients: _clients,
        onSessionAdded: () {
          _loadSessions();
        },
      ),
    );
  }

  String _getClientName(String clientId) {
    final localizations = AppLocalizations.of(context)!;

    final client = _clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => PsychologyClient(
        id: '',
        userId: '',
        createdAt: DateTime.now(),
        ad: localizations.unknown,
        soyad: localizations.client,
        telefon: '',
      ),
    );
    return client.tamAd;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(localizations.sessions),
        backgroundColor: const Color(0xFF6A5ACD),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddSessionDialog,
            icon: const Icon(Icons.add_circle),
            tooltip: localizations.newSession,
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre Barı
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText:
                        '${localizations.search} (${localizations.client}, konu, tür)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filtre butónları
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: localizations.status,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(localizations.all)),
                          DropdownMenuItem(
                              value: 'completed',
                              child: Text(localizations.completed)),
                          DropdownMenuItem(
                              value: 'upcoming',
                              child: Text(localizations.upcoming)),
                          DropdownMenuItem(
                              value: 'missed',
                              child: Text(localizations.missed)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: localizations.sessionType,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(localizations.all)),
                          DropdownMenuItem(
                              value: 'bireysel_terapi',
                              child:
                                  Text('${localizations.individual} Terapi')),
                          DropdownMenuItem(
                              value: 'cift_terapisi',
                              child: Text('${localizations.couple} Terapisi')),
                          DropdownMenuItem(
                              value: 'aile_terapisi',
                              child: Text('${localizations.family} Terapisi')),
                          DropdownMenuItem(
                              value: 'grup_terapisi',
                              child: Text('${localizations.group} Terapisi')),
                        ],
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
                  '${_filteredSessions.length} seans',
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
                : _filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildSessionCard(session);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionDialog,
        backgroundColor: const Color(0xFF6A5ACD),
        child: const Icon(Icons.add, color: Colors.white),
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
              Icons.schedule,
              size: 64,
              color: Color(0xFF6A5ACD),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama sonucu bulunamadı'
                : 'Henüz seans yok',
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
                : _clients.isEmpty
                    ? 'Önce danışan ekleyin'
                    : 'İlk seansınızı planlayın',
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          if (_searchQuery.isEmpty && _clients.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSessionDialog,
              icon: const Icon(Icons.add_circle),
              label: const Text('İlk Seansı Planla'),
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

  Widget _buildSessionCard(PsychologySession session) {
    final clientName = _getClientName(session.danisanId);
    final isCompleted = session.tamamlandi;
    final isPast = session.seansTarihi.isBefore(DateTime.now());
    final isToday = DateTime.now().day == session.seansTarihi.day &&
        DateTime.now().month == session.seansTarihi.month &&
        DateTime.now().year == session.seansTarihi.year;

    Color statusColor = AppConstants.textSecondary;
    if (isCompleted) {
      statusColor = AppConstants.successColor;
    } else if (isToday) {
      statusColor = AppConstants.warningColor;
    } else if (isPast) {
      statusColor = AppConstants.errorColor;
    } else {
      statusColor = const Color(0xFF6A5ACD);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSessionDetail(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Durum göstergesi
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Danışan adı
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),

                  // Seans türü
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A5ACD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.seansTuruAciklama,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A5ACD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tarih ve saat
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.tarihSaatMetni,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.sure} dk',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    session.formatliUcret,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A5ACD),
                    ),
                  ),
                ],
              ),

              // Konular
              if (session.konular != null && session.konular!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: session.konular!
                      .take(3)
                      .map((konu) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppConstants.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              konu,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // Notlar
              if (session.seansNotlari != null &&
                  session.seansNotlari!.isNotEmpty) ...[
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
                        Icons.note_alt,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.seansNotlari!,
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

              // Durum metni
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    session.statusEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    session.durumMetni,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(PsychologySession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seans Detayı - ${_getClientName(session.danisanId)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tarih & Saat', session.tarihSaatMetni),
              _buildDetailRow('Süre', '${session.sure} dakika'),
              _buildDetailRow('Tür', session.seansTuruAciklama),
              _buildDetailRow('Ücret', session.formatliUcret),
              if (session.konular != null && session.konular!.isNotEmpty)
                _buildDetailRow('Konular', session.konular!.join(', ')),
              if (session.seansNotlari != null &&
                  session.seansNotlari!.isNotEmpty)
                _buildDetailRow('Notlar', session.seansNotlari!),
              _buildDetailRow('Durum', session.durumMetni),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (!session.tamamlandi)
            ElevatedButton(
              onPressed: () => _markAsCompleted(session),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tamamlandı İşaretle'),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted(PsychologySession session) async {
    try {
      final updatedSession = session.copyWith(
        status: 'tamamlandi',
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .doc(session.id)
          .update(updatedSession.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seans tamamlandı olarak işaretlendi'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        _loadSessions();
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
    }
  }
}

// Seans ekleme dialog'u
class _AddSessionDialog extends StatefulWidget {
  final List<PsychologyClient> clients;
  final VoidCallback onSessionAdded;

  const _AddSessionDialog({
    required this.clients,
    required this.onSessionAdded,
  });

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notlarController = TextEditingController();
  final _ucretController = TextEditingController(text: '400');

  String? _selectedClientId;
  String _selectedType = 'bireysel_terapi';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 50;
  final List<String> _selectedTopics = [];
  bool _isLoading = false;

  final List<String> _availableTopics = [
    'Anksiyete',
    'Depresyon',
    'Stres Yönetimi',
    'İlişki Problemleri',
    'Travma',
    'Öfke Kontrolü',
    'Özgüven',
    'Uyku Problemleri',
    'Obsesif Kompulsif',
    'Panik Atak',
    'Sosyal Fobi',
    'Dikkat Eksikliği',
    'Bağımlılık',
    'Yas Süreci',
    'Aile İçi İletişim',
    'Çocuk Gelişimi',
    'Ergen Problemleri',
    'Kariyer Danışmanlığı',
    'Kişilik Bozuklukları',
    'Başka',
  ];

  @override
  void dispose() {
    _notlarController.dispose();
    _ucretController.dispose();
    super.dispose();
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen danışan seçin'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu açmamış';

      final sessionId = FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .doc()
          .id;

      final sessionDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final session = PsychologySession(
        id: sessionId,
        userId: user.uid,
        createdAt: DateTime.now(),
        danisanId: _selectedClientId!,
        seansTarihi: sessionDateTime,
        saatAraligi:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        sure: _duration,
        seansTuru: _selectedType,
        ucret: double.tryParse(_ucretController.text) ?? 0,
        konular: _selectedTopics.isNotEmpty ? _selectedTopics : null,
        seansNotlari: _notlarController.text.trim().isEmpty
            ? null
            : _notlarController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.psychologySessionsCollection)
          .doc(sessionId)
          .set(session.toMap());

      if (mounted) {
        Navigator.pop(context);
        widget.onSessionAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seans başarıyla eklendi'),
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _showTopicSelector() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations.sessionTopics),
          content: SizedBox(
            width: 300,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: _getLocalizedTopics(localizations).map((topicData) {
                  final isSelected =
                      _selectedTopics.contains(topicData['key']!);
                  return CheckboxListTile(
                    title: Text(topicData['label']!),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedTopics.add(topicData['key']!);
                        } else {
                          _selectedTopics.remove(topicData['key']!);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.confirm),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
  }

  List<Map<String, String>> _getLocalizedTopics(
      AppLocalizations localizations) {
    return [
      {'key': 'anxiety', 'label': localizations.anxiety},
      {'key': 'depression', 'label': localizations.depression},
      {'key': 'stress_management', 'label': localizations.stressManagement},
      {
        'key': 'relationship_problems',
        'label': localizations.relationshipProblems
      },
      {'key': 'trauma', 'label': localizations.trauma},
      {'key': 'anger_management', 'label': localizations.angerManagement},
      {'key': 'self_confidence', 'label': localizations.selfConfidence},
      {'key': 'sleep_problems', 'label': localizations.sleepProblems},
      {
        'key': 'obsessive_compulsive',
        'label': localizations.obsessiveCompulsive
      },
      {'key': 'panic_attack', 'label': localizations.panicAttack},
      {'key': 'social_phobia', 'label': localizations.socialPhobia},
      {'key': 'attention_deficit', 'label': localizations.attentionDeficit},
      {'key': 'addiction', 'label': localizations.addiction},
      {'key': 'grief_process', 'label': localizations.griefProcess},
      {
        'key': 'family_communication',
        'label': localizations.familyCommunication
      },
      {'key': 'child_development', 'label': localizations.childDevelopment},
      {'key': 'adolescent_problems', 'label': localizations.adolescentProblems},
      {'key': 'career_counseling', 'label': localizations.careerCounseling},
      {
        'key': 'personality_disorders',
        'label': localizations.personalityDisorders
      },
      {'key': 'other', 'label': localizations.other},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.addSession),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Danışan seçimi
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Danışan *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.clients.map((client) {
                    return DropdownMenuItem(
                      value: client.id,
                      child: Text(client.tamAd),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) return 'Danışan seçin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Seans türü
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Seans Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'bireysel_terapi',
                        child: Text('Bireysel Terapi')),
                    DropdownMenuItem(
                        value: 'cift_terapisi', child: Text('Çift Terapisi')),
                    DropdownMenuItem(
                        value: 'aile_terapisi', child: Text('Aile Terapisi')),
                    DropdownMenuItem(
                        value: 'grup_terapisi', child: Text('Grup Terapisi')),
                    DropdownMenuItem(
                        value: 'online_seans', child: Text('Online Seans')),
                    DropdownMenuItem(
                        value: 'degerlendirme', child: Text('Değerlendirme')),
                    DropdownMenuItem(value: 'kontrol', child: Text('Kontrol')),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarih ve saat
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Süre ve ücret
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _duration,
                        onChanged: (value) {
                          setState(() {
                            _duration = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Süre (dk)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 dk')),
                          DropdownMenuItem(value: 45, child: Text('45 dk')),
                          DropdownMenuItem(value: 50, child: Text('50 dk')),
                          DropdownMenuItem(value: 60, child: Text('60 dk')),
                          DropdownMenuItem(value: 90, child: Text('90 dk')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ucretController,
                        decoration: const InputDecoration(
                          labelText: 'Ücret (₺)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Ücret gerekli';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Geçerli tutar girin';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Konular
                InkWell(
                  onTap: _showTopicSelector,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.topic),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTopics.isEmpty
                                ? 'Konular seç (opsiyonel)'
                                : '${_selectedTopics.length} konu seçildi',
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                if (_selectedTopics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedTopics
                        .map((topic) => Chip(
                              label: Text(topic),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedTopics.remove(topic);
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Notlar
                TextFormField(
                  controller: _notlarController,
                  decoration: const InputDecoration(
                    labelText: 'Seans Notları',
                    border: OutlineInputBorder(),
                    hintText: 'Planlanan aktiviteler, ödev vb.',
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
          onPressed: _isLoading ? null : _saveSession,
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
              : const Text('Planla'),
        ),
      ],
    );
  }
}
