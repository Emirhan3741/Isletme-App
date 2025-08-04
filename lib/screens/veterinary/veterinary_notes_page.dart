import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/models/veterinary_patient_model.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class VeterinaryNotesPage extends StatefulWidget {
  const VeterinaryNotesPage({super.key});

  @override
  State<VeterinaryNotesPage> createState() => _VeterinaryNotesPageState();
}

class _VeterinaryNotesPageState extends State<VeterinaryNotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'tümü';

  final List<Map<String, String>> _noteCategories = [
    {'value': 'tümü', 'label': 'Tümü'},
    {'value': 'genel', 'label': 'Genel Notlar'},
    {'value': 'tedavi', 'label': 'Tedavi Notları'},
    {'value': 'davranış', 'label': 'Davranış'},
    {'value': 'beslenme', 'label': 'Beslenme'},
    {'value': 'hatırlatıcı', 'label': 'Hatırlatıcılar'},
    {'value': 'diğer', 'label': 'Diğer'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddNoteDialog(
        onNoteAdded: () => setState(() {}),
        categories: _noteCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildFilterSection(),
          Expanded(child: _buildNotesList()),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.note_alt,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hasta Notları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Hastalarınız için özel notlar ve hatırlatıcılar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddNoteDialog,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Not'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
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

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Not ara...',
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
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PopupMenuButton<String>(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _noteCategories.firstWhere(
                            (c) => c['value'] == _selectedCategory)['label']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
              itemBuilder: (context) => _noteCategories.map((category) {
                return PopupMenuItem(
                  value: category['value'],
                  child: Text(category['label']!),
                );
              }).toList(),
              onSelected: (value) => setState(() => _selectedCategory = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildNotesQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNoteCard(data, doc.id);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildNotesQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('veterinary_notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    if (_selectedCategory != 'tümü') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Widget _buildNoteCard(Map<String, dynamic> data, String id) {
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final isImportant = data['isImportant'] == true;
    final patientId = data['patientId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            isImportant ? Border.all(color: Colors.red[300]!, width: 2) : null,
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
                  color: _getCategoryColor(data['category'])
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(data['category']),
                  color: _getCategoryColor(data['category']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Not',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (isImportant)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ÖNEMLİ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      _noteCategories.firstWhere(
                        (c) => c['value'] == data['category'],
                        orElse: () => _noteCategories.last,
                      )['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (patientId != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('veterinary_patients')
                  .doc(patientId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final patientData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pets,
                            size: 16, color: const Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'Hasta: ${patientData['hayvanAdi']} (${patientData['sahipAdi']} ${patientData['sahipSoyadi']})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          Text(
            data['content'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (data['reminder'] != null &&
              data['reminder']['enabled'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Hatırlatıcı: ${(data['reminder']['date'] as Timestamp).toDate().day}/${(data['reminder']['date'] as Timestamp).toDate().month}/${(data['reminder']['date'] as Timestamp).toDate().year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'tedavi':
        return Colors.blue;
      case 'davranış':
        return Colors.purple;
      case 'beslenme':
        return Colors.green;
      case 'hatırlatıcı':
        return Colors.orange;
      case 'genel':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'tedavi':
        return Icons.medical_services;
      case 'davranış':
        return Icons.psychology;
      case 'beslenme':
        return Icons.restaurant;
      case 'hatırlatıcı':
        return Icons.alarm;
      case 'genel':
        return Icons.note;
      default:
        return Icons.note_alt;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.note_alt,
                size: 50,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz not yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk notunuzu ekleyerek başlayın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddNoteDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Notu Ekle'),
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
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final VoidCallback onNoteAdded;
  final List<Map<String, String>> categories;

  const _AddNoteDialog({
    required this.onNoteAdded,
    required this.categories,
  });

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = 'genel';
  String? _selectedPatientId;
  bool _isImportant = false;
  bool _hasReminder = false;
  DateTime? _reminderDate;
  bool _isLoading = false;
  List<VeterinaryPatient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('veterinary_patients')
          .where('kullaniciId', isEqualTo: user.uid)
          .where('aktif', isEqualTo: true)
          .get();

      setState(() {
        _patients = snapshot.docs
            .map((doc) => VeterinaryPatient.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      // Hata durumunda boş liste kalır
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final noteData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'patientId': _selectedPatientId,
        'isImportant': _isImportant,
        'reminder': _hasReminder && _reminderDate != null
            ? {
                'enabled': true,
                'date': Timestamp.fromDate(_reminderDate!),
              }
            : null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('veterinary_notes')
          .add(noteData);

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(context, 'Not başarıyla eklendi');
        widget.onNoteAdded();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.add_circle_outline,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Yeni Not Ekle',
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
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Not Başlığı *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.categories
                            .where((c) => c['value'] != 'tümü')
                            .map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPatientId,
                        decoration: const InputDecoration(
                          labelText: 'Hasta (İsteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Hasta seçin'),
                          ),
                          ..._patients.map((patient) {
                            return DropdownMenuItem<String>(
                              value: patient.id,
                              child: Text(
                                  '${patient.hayvanAdi} (${patient.sahipAdi})'),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedPatientId = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Not İçeriği *',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidationUtils.validateRequired,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isImportant,
                      onChanged: (value) =>
                          setState(() => _isImportant = value!),
                    ),
                    const Text('Önemli not olarak işaretle'),
                    const SizedBox(width: 24),
                    Checkbox(
                      value: _hasReminder,
                      onChanged: (value) => setState(() {
                        _hasReminder = value!;
                        if (!_hasReminder) _reminderDate = null;
                      }),
                    ),
                    const Text('Hatırlatıcı ekle'),
                  ],
                ),
                if (_hasReminder) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _reminderDate ??
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _reminderDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hatırlatıcı Tarihi *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _reminderDate != null
                            ? '${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year}'
                            : 'Tarih seçin',
                        style: TextStyle(
                          color: _reminderDate != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
