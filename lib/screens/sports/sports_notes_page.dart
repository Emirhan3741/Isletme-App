import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/feedback_utils.dart';

class SportsNotesPage extends StatefulWidget {
  const SportsNotesPage({super.key});

  @override
  State<SportsNotesPage> createState() => _SportsNotesPageState();
}

class _SportsNotesPageState extends State<SportsNotesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Firebase entegrasyonu ile güncellendi
  List<SportNote> _notes = [];
  List<SportNote> _reminders = [];
  List<SportNote> _todos = [];

  String _searchQuery = '';
  NoteCategory _selectedCategory = NoteCategory.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  // Firebase'den notları yükle
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.sportsNotesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final allNotes = snapshot.docs.map((doc) {
        return SportNote.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        _notes = allNotes.where((note) => note.type == 'note').toList();
        _reminders = allNotes.where((note) => note.type == 'reminder').toList();
        _todos = allNotes.where((note) => note.type == 'todo').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Notlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildRemindersTab(),
                _buildTodosTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notes,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notlarım',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Planlar, hatırlatıcılar ve yapılacaklar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
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
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Notlarda ara...',
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
              const SizedBox(width: 12),
              PopupMenuButton<NoteCategory>(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedCategory.displayName),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                itemBuilder: (context) => NoteCategory.values.map((category) {
                  return PopupMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF8B5CF6),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note_alt),
                const SizedBox(width: 8),
                Text('Notlar (${_filterNotes(_notes).length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text('Hatırlatıcılar (${_filterNotes(_reminders).length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 8),
                Text('Yapılacaklar (${_filterNotes(_todos).length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final filteredNotes = _filterNotes(_notes);

    if (filteredNotes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.note_alt,
        title: 'Henüz not yok',
        subtitle: 'İlk notunuzu ekleyerek başlayın',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(filteredNotes[index]);
      },
    );
  }

  Widget _buildRemindersTab() {
    final filteredReminders = _filterNotes(_reminders);

    if (filteredReminders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'Henüz hatırlatıcı yok',
        subtitle: 'Önemli konular için hatırlatıcı ekleyin',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredReminders.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(filteredReminders[index]);
      },
    );
  }

  Widget _buildTodosTab() {
    final filteredTodos = _filterNotes(_todos);

    if (filteredTodos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Henüz yapılacak yok',
        subtitle: 'Görevlerinizi ekleyip takip edin',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(filteredTodos[index]);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 64,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(SportNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: note.priority == NotePriority.high
            ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: note.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  note.category.icon,
                  size: 16,
                  color: note.category.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: note.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.priority.name,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: note.priority.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (note.dueDate != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.event,
                  size: 14,
                  color: note.isOverdue ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Son: ${DateFormat('dd/MM/yyyy').format(note.dueDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: note.isOverdue ? Colors.red : Colors.orange,
                    fontWeight:
                        note.isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
              const Spacer(),
              if (note.isCompleted != null) ...[
                IconButton(
                  onPressed: () => _toggleTodoCompletion(note),
                  icon: Icon(
                    note.isCompleted!
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    size: 20,
                    color: note.isCompleted! ? Colors.green : Colors.grey,
                  ),
                  tooltip: note.isCompleted! ? 'Tamamlandı' : 'Tamamla',
                ),
              ],
              IconButton(
                onPressed: () => _showEditNoteDialog(note),
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Düzenle',
              ),
              IconButton(
                onPressed: () => _deleteNote(note),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<SportNote> _filterNotes(List<SportNote> notes) {
    return notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == NoteCategory.all ||
          note.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddNoteDialog(
        onNoteSaved: () => _loadNotes(),
      ),
    );
  }

  void _showEditNoteDialog(SportNote note) {
    showDialog(
      context: context,
      builder: (context) => _AddNoteDialog(
        note: note,
        onNoteSaved: () => _loadNotes(),
      ),
    );
  }

  Future<void> _deleteNote(SportNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content: Text(
            '${note.title} başlıklı notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.sportsNotesCollection)
            .doc(note.id)
            .delete();

        _loadNotes();
        FeedbackUtils.showSuccess(context, 'Not silindi');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Not silinirken hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleTodoCompletion(SportNote note) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.sportsNotesCollection)
          .doc(note.id)
          .update({
        'isCompleted': !note.isCompleted!,
        'updatedAt': Timestamp.now(),
      });

      _loadNotes();
    } catch (e) {
      FeedbackUtils.showError(context, 'Güncelleme hatası: $e');
    }
  }
}

// Models
enum NoteCategory {
  all,
  training,
  member,
  admin,
  maintenance,
  equipment,
  finance,
  marketing,
}

extension NoteCategoryExtension on NoteCategory {
  String get displayName {
    switch (this) {
      case NoteCategory.all:
        return 'Tümü';
      case NoteCategory.training:
        return 'Antrenman';
      case NoteCategory.member:
        return 'Üye';
      case NoteCategory.admin:
        return 'Yönetim';
      case NoteCategory.maintenance:
        return 'Bakım';
      case NoteCategory.equipment:
        return 'Ekipman';
      case NoteCategory.finance:
        return 'Finans';
      case NoteCategory.marketing:
        return 'Pazarlama';
    }
  }

  IconData get icon {
    switch (this) {
      case NoteCategory.all:
        return Icons.all_inclusive;
      case NoteCategory.training:
        return Icons.fitness_center;
      case NoteCategory.member:
        return Icons.people;
      case NoteCategory.admin:
        return Icons.admin_panel_settings;
      case NoteCategory.maintenance:
        return Icons.build;
      case NoteCategory.equipment:
        return Icons.sports_gymnastics;
      case NoteCategory.finance:
        return Icons.attach_money;
      case NoteCategory.marketing:
        return Icons.campaign;
    }
  }

  Color get color {
    switch (this) {
      case NoteCategory.all:
        return const Color(0xFF6B7280);
      case NoteCategory.training:
        return const Color(0xFFFF6B35);
      case NoteCategory.member:
        return const Color(0xFF3B82F6);
      case NoteCategory.admin:
        return const Color(0xFF8B5CF6);
      case NoteCategory.maintenance:
        return const Color(0xFFF59E0B);
      case NoteCategory.equipment:
        return const Color(0xFF10B981);
      case NoteCategory.finance:
        return const Color(0xFF059669);
      case NoteCategory.marketing:
        return const Color(0xFFEC4899);
    }
  }
}

enum NotePriority {
  low,
  medium,
  high,
}

extension NotePriorityExtension on NotePriority {
  String get name {
    switch (this) {
      case NotePriority.low:
        return 'Düşük';
      case NotePriority.medium:
        return 'Orta';
      case NotePriority.high:
        return 'Yüksek';
    }
  }

  Color get color {
    switch (this) {
      case NotePriority.low:
        return const Color(0xFF10B981);
      case NotePriority.medium:
        return const Color(0xFFF59E0B);
      case NotePriority.high:
        return const Color(0xFFEF4444);
    }
  }
}

class SportNote {
  final String id;
  final String title;
  final String content;
  final NoteCategory category;
  final NotePriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool? isCompleted;
  final String type; // note, reminder, todo

  SportNote({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.isCompleted,
    required this.type,
  });

  static SportNote fromMap(String id, Map<String, dynamic> map) {
    return SportNote(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: NoteCategory.values.firstWhere(
        (c) => c.name == (map['category'] ?? 'training'),
        orElse: () => NoteCategory.training,
      ),
      priority: NotePriority.values.firstWhere(
        (p) => p.name == (map['priority'] ?? 'medium'),
        orElse: () => NotePriority.medium,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: map['isCompleted'] ?? false,
      type: map['type'] ?? 'note',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'type': type,
      'updatedAt': Timestamp.now(),
    };
  }

  SportNote copyWith({
    String? id,
    String? title,
    String? content,
    NoteCategory? category,
    NotePriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    String? type,
  }) {
    return SportNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
    );
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}

class _AddNoteDialog extends StatefulWidget {
  final SportNote? note;
  final VoidCallback onNoteSaved;

  const _AddNoteDialog({
    this.note,
    required this.onNoteSaved,
  });

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedType = 'note';
  NoteCategory _selectedCategory = NoteCategory.training;
  NotePriority _selectedPriority = NotePriority.medium;
  DateTime? _dueDate;
  bool _isCompleted = false;
  bool _isLoading = false;

  final List<String> _noteTypes = ['note', 'reminder', 'todo'];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      final note = widget.note!;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedType = note.type;
      _selectedCategory = note.category;
      _selectedPriority = note.priority;
      _dueDate = note.dueDate;
      _isCompleted = note.isCompleted ?? false;
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
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final noteData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'type': _selectedType,
        'category': _selectedCategory.name,
        'priority': _selectedPriority.name,
        'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        'isCompleted': _isCompleted,
        'updatedAt': Timestamp.now(),
      };

      if (widget.note == null) {
        // Yeni not
        noteData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection(AppConstants.sportsNotesCollection)
            .add(noteData);
        FeedbackUtils.showSuccess(context, 'Not başarıyla eklendi');
      } else {
        // Mevcut notu güncelle
        await FirebaseFirestore.instance
            .collection(AppConstants.sportsNotesCollection)
            .doc(widget.note!.id)
            .update(noteData);
        FeedbackUtils.showSuccess(context, 'Not başarıyla güncellendi');
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onNoteSaved();
      }
    } catch (e) {
      FeedbackUtils.showError(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.note_add,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.note == null
                              ? 'Yeni Not Ekle'
                              : 'Notu Düzenle',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Text(
                          'Not bilgilerini girin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'İçerik *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İçerik gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type, Category, Priority row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tür *',
                        border: OutlineInputBorder(),
                      ),
                      items: _noteTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(_getTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<NoteCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                        border: OutlineInputBorder(),
                      ),
                      items: NoteCategory.values
                          .where((c) => c != NoteCategory.all)
                          .map((category) {
                        return DropdownMenuItem<NoteCategory>(
                          value: category,
                          child: Text(_getCategoryLabel(category)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<NotePriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik *',
                        border: OutlineInputBorder(),
                      ),
                      items: NotePriority.values.map((priority) {
                        return DropdownMenuItem<NotePriority>(
                          value: priority,
                          child: Text(_getPriorityLabel(priority)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Due date and completion
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _dueDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _dueDate != null
                                  ? 'Bitiş: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}'
                                  : 'Bitiş tarihi seç',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            if (_dueDate != null)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _dueDate = null),
                                icon: const Icon(Icons.clear, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedType == 'todo') ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Tamamlandı'),
                        value: _isCompleted,
                        onChanged: (value) {
                          setState(() => _isCompleted = value ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Kaydet'),
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'note':
        return 'Not';
      case 'reminder':
        return 'Hatırlatma';
      case 'todo':
        return 'Yapılacak';
      default:
        return type;
    }
  }

  String _getCategoryLabel(NoteCategory category) {
    switch (category) {
      case NoteCategory.training:
        return 'Antrenman';
      case NoteCategory.member:
        return 'Üye';
      case NoteCategory.admin:
        return 'Yönetim';
      case NoteCategory.maintenance:
        return 'Bakım';
      case NoteCategory.equipment:
        return 'Ekipman';
      case NoteCategory.finance:
        return 'Mali';
      case NoteCategory.marketing:
        return 'Pazarlama';
      default:
        return category.name;
    }
  }

  String _getPriorityLabel(NotePriority priority) {
    switch (priority) {
      case NotePriority.low:
        return 'Düşük';
      case NotePriority.medium:
        return 'Orta';
      case NotePriority.high:
        return 'Yüksek';
      default:
        return priority.name;
    }
  }
}
