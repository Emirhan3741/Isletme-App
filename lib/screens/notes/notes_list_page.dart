import 'package:flutter/material.dart';
import 'package:randevu_erp/models/note_model.dart';
import 'package:randevu_erp/services/note_service.dart';
import 'add_edit_note_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({Key? key}) : super(key: key);

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NoteService _noteService = NoteService();
  List<NoteModel> _notes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notes = await _noteService.getNotes();
    setState(() {
      _notes = notes;
    });
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    if (_searchQuery.isEmpty) return notes;
    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _filterNotes(_notes);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditNotePage()),
              );
              if (result == true) _fetchNotes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search notes',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.primaries[note.color % Colors.primaries.length],
                    child: const Icon(Icons.note, color: Colors.white),
                  ),
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(DateFormat('dd.MM.yyyy').format(note.createdAt)),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditNotePage(note: note),
                      ),
                    );
                    if (result == true) _fetchNotes();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// Cleaned for Web Build by Cursor