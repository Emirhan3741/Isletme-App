import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class LawyerNotesPage extends StatefulWidget {
  const LawyerNotesPage({super.key});

  @override
  State<LawyerNotesPage> createState() => _LawyerNotesPageState();
}

class _LawyerNotesPageState extends State<LawyerNotesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<NoteModel> _notes = [];
  List<TodoModel> _todos = [];
  List<ReminderModel> _reminders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final results = await Future.wait([
        _loadNotes(user.uid),
        _loadTodos(user.uid),
        _loadReminders(user.uid),
      ]);

      setState(() {
        _notes = results[0] as List<NoteModel>;
        _todos = results[1] as List<TodoModel>;
        _reminders = results[2] as List<ReminderModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Veri yükleme hatası: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<NoteModel>> _loadNotes(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerNotesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return NoteModel(
        id: doc.id,
        userId: userId,
        baslik: data['baslik'] ?? '',
        icerik: data['icerik'] ?? '',
        kategori: data['kategori'] ?? 'Genel',
        onemliMi: data['onemliMi'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<List<TodoModel>> _loadTodos(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerTodosCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TodoModel(
        id: doc.id,
        userId: userId,
        baslik: data['baslik'] ?? '',
        aciklama: data['aciklama'] ?? '',
        kategori: data['kategori'] ?? 'Genel',
        oncelik: data['oncelik'] ?? 'Normal',
        tamamlandiMi: data['tamamlandiMi'] ?? false,
        bitisTarihi: (data['bitisTarihi'] as Timestamp?)?.toDate(),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<List<ReminderModel>> _loadReminders(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.lawyerRemindersCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('hatirlatmaTarihi', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ReminderModel(
        id: doc.id,
        userId: userId,
        baslik: data['baslik'] ?? '',
        aciklama: data['aciklama'] ?? '',
        hatirlatmaTarihi: (data['hatirlatmaTarihi'] as Timestamp).toDate(),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notlar & Yapılacaklar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: AppConstants.textSecondary,
              indicatorColor: AppConstants.primaryColor,
              tabs: const [
                Tab(text: 'Notlar', icon: Icon(Icons.note, size: 20)),
                Tab(
                    text: 'Yapılacaklar',
                    icon: Icon(Icons.checklist, size: 20)),
                Tab(
                    text: 'Hatırlatıcılar',
                    icon: Icon(Icons.notifications, size: 20)),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotesTab(),
                      _buildTodosTab(),
                      _buildRemindersTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) {
      return _buildEmptyState('Henüz not eklenmemiş', Icons.note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildTodosTab() {
    if (_todos.isEmpty) {
      return _buildEmptyState('Henüz görev eklenmemiş', Icons.checklist);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return _buildTodoCard(todo);
      },
    );
  }

  Widget _buildRemindersTab() {
    if (_reminders.isEmpty) {
      return _buildEmptyState(
          'Henüz hatırlatıcı eklenmemiş', Icons.notifications);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppConstants.textSecondary),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.onemliMi)
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                if (note.onemliMi) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.baslik,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.kategori,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.icerik, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
              style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(TodoModel todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Checkbox(
              value: todo.tamamlandiMi,
              onChanged: (value) => _toggleTodo(todo),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.baslik,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration:
                          todo.tamamlandiMi ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (todo.aciklama.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(todo.aciklama, style: const TextStyle(fontSize: 14)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(todo.oncelik)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          todo.oncelik,
                          style: TextStyle(
                              fontSize: 12,
                              color: _getPriorityColor(todo.oncelik)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (todo.bitisTarihi != null)
                        Text(
                          'Bitiş: ${todo.bitisTarihi!.day}/${todo.bitisTarihi!.month}',
                          style: TextStyle(
                              fontSize: 12, color: AppConstants.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    final isOverdue = reminder.hatirlatmaTarihi.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      color: isOverdue ? Colors.red.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning : Icons.notifications,
                  color: isOverdue ? Colors.red : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder.baslik,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reminder.aciklama, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Hatırlatma: ${reminder.hatirlatmaTarihi.day}/${reminder.hatirlatmaTarihi.month}/${reminder.hatirlatmaTarihi.year} ${reminder.hatirlatmaTarihi.hour}:${reminder.hatirlatmaTarihi.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue ? Colors.red : AppConstants.textSecondary,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek':
        return Colors.red;
      case 'Orta':
        return Colors.orange;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleTodo(TodoModel todo) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerTodosCollection)
          .doc(todo.id)
          .update({'tamamlandiMi': !todo.tamamlandiMi});

      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    final currentTab = _tabController.index;

    if (currentTab == 0) {
      _showAddNoteDialog();
    } else if (currentTab == 1) {
      _showAddTodoDialog();
    } else {
      _showAddReminderDialog();
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddNoteDialog(onNoteAdded: _loadData),
    );
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTodoDialog(onTodoAdded: _loadData),
    );
  }

  void _showAddReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddReminderDialog(onReminderAdded: _loadData),
    );
  }
}

// Veri modelleri
class NoteModel {
  final String id;
  final String userId;
  final String baslik;
  final String icerik;
  final String kategori;
  final bool onemliMi;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.userId,
    required this.baslik,
    required this.icerik,
    required this.kategori,
    required this.onemliMi,
    required this.createdAt,
  });
}

class TodoModel {
  final String id;
  final String userId;
  final String baslik;
  final String aciklama;
  final String kategori;
  final String oncelik;
  final bool tamamlandiMi;
  final DateTime? bitisTarihi;
  final DateTime createdAt;

  TodoModel({
    required this.id,
    required this.userId,
    required this.baslik,
    required this.aciklama,
    required this.kategori,
    required this.oncelik,
    required this.tamamlandiMi,
    this.bitisTarihi,
    required this.createdAt,
  });
}

class ReminderModel {
  final String id;
  final String userId;
  final String baslik;
  final String aciklama;
  final DateTime hatirlatmaTarihi;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.baslik,
    required this.aciklama,
    required this.hatirlatmaTarihi,
    required this.createdAt,
  });
}

// Basit dialog sınıfları
class _AddNoteDialog extends StatefulWidget {
  final VoidCallback onNoteAdded;

  const _AddNoteDialog({required this.onNoteAdded});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Genel';
  bool _isImportant = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Genel',
    'Dava',
    'Müvekkil',
    'Mahkeme',
    'Araştırma'
  ];

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerNotesCollection)
          .add({
        'userId': user.uid,
        'baslik': _titleController.text.trim(),
        'icerik': _contentController.text.trim(),
        'kategori': _selectedCategory,
        'onemliMi': _isImportant,
        'createdAt': Timestamp.now(),
      });

      widget.onNoteAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Not'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'İçerik',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'İçerik gerekli' : null,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Önemli'),
                value: _isImportant,
                onChanged: (value) => setState(() => _isImportant = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveNote,
          child: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _AddTodoDialog extends StatefulWidget {
  final VoidCallback onTodoAdded;

  const _AddTodoDialog({required this.onTodoAdded});

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Genel';
  String _selectedPriority = 'Normal';
  DateTime? _dueDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'Genel',
    'Dava',
    'Müvekkil',
    'Araştırma',
    'Evrak'
  ];
  final List<String> _priorities = ['Normal', 'Orta', 'Yüksek'];

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerTodosCollection)
          .add({
        'userId': user.uid,
        'baslik': _titleController.text.trim(),
        'aciklama': _descriptionController.text.trim(),
        'kategori': _selectedCategory,
        'oncelik': _selectedPriority,
        'tamamlandiMi': false,
        'bitisTarihi': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
        'createdAt': Timestamp.now(),
      });

      widget.onTodoAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Görev'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Görev Başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                            value: category, child: Text(category));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik',
                        border: OutlineInputBorder(),
                      ),
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(
                            value: priority, child: Text(priority));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPriority = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_dueDate == null
                    ? 'Bitiş Tarihi Seç'
                    : 'Bitiş: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _dueDate = date);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveTodo,
          child: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _AddReminderDialog extends StatefulWidget {
  final VoidCallback onReminderAdded;

  const _AddReminderDialog({required this.onReminderAdded});

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  bool _isLoading = false;

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderDate == null || _reminderTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tarih ve saat seçiniz'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reminderDateTime = DateTime(
        _reminderDate!.year,
        _reminderDate!.month,
        _reminderDate!.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.lawyerRemindersCollection)
          .add({
        'userId': user.uid,
        'baslik': _titleController.text.trim(),
        'aciklama': _descriptionController.text.trim(),
        'hatirlatmaTarihi': Timestamp.fromDate(reminderDateTime),
        'createdAt': Timestamp.now(),
      });

      widget.onReminderAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Hatırlatıcı'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Hatırlatıcı Başlığı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_reminderDate == null
                          ? 'Tarih Seç'
                          : '${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _reminderDate = date);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(_reminderTime == null
                          ? 'Saat Seç'
                          : '${_reminderTime!.hour}:${_reminderTime!.minute.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() => _reminderTime = time);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveReminder,
          child: _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
