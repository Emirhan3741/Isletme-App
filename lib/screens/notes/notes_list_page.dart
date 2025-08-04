import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/note_model.dart';
import '../../services/note_service.dart';
import 'add_edit_note_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NoteService _noteService = NoteService();

  List<NoteModel> _notes = [];
  List<NoteModel> _reminders = [];
  List<NoteModel> _todos = [];

  String _searchQuery = '';
  bool _isLoading = false;
  String _selectedCategory = 'Tümü';
  String _selectedPriority = 'Tümü';
  bool _showCompleted = true;
  String _sortBy = 'Oluşturma Tarihi';
  bool _sortAscending = false;

  final List<String> _categories = [
    'Tümü',
    'İş Geliştirme',
    'Hatırlatıcı',
    'Yapılacaklar',
    'Kişisel',
    'Proje'
  ];
  final List<String> _priorities = ['Tümü', 'Düşük', 'Orta', 'Yüksek', 'Acil'];
  final List<String> _sortOptions = [
    'Oluşturma Tarihi',
    'Başlık',
    'Öncelik',
    'Son Tarih'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _noteService.getNotes();
      setState(() {
        _notes = notes
            .where((note) =>
                note.category != 'Hatırlatıcı' &&
                note.category != 'Yapılacaklar')
            .toList();
        _reminders =
            notes.where((note) => note.category == 'Hatırlatıcı').toList();
        _todos =
            notes.where((note) => note.category == 'Yapılacaklar').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notlar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    var filtered = notes.where((note) {
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.encryptedContent
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'Tümü' || note.category == _selectedCategory;

      final matchesPriority = _selectedPriority == 'Tümü' ||
          note.priority.text == _selectedPriority;

      final matchesStatus =
          _showCompleted || note.status != NoteStatus.completed;

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesStatus;
    }).toList();

    // Sıralama
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'Başlık':
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 'Öncelik':
          final priorityOrder = {
            NotePriority.urgent: 0,
            NotePriority.high: 1,
            NotePriority.medium: 2,
            NotePriority.low: 3,
          };
          comparison = (priorityOrder[a.priority] ?? 3)
              .compareTo(priorityOrder[b.priority] ?? 3);
          break;
        case 'Son Tarih':
          if (a.deadline == null && b.deadline == null) {
            comparison = 0;
          } else if (a.deadline == null) {
            comparison = 1;
          } else if (b.deadline == null) {
            comparison = -1;
          } else {
            comparison = a.deadline!.compareTo(b.deadline!);
          }
          break;
        case 'Oluşturma Tarihi':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _toggleNoteStatus(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(
        status: note.status == NoteStatus.completed
            ? NoteStatus.active
            : NoteStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _noteService.addOrUpdateNote(updatedNote);
      _loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedNote.status == NoteStatus.completed
                  ? 'Görev tamamlandı! ✅'
                  : 'Görev yeniden açıldı! 📝',
            ),
            backgroundColor: updatedNote.status == NoteStatus.completed
                ? Colors.green
                : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content:
            Text('${note.title} notunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _noteService.deleteNote(note.id);
        _loadNotes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not başarıyla silindi! 🗑️'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openAddEditNote({NoteModel? note, String? defaultCategory}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditNotePage(
          note: note,
          userId: 'current_user_id', // AuthProvider'dan alınacak
          defaultCategory: defaultCategory,
        ),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  void _showQuickAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddNoteModal(
        onSaved: () {
          Navigator.pop(context);
          _loadNotes();
        },
        defaultCategory: _tabController.index == 0
            ? 'İş Geliştirme'
            : _tabController.index == 1
                ? 'Hatırlatıcı'
                : 'Yapılacaklar',
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Kategori filtresi
          _buildFilterChip(
            label: _selectedCategory,
            icon: Icons.category,
            onTap: () => _showCategoryFilter(),
          ),
          const SizedBox(width: 8),

          // Öncelik filtresi
          _buildFilterChip(
            label: _selectedPriority,
            icon: Icons.priority_high,
            onTap: () => _showPriorityFilter(),
          ),
          const SizedBox(width: 8),

          // Durum filtresi
          _buildFilterChip(
            label: _showCompleted ? 'Tümü' : 'Aktif',
            icon: _showCompleted ? Icons.visibility : Icons.visibility_off,
            onTap: () => setState(() => _showCompleted = !_showCompleted),
          ),
          const SizedBox(width: 8),

          // Sıralama filtresi
          _buildFilterChip(
            label: _sortBy,
            icon: _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            onTap: () => _showSortFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFF1A73E8).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A73E8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Öncelik Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPriority = priority);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sıralama Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((sort) {
                final isSelected = _sortBy == sort;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortBy = sort);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sort,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Sıralama Yönü:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    setState(() => _sortAscending = true);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _sortAscending
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 16,
                          color: _sortAscending ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Artan',
                          style: TextStyle(
                            color:
                                _sortAscending ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _sortAscending = false);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_sortAscending
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color:
                              !_sortAscending ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Azalan',
                          style: TextStyle(
                            color:
                                !_sortAscending ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Notlarda ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A73E8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF1A73E8)),
              onPressed: () => _showAdvancedFilters(),
              tooltip: 'Gelişmiş Filtreler',
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gelişmiş Filtreler 🔍',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kategori seçimi
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Öncelik seçimi
            const Text(
              'Öncelik',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPriority = priority),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Durum toggle
            Row(
              children: [
                const Text(
                  'Tamamlanan görevleri göster',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _showCompleted,
                  onChanged: (value) => setState(() => _showCompleted = value),
                  activeColor: const Color(0xFF1A73E8),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Uygula ve Temizle butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'Tümü';
                        _selectedPriority = 'Tümü';
                        _showCompleted = true;
                        _searchQuery = '';
                      });
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Temizle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Uygula'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAddEditNote(note: note),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: note.priority.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      note.priority.icon,
                      size: 16,
                      color: note.priority.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: note.status == NoteStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(note.category)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              color: _getCategoryColor(note.category),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: note.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.status.text,
                      style: TextStyle(
                        color: note.status.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (note.encryptedContent.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.encryptedContent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(note.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (note.deadline != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.event,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd.MM.yyyy').format(note.deadline!),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.category == 'Yapılacaklar')
                        IconButton(
                          icon: Icon(
                            note.status == NoteStatus.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: note.status == NoteStatus.completed
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => _toggleNoteStatus(note),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _deleteNote(note),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openAddEditNote(
              defaultCategory: _tabController.index == 0
                  ? 'İş Geliştirme'
                  : _tabController.index == 1
                      ? 'Hatırlatıcı'
                      : 'Yapılacaklar',
            ),
            icon: const Icon(Icons.add),
            label: const Text('İlk Notunu Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(
      List<NoteModel> notes, String emptyMessage, IconData emptyIcon) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Notlar yükleniyor... 📝',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final filteredNotes = _filterNotes(notes);

    if (filteredNotes.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon);
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      color: const Color(0xFF1A73E8),
      child: ListView.builder(
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index]),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'İş Geliştirme':
        return Colors.blue;
      case 'Hatırlatıcı':
        return Colors.orange;
      case 'Yapılacaklar':
        return Colors.green;
      case 'Kişisel':
        return Colors.purple;
      case 'Proje':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FC),
        appBar: AppBar(
          title: const Text(
            'Kişisel Planlayıcı 📋',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1A73E8),
            labelColor: const Color(0xFF1A73E8),
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: '🗒️ Notlar'),
              Tab(text: '⏰ Hatırlatıcılar'),
              Tab(text: '✅ Yapılacaklar'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotesList(
                    _notes,
                    'Henüz not eklenmemiş.\nIlk notunuzu oluşturun! 📝',
                    Icons.note_add,
                  ),
                  _buildNotesList(
                    _reminders,
                    'Henüz hatırlatıcı eklenmemiş.\nÖnemli görevlerinizi unutmayın! ⏰',
                    Icons.notification_add,
                  ),
                  _buildNotesList(
                    _todos,
                    'Henüz yapılacak eklenmemiş.\nGörevlerinizi organize edin! ✅',
                    Icons.playlist_add,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.8),
              onPressed: () => _openAddEditNote(
                defaultCategory: _tabController.index == 0
                    ? 'İş Geliştirme'
                    : _tabController.index == 1
                        ? 'Hatırlatıcı'
                        : 'Yapılacaklar',
              ),
              heroTag: "detailed_add",
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              backgroundColor: const Color(0xFF1A73E8),
              onPressed: _showQuickAddModal,
              heroTag: "quick_add",
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAddNoteModal extends StatefulWidget {
  final VoidCallback onSaved;
  final String defaultCategory;

  const QuickAddNoteModal({
    Key? key,
    required this.onSaved,
    required this.defaultCategory,
  }) : super(key: key);

  @override
  State<QuickAddNoteModal> createState() => _QuickAddNoteModalState();
}

class _QuickAddNoteModalState extends State<QuickAddNoteModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _category = '';
  NotePriority _priority = NotePriority.medium;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.defaultCategory;
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
      final now = DateTime.now();
      final note = NoteModel(
        id: now.microsecondsSinceEpoch.toString(),
        userId: 'current_user_id', // AuthProvider'dan alınacak
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: now,
        updatedAt: now,
        status: NoteStatus.pending,
        priority: _priority,
        category: _category,
        deadline: _deadline,
        color: 'blue',
      );

      await NoteService().addOrUpdateNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not başarıyla oluşturuldu! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Color(0xFF1A73E8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Hızlı Not Ekle ⚡',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Başlık
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Başlık *',
                  hintText: 'Not başlığını girin',
                  prefixIcon: const Icon(Icons.title, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: const Color(0xFFF5F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // İçerik
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'İçerik',
                  hintText: 'Not içeriğini yazın...',
                  prefixIcon:
                      const Icon(Icons.description, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: const Color(0xFFF5F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kategori ve Öncelik
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: const Icon(Icons.category,
                            color: Color(0xFF1A73E8)),
                        filled: true,
                        fillColor: const Color(0xFFF5F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'İş Geliştirme',
                            child: Text('📊 İş Geliştirme')),
                        DropdownMenuItem(
                            value: 'Hatırlatıcı', child: Text('⏰ Hatırlatıcı')),
                        DropdownMenuItem(
                            value: 'Yapılacaklar',
                            child: Text('✅ Yapılacaklar')),
                        DropdownMenuItem(
                            value: 'Kişisel', child: Text('👤 Kişisel')),
                        DropdownMenuItem(
                            value: 'Proje', child: Text('🎯 Proje')),
                      ],
                      onChanged: (value) =>
                          setState(() => _category = value ?? 'İş Geliştirme'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<NotePriority>(
                      value: _priority,
                      decoration: InputDecoration(
                        labelText: 'Öncelik',
                        prefixIcon:
                            Icon(_priority.icon, color: _priority.color),
                        filled: true,
                        fillColor: const Color(0xFFF5F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: NotePriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Icon(priority.icon,
                                  color: priority.color, size: 16),
                              const SizedBox(width: 8),
                              Text(priority.text),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(
                          () => _priority = value ?? NotePriority.medium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tarih seçici
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: const Color(0xFF1A73E8),
                              ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _deadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _deadline != null
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline != null
                              ? DateFormat('dd MMMM yyyy', 'tr_TR')
                                  .format(_deadline!)
                              : 'Son tarih seçin (opsiyonel)',
                          style: TextStyle(
                            color: _deadline != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: _deadline != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setState(() => _deadline = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cleaned for Web Build by Cursor
