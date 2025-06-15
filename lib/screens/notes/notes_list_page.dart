import 'package:flutter/material.dart';
import 'package:randevu_erp/models/note_model.dart';
import 'package:randevu_erp/services/note_service.dart';

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
      appBar: AppBar(title: const Text('Notes')),
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
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    width: 16,
                    height: 16,
                    color: Colors.primaries[note.color % Colors.primaries.length],
                  ),
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