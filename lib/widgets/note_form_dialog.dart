import 'package:flutter/material.dart';

class NoteFormDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData;

  const NoteFormDialog({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'İş';
  String _selectedPriority = 'medium';
  bool _isImportant = false;

  final List<String> _categories = [
    'İş',
    'Müşteri',
    'Pazarlama',
    'Kişisel',
    'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      _selectedCategory = widget.initialData!['category'] ?? 'İş';
      _selectedPriority = widget.initialData!['priority'] ?? 'medium';
      _isImportant = widget.initialData!['isImportant'] ?? false;
      _tagsController.text =
          (widget.initialData!['tags'] as List<String>?)?.join(', ') ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialData != null ? "Notu Düzenle" : "Yeni Not",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'İçerik *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İçerik gerekli';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Kategori ve Öncelik
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
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
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Düşük')),
                        DropdownMenuItem(value: 'medium', child: Text('Orta')),
                        DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Etiketler
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiketler (virgülle ayırın)',
                  border: OutlineInputBorder(),
                  hintText: 'örn: stok, sipariş, acil',
                ),
              ),

              const SizedBox(height: 16),

              // Önemli checkbox
              CheckboxListTile(
                title: const Text('Önemli olarak işaretle'),
                value: _isImportant,
                onChanged: (value) {
                  setState(() {
                    _isImportant = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveNote,
                    child: Text(
                        widget.initialData != null ? "Güncelle" : "Kaydet"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      widget.onSave({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'tags': tags,
        'isImportant': _isImportant,
      });
    }
  }
}
