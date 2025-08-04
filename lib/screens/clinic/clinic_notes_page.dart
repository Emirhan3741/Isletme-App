import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicNotesPage extends StatefulWidget {
  const ClinicNotesPage({super.key});

  @override
  State<ClinicNotesPage> createState() => _ClinicNotesPageState();
}

class _ClinicNotesPageState extends State<ClinicNotesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicNotesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _notes =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Notları yüklerken hata: $e');
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get filteredNotes {
    List<Map<String, dynamic>> filtered = _notes;

    if (_selectedFilter == 'tamamlandi') {
      filtered = filtered.where((note) => note['isCompleted'] == true).toList();
    } else if (_selectedFilter == 'bekliyor') {
      filtered =
          filtered.where((note) => note['isCompleted'] == false).toList();
    } else if (_selectedFilter == 'onemli') {
      filtered =
          filtered.where((note) => note['priority'] == 'yuksek').toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((note) =>
              (note['title'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (note['description'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Başlık ve yeni not butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notlar (To-Do List)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddNoteDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni Not',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // İstatistik kartları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Toplam Not', _notes.length, Colors.blue, Icons.note)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard(
                        'Tamamlanan',
                        _getCompletedNotesCount(),
                        Colors.green,
                        Icons.check_circle)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard('Bekleyen', _getPendingNotesCount(),
                        Colors.orange, Icons.pending)),
              ],
            ),
          ),

          // Arama ve filtreler
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Not ara (Başlık, açıklama)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('Tümü', 'tumu'),
                    _buildFilterChip('Bekleyen', 'bekliyor'),
                    _buildFilterChip('Tamamlanan', 'tamamlandi'),
                    _buildFilterChip('Önemli', 'onemli'),
                  ],
                ),
              ],
            ),
          ),

          // Notlar listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _buildNoteCard(note);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(title,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = value),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
        checkmarkColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final isCompleted = note['isCompleted'] ?? false;
    final priority = note['priority'] ?? 'normal';
    final priorityColor = _getPriorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) =>
              _toggleNoteCompletion(note['id'], value ?? false),
          activeColor: Colors.green,
        ),
        title: Text(
          note['title'] ?? 'Başlık yok',
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note['description'] != null && note['description'].isNotEmpty)
              Text(
                note['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: priorityColor),
                  ),
                  child: Text(
                    _getPriorityLabel(priority),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(note['createdAt']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditNoteDialog(note),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNote(note['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Henüz not eklenmemiş',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('İlk notunuzu eklemek için "Yeni Not" butonuna tıklayın',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'yuksek':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'dusuk':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'yuksek':
        return 'Yüksek';
      case 'orta':
        return 'Orta';
      case 'dusuk':
        return 'Düşük';
      default:
        return 'Normal';
    }
  }

  int _getCompletedNotesCount() {
    return _notes.where((note) => note['isCompleted'] == true).length;
  }

  int _getPendingNotesCount() {
    return _notes.where((note) => note['isCompleted'] == false).length;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tarih yok';
    DateTime dateTime =
        date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  Future<void> _toggleNoteCompletion(String noteId, bool isCompleted) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.clinicNotesCollection)
          .doc(noteId)
          .update({'isCompleted': isCompleted});

      _loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditNoteDialog(onSaved: _loadNotes),
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => _AddEditNoteDialog(note: note, onSaved: _loadNotes),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Sil'),
        content: const Text('Bu notu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
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
            .collection(AppConstants.clinicNotesCollection)
            .doc(noteId)
            .delete();

        _loadNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Not silindi'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Not ekleme/düzenleme dialog'u
class _AddEditNoteDialog extends StatefulWidget {
  final Map<String, dynamic>? note;
  final VoidCallback onSaved;

  const _AddEditNoteDialog({this.note, required this.onSaved});

  @override
  State<_AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<_AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPriority = 'normal';
  bool _isCompleted = false;
  bool _isLoading = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadNoteData();
    }
  }

  void _loadNoteData() {
    final note = widget.note!;
    _titleController.text = note['title'] ?? '';
    _descriptionController.text = note['description'] ?? '';
    _selectedPriority = note['priority'] ?? 'normal';
    _isCompleted = note['isCompleted'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.note_add, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(isEditing ? 'Not Düzenle' : 'Yeni Not',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),

              // Başlık
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Başlık *', border: OutlineInputBorder()),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Başlık gerekli' : null,
              ),

              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Açıklama', border: OutlineInputBorder()),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Öncelik
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                    labelText: 'Öncelik', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'dusuk', child: Text('Düşük')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'orta', child: Text('Orta')),
                  DropdownMenuItem(value: 'yuksek', child: Text('Yüksek')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedPriority = value!),
              ),

              const SizedBox(height: 16),

              // Tamamlandı durumu
              CheckboxListTile(
                title: const Text('Tamamlandı'),
                value: _isCompleted,
                onChanged: (value) =>
                    setState(() => _isCompleted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 20),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditing ? 'Güncelle' : 'Kaydet'),
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

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final noteData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority,
        'isCompleted': _isCompleted,
        'updatedAt': Timestamp.now(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicNotesCollection)
            .doc(widget.note!['id'])
            .update(noteData);
      } else {
        noteData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicNotesCollection)
            .add(noteData);
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? 'Not güncellendi' : 'Not eklendi'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
