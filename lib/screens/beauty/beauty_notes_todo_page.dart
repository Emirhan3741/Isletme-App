import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:locapo/core/constants/app_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyNotesTodoPage extends StatefulWidget {
  const BeautyNotesTodoPage({super.key});

  @override
  State<BeautyNotesTodoPage> createState() => _BeautyNotesTodoPageState();
}

class _BeautyNotesTodoPageState extends State<BeautyNotesTodoPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Local data
  final List<Map<String, dynamic>> _notes = [];
  final List<Map<String, dynamic>> _todos = [];
  final List<Map<String, dynamic>> _reminders = [];

  // Firebase data
  final List<Map<String, dynamic>> _firebaseTodos = [];
  final List<Map<String, dynamic>> _firebaseReminders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _loadFirebaseTodos();
      await _loadFirebaseReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context)!.tasksLoadError}: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadFirebaseTodos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .get();

    _firebaseTodos.clear();
    for (var doc in querySnapshot.docs) {
      _firebaseTodos.add({
        'id': doc.id,
        ...doc.data(),
      });
    }
    setState(() {});
  }

  Future<void> _loadFirebaseReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .get();

    _firebaseReminders.clear();
    for (var doc in querySnapshot.docs) {
      _firebaseReminders.add({
        'id': doc.id,
        ...doc.data(),
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notesAndTasksTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                text: AppLocalizations.of(context)!.notesTab,
                icon: const Icon(Icons.note_outlined)),
            Tab(
                text: AppLocalizations.of(context)!.todosTab,
                icon: const Icon(Icons.task_outlined)),
            Tab(
                text: AppLocalizations.of(context)!.remindersTab,
                icon: const Icon(Icons.notifications_outlined)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
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
        child: const Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.addNewItem,
      ),
    );
  }

  Widget _buildNotesTab() {
    final filteredNotes = _notes.where((note) {
      return _searchQuery.isEmpty ||
          note['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note['description']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return filteredNotes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  AppLocalizations.of(context)!.noNotesYet,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return _NoteCard(
                note: note,
                onTap: () => _showNoteDetails(note),
                onEdit: () => _editNote(note),
                onDelete: () => _deleteNote(note['id']),
              );
            },
          );
  }

  Widget _buildTodosTab() {
    final allTodos = _firebaseTodos.isNotEmpty ? _firebaseTodos : _todos;
    final filteredTodos = allTodos.where((todo) {
      return _searchQuery.isEmpty ||
          todo['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          todo['description']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return filteredTodos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.task_outlined,
                  size: 64,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  AppLocalizations.of(context)!.noTasksFound,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: filteredTodos.length,
            itemBuilder: (context, index) {
              final todo = filteredTodos[index];
              return _TodoCard(
                todo: todo,
                onTap: () => _showTodoDetails(todo),
                onToggle: () => _toggleTodo(todo),
                onEdit: () => _editTodo(todo),
                onDelete: () => _deleteTodo(todo['id']),
              );
            },
          );
  }

  Widget _buildRemindersTab() {
    final allReminders =
        _firebaseReminders.isNotEmpty ? _firebaseReminders : _reminders;
    final filteredReminders = allReminders.where((reminder) {
      return _searchQuery.isEmpty ||
          reminder['title']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          reminder['description']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return filteredReminders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 64,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  AppLocalizations.of(context)!.noRemindersFound,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: filteredReminders.length,
            itemBuilder: (context, index) {
              final reminder = filteredReminders[index];
              return _ReminderCard(
                reminder: reminder,
                onTap: () => _showReminderDetails(reminder),
                onEdit: () => _editReminder(reminder),
                onDelete: () => _deleteReminder(reminder['id']),
              );
            },
          );
  }

  void _showAddDialog() {
    switch (_tabController.index) {
      case 0:
        _showNoteDialog();
        break;
      case 1:
        _showTodoDialog();
        break;
      case 2:
        _showReminderDialog();
        break;
    }
  }

  // Note methods
  void _showNoteDialog({Map<String, dynamic>? initialData}) {
    final titleController =
        TextEditingController(text: initialData?['title'] ?? '');
    final descriptionController =
        TextEditingController(text: initialData?['description'] ?? '');
    String selectedCategory = initialData?['category'] ?? 'general';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialData != null
            ? AppLocalizations.of(context)!.editNoteTitle
            : AppLocalizations.of(context)!.newNoteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.titleLabel} *',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.titleRequiredError;
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.descriptionLabel} *',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.descriptionRequiredError;
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.categoryLabel} *',
              ),
              items: [
                DropdownMenuItem(
                    value: 'general',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryGeneral)),
                DropdownMenuItem(
                    value: 'business',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryBusiness)),
                DropdownMenuItem(
                    value: 'personal',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryPersonal)),
                DropdownMenuItem(
                    value: 'customer',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryCustomer)),
                DropdownMenuItem(
                    value: 'appointment',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryAppointment)),
                DropdownMenuItem(
                    value: 'payment',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryPayment)),
                DropdownMenuItem(
                    value: 'stock',
                    child:
                        Text(AppLocalizations.of(context)!.noteCategoryStock)),
                DropdownMenuItem(
                    value: 'marketing',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryMarketing)),
              ],
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                final note = {
                  'id': initialData?['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'category': selectedCategory,
                  'createdAt': initialData?['createdAt'] ??
                      DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                if (initialData != null) {
                  _updateNote(note);
                } else {
                  _addNote(note);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text(initialData != null
                ? AppLocalizations.of(context)!.saveButton
                : AppLocalizations.of(context)!.addNewItem),
          ),
        ],
      ),
    );
  }

  void _addNote(Map<String, dynamic> note) {
    setState(() {
      _notes.add(note);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.noteAddedSuccess),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _updateNote(Map<String, dynamic> note) {
    setState(() {
      final index = _notes.indexWhere((n) => n['id'] == note['id']);
      if (index != -1) {
        _notes[index] = note;
      }
    });
  }

  void _deleteNote(String id) {
    setState(() {
      _notes.removeWhere((note) => note['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.noteDeletedSuccess),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    _showNoteDialog(initialData: note);
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note['title']),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(note['description']),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
                "${AppLocalizations.of(context)!.categoryLabel}: ${note['category']}"),
            Text(
                "${AppLocalizations.of(context)!.priorityLabel}: ${_getPriorityText(note['priority'])}"),
            Text(
                "${AppLocalizations.of(context)!.creationDateLabel}: ${_formatDateTime(note['createdAt'])}"),
            if (note['tags'] != null && note['tags'].isNotEmpty)
              Text(
                  "${AppLocalizations.of(context)!.tagsLabel}: ${note['tags'].join(', ')}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      ),
    );
  }

  // Todo methods
  void _showTodoDialog({Map<String, dynamic>? initialData}) {
    final titleController =
        TextEditingController(text: initialData?['title'] ?? '');
    final descriptionController =
        TextEditingController(text: initialData?['description'] ?? '');
    String selectedCategory = initialData?['category'] ?? 'general';
    String selectedPriority = initialData?['priority'] ?? 'medium';
    DateTime? selectedDueDate = initialData?['dueDate'] != null
        ? DateTime.parse(initialData!['dueDate'])
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialData != null
            ? AppLocalizations.of(context)!.editButton
            : AppLocalizations.of(context)!.addNewItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.titleLabel} *',
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.descriptionLabel} *',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.categoryLabel} *',
              ),
              items: [
                DropdownMenuItem(
                    value: 'general',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryGeneral)),
                DropdownMenuItem(
                    value: 'business',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryBusiness)),
                DropdownMenuItem(
                    value: 'personal',
                    child: Text(
                        AppLocalizations.of(context)!.noteCategoryPersonal)),
              ],
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.priorityLabel} *',
              ),
              items: [
                DropdownMenuItem(
                    value: 'high',
                    child: Text(AppLocalizations.of(context)!.priorityHigh)),
                DropdownMenuItem(
                    value: 'medium',
                    child: Text(AppLocalizations.of(context)!.priorityMedium)),
                DropdownMenuItem(
                    value: 'low',
                    child: Text(AppLocalizations.of(context)!.priorityLow)),
              ],
              onChanged: (value) {
                selectedPriority = value!;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            ListTile(
              title: Text(AppLocalizations.of(context)!.dueDateLabel),
              subtitle: Text(selectedDueDate != null
                  ? DateFormat('dd/MM/yyyy').format(selectedDueDate!)
                  : AppLocalizations.of(context)!.addNewItem),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedDueDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                final todo = {
                  'id': initialData?['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'category': selectedCategory,
                  'priority': selectedPriority,
                  'dueDate': selectedDueDate?.toIso8601String(),
                  'isCompleted': initialData?['isCompleted'] ?? false,
                  'createdAt': initialData?['createdAt'] ??
                      DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                if (initialData != null) {
                  _updateTodo(todo);
                } else {
                  _addTodo(todo);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text(initialData != null
                ? AppLocalizations.of(context)!.saveButton
                : AppLocalizations.of(context)!.addNewItem),
          ),
        ],
      ),
    );
  }

  void _addTodo(Map<String, dynamic> todo) {
    setState(() {
      _todos.add(todo);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.taskAddedSuccess),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _updateTodo(Map<String, dynamic> todo) {
    setState(() {
      final index = _todos.indexWhere((t) => t['id'] == todo['id']);
      if (index != -1) {
        _todos[index] = todo;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.taskUpdatedSuccess),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  Future<void> _toggleTodo(Map<String, dynamic> todo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentStatus = todo['isCompleted'] ?? false;
      final newStatus = !currentStatus;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .doc(todo['id'])
          .update({'isCompleted': newStatus});

      setState(() {
        todo['isCompleted'] = newStatus;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus
              ? AppLocalizations.of(context)!.taskMarkedCompleted
              : AppLocalizations.of(context)!.taskMarkedPending),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.taskStatusUpdateError}: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('todos')
            .doc(id)
            .delete();
      }

      setState(() {
        _todos.removeWhere((todo) => todo['id'] == id);
        _firebaseTodos.removeWhere((todo) => todo['id'] == id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskDeletedSuccess),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskDeletedSuccess),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _editTodo(Map<String, dynamic> todo) {
    _showTodoDialog(initialData: todo);
  }

  void _showTodoDetails(Map<String, dynamic> todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(todo['title']),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(todo['description']),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
                "${AppLocalizations.of(context)!.categoryLabel}: ${todo['category']}"),
            Text(
                "${AppLocalizations.of(context)!.priorityLabel}: ${_getPriorityText(todo['priority'])}"),
            Text(
                "${AppLocalizations.of(context)!.dueDateLabel}: ${_formatDateTime(todo['dueDate'])}"),
            if (todo['assignedTo'] != null)
              Text(
                  "${AppLocalizations.of(context)!.assigneeLabel}: ${todo['assignedTo']}"),
            Text(
                "${AppLocalizations.of(context)!.statusLabel}: ${todo['isCompleted'] ? AppLocalizations.of(context)!.statusCompleted : AppLocalizations.of(context)!.statusPending}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      ),
    );
  }

  // Reminder methods
  void _showReminderDialog({Map<String, dynamic>? initialData}) {
    final titleController =
        TextEditingController(text: initialData?['title'] ?? '');
    final descriptionController =
        TextEditingController(text: initialData?['description'] ?? '');
    String selectedType = initialData?['type'] ?? 'general';
    String selectedRepeat = initialData?['repeatType'] ?? 'none';
    DateTime selectedDateTime = initialData?['reminderTime'] != null
        ? DateTime.parse(initialData!['reminderTime'])
        : DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialData != null
            ? AppLocalizations.of(context)!.editReminderTitle
            : AppLocalizations.of(context)!.newReminderTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              initialData != null
                  ? AppLocalizations.of(context)!.editReminderSubtitle
                  : AppLocalizations.of(context)!.newReminderSubtitle,
              style: const TextStyle(
                  fontSize: 14, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.titleLabel} *',
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context)!.descriptionLabel} *',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.typeLabel} *',
              ),
              items: [
                DropdownMenuItem(
                    value: 'general',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypeGeneral)),
                DropdownMenuItem(
                    value: 'payment',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypePayment)),
                DropdownMenuItem(
                    value: 'customer',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypeCustomer)),
                DropdownMenuItem(
                    value: 'maintenance',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypeMaintenance)),
                DropdownMenuItem(
                    value: 'appointment',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypeAppointment)),
                DropdownMenuItem(
                    value: 'inventory',
                    child: Text(
                        AppLocalizations.of(context)!.reminderTypeInventory)),
                DropdownMenuItem(
                    value: 'other',
                    child:
                        Text(AppLocalizations.of(context)!.reminderTypeOther)),
              ],
              onChanged: (value) {
                selectedType = value!;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            DropdownButtonFormField<String>(
              value: selectedRepeat,
              decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.repeatLabel} *',
              ),
              items: [
                DropdownMenuItem(
                    value: 'none',
                    child: Text(AppLocalizations.of(context)!.repeatNone)),
                DropdownMenuItem(
                    value: 'daily',
                    child: Text(AppLocalizations.of(context)!.repeatDaily)),
                DropdownMenuItem(
                    value: 'weekly',
                    child: Text(AppLocalizations.of(context)!.repeatWeekly)),
                DropdownMenuItem(
                    value: 'monthly',
                    child: Text(AppLocalizations.of(context)!.repeatMonthly)),
                DropdownMenuItem(
                    value: 'yearly',
                    child: Text(AppLocalizations.of(context)!.repeatYearly)),
              ],
              onChanged: (value) {
                selectedRepeat = value!;
              },
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            ListTile(
              title: Text(AppLocalizations.of(context)!.reminderTimeLabel),
              subtitle: Text(
                '${AppLocalizations.of(context)!.reminderTimeLabel}: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime)}',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  );
                  if (time != null && mounted) {
                    setState(() {
                      selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.reminderActiveLabel),
              value: initialData?['isActive'] ?? true,
              onChanged: (value) {
                // Handle active state
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                final reminder = {
                  'id': initialData?['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'type': selectedType,
                  'repeatType': selectedRepeat,
                  'reminderTime': selectedDateTime.toIso8601String(),
                  'isActive': initialData?['isActive'] ?? true,
                  'createdAt': initialData?['createdAt'] ??
                      DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                };

                if (initialData != null) {
                  await _updateReminder(reminder);
                } else {
                  await _addReminder(reminder);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text(initialData != null
                ? AppLocalizations.of(context)!.saveButton
                : AppLocalizations.of(context)!.addNewItem),
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder(Map<String, dynamic> reminder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw Exception(AppLocalizations.of(context)!.userNotLoggedInError);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder['id'])
          .set(reminder);

      setState(() {
        _firebaseReminders.add(reminder);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reminderAddedSuccess),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.reminderSaveError}: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _updateReminder(Map<String, dynamic> reminder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder['id'])
          .update(reminder);

      setState(() {
        final index =
            _firebaseReminders.indexWhere((r) => r['id'] == reminder['id']);
        if (index != -1) {
          _firebaseReminders[index] = reminder;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reminderUpdatedSuccess),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.reminderSaveError}: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(id)
            .delete();
      }

      setState(() {
        _reminders.removeWhere((reminder) => reminder['id'] == id);
        _firebaseReminders.removeWhere((reminder) => reminder['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reminderDeletedSuccess),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.reminderSaveError}: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _editReminder(Map<String, dynamic> reminder) {
    _showReminderDialog(initialData: reminder);
  }

  void _showReminderDetails(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder['title']),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reminder['description']),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
                "${AppLocalizations.of(context)!.reminderTimeLabel}: ${_formatDateTime(reminder['reminderTime'])}"),
            Text(
                "${AppLocalizations.of(context)!.typeLabel}: ${_getReminderTypeText(reminder['type'])}"),
            Text(
                "${AppLocalizations.of(context)!.repeatLabel}: ${_getRepeatTypeText(reminder['repeatType'])}"),
            Text(
                "${AppLocalizations.of(context)!.statusLabel}: ${reminder['isActive'] ? AppLocalizations.of(context)!.statusActive : AppLocalizations.of(context)!.statusPassive}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.closeButton),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getPriorityText(String? priority) {
    switch (priority) {
      case 'high':
        return AppLocalizations.of(context)!.priorityHigh;
      case 'medium':
        return AppLocalizations.of(context)!.priorityMedium;
      case 'low':
        return AppLocalizations.of(context)!.priorityLow;
      default:
        return AppLocalizations.of(context)!.priorityUnspecified;
    }
  }

  String _getReminderTypeText(String? type) {
    switch (type) {
      case 'payment':
        return AppLocalizations.of(context)!.reminderTypePayment;
      case 'customer':
        return AppLocalizations.of(context)!.reminderTypeCustomer;
      case 'maintenance':
        return AppLocalizations.of(context)!.reminderTypeMaintenance;
      case 'appointment':
        return AppLocalizations.of(context)!.reminderTypeAppointment;
      case 'inventory':
        return AppLocalizations.of(context)!.reminderTypeInventory;
      case 'other':
        return AppLocalizations.of(context)!.reminderTypeOther;
      default:
        return AppLocalizations.of(context)!.reminderTypeGeneral;
    }
  }

  String _getRepeatTypeText(String? repeatType) {
    switch (repeatType) {
      case 'none':
        return AppLocalizations.of(context)!.repeatNone;
      case 'daily':
        return AppLocalizations.of(context)!.repeatDaily;
      case 'weekly':
        return AppLocalizations.of(context)!.repeatWeekly;
      case 'monthly':
        return AppLocalizations.of(context)!.repeatMonthly;
      case 'yearly':
        return AppLocalizations.of(context)!.repeatYearly;
      default:
        return AppLocalizations.of(context)!.repeatNone;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}

// Card widgets
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        title: Text(note['title']),
        subtitle: Text(
          note['description'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(AppLocalizations.of(context)!.editButton),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(AppLocalizations.of(context)!.deleteButton,
                  style: const TextStyle(color: AppConstants.errorColor)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final Map<String, dynamic> todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = todo['isCompleted'] ?? false;
    final dueDate =
        todo['dueDate'] != null ? DateTime.parse(todo['dueDate']) : null;
    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now()) && !isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) => onToggle(),
        ),
        title: Text(
          todo['title'],
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (dueDate != null)
              Text(
                isOverdue
                    ? AppLocalizations.of(context)!.overdueStatus
                    : DateFormat('dd/MM/yyyy').format(dueDate),
                style: TextStyle(
                  color: isOverdue
                      ? AppConstants.errorColor
                      : AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(AppLocalizations.of(context)!.editButton),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(AppLocalizations.of(context)!.deleteButton,
                  style: const TextStyle(color: AppConstants.errorColor)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final reminderTime = DateTime.parse(reminder['reminderTime']);
    final isActive = reminder['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: Icon(
          Icons.notifications,
          color:
              isActive ? AppConstants.primaryColor : AppConstants.textSecondary,
        ),
        title: Text(reminder['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder['description'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(reminderTime),
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(AppLocalizations.of(context)!.editButton),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(AppLocalizations.of(context)!.deleteButton,
                  style: const TextStyle(color: AppConstants.errorColor)),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
