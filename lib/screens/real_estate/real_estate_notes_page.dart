import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/feedback_utils.dart';

// TODO: Bu sayfaya not tipi kategorileri, müşteri bağlantısı, sil/düzenle işlemleri eklenecek
class RealEstateNotesPage extends StatefulWidget {
  const RealEstateNotesPage({super.key});

  @override
  State<RealEstateNotesPage> createState() => _RealEstateNotesPageState();
}

class _RealEstateNotesPageState extends State<RealEstateNotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'tümü';
  bool _isLoading = false;
  List<RealEstateNote> _notes = [];

  final List<String> _categoryOptions = [
    'tümü',
    'görüşme',
    'portföy',
    'işlem',
    'değerlendirme',
    'hatırlatma',
    'genel'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<RealEstateNote> get _filteredNotes {
    return _notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.customerName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'tümü' || note.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('real_estate_notes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final notes = snapshot.docs.map((doc) {
        final data = doc.data();
        return RealEstateNote.fromMap(doc.id, data);
      }).toList();

      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Notlar yüklenirken hata: $e');
      setState(() {
        _notes = [];
        _isLoading = false;
      });
    }
  }

  void _showAddNoteDialog({RealEstateNote? note}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditNoteDialog(
        note: note,
        onNoteSaved: () => _loadNotes(),
      ),
    );
  }

  void _deleteNote(RealEstateNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('real_estate_notes')
            .doc(note.id)
            .delete();

        FeedbackUtils.showSuccess(context, 'Not başarıyla silindi');
        _loadNotes();
      } catch (e) {
        FeedbackUtils.showError(context, 'Not silinirken hata oluştu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.note,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not Yönetimi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Müşteri görüşmeleri, portföy açıklamaları ve işlem notları',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddNoteDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Not Ekle',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
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

          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Başlık, içerik veya müşteri adı ile arayın...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categoryOptions.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryDisplayName(category)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_filteredNotes.length} not',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'tümü':
        return 'Tümü';
      case 'görüşme':
        return 'Müşteri Görüşmesi';
      case 'portföy':
        return 'Portföy Açıklaması';
      case 'işlem':
        return 'İşlem Notu';
      case 'değerlendirme':
        return 'Emlak Değerlendirme';
      case 'hatırlatma':
        return 'Hatırlatma';
      case 'genel':
        return 'Genel Not';
      default:
        return category;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.note_add,
              size: 64,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz not yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerinize uygun not bulunamadı'
                : 'İlk notunuzu ekleyerek başlayın',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(note.category)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCategoryDisplayName(note.category),
                        style: TextStyle(
                          color: _getCategoryColor(note.category),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showAddNoteDialog(note: note);
                            break;
                          case 'delete':
                            _deleteNote(note);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              const SizedBox(width: 8),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Sil', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      note.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today,
                        size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'görüşme':
        return Colors.blue;
      case 'portföy':
        return Colors.green;
      case 'işlem':
        return Colors.purple;
      case 'değerlendirme':
        return Colors.orange;
      case 'hatırlatma':
        return Colors.red;
      case 'genel':
        return Colors.grey;
      default:
        return Colors.amber;
    }
  }
}

// Note Model
class RealEstateNote {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String customerName;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RealEstateNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.customerName,
    required this.category,
    required this.createdAt,
    this.updatedAt,
  });

  factory RealEstateNote.fromMap(String id, Map<String, dynamic> data) {
    return RealEstateNote(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      customerName: data['customerName'] ?? '',
      category: data['category'] ?? 'genel',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'customerName': customerName,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

// Add/Edit Note Dialog
class _AddEditNoteDialog extends StatefulWidget {
  final RealEstateNote? note;
  final VoidCallback onNoteSaved;

  const _AddEditNoteDialog({
    this.note,
    required this.onNoteSaved,
  });

  @override
  State<_AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<_AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customerController = TextEditingController();

  String _selectedCategory = 'genel';
  bool _isLoading = false;

  final List<String> _categories = [
    'görüşme',
    'portföy',
    'işlem',
    'değerlendirme',
    'hatırlatma',
    'genel'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _customerController.text = widget.note!.customerName;
      _selectedCategory = widget.note!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'görüşme':
        return 'Müşteri Görüşmesi';
      case 'portföy':
        return 'Portföy Açıklaması';
      case 'işlem':
        return 'İşlem Notu';
      case 'değerlendirme':
        return 'Emlak Değerlendirme';
      case 'hatırlatma':
        return 'Hatırlatma';
      case 'genel':
        return 'Genel Not';
      default:
        return category;
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final noteData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'customerName': _customerController.text.trim(),
        'category': _selectedCategory,
        'updatedAt': Timestamp.now(),
      };

      if (widget.note == null) {
        // Yeni not ekle
        noteData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('real_estate_notes')
            .add(noteData);

        FeedbackUtils.showSuccess(context, 'Not başarıyla eklendi');
      } else {
        // Mevcut notu güncelle
        await FirebaseFirestore.instance
            .collection('real_estate_notes')
            .doc(widget.note!.id)
            .update(noteData);

        FeedbackUtils.showSuccess(context, 'Not başarıyla güncellendi');
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onNoteSaved();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.note == null ? 'Yeni Not' : 'Notu Düzenle',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Başlık *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Başlık gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'Müşteri Adı *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Müşteri adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value!),
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryDisplayName(category)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'İçerik *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'İçerik gerekli';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.note == null ? 'Ekle' : 'Güncelle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
