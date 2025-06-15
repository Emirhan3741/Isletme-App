import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';

class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({
    super.key,
    this.note,
  });

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final NoteService _noteService = NoteService();

  // Form controllers
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _icerikController = TextEditingController();

  // Form değişkenleri
  String _selectedKategori = NoteCategory.genel;
  int _selectedOnem = NotePriority.orta;
  String _selectedRenk = NoteColors.mavi;
  bool _tamamlandi = false;
  bool _isLoading = false;

  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _icerikController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final note = widget.note!;
      _baslikController.text = note.baslik;
      _icerikController.text = note.icerik;
      _selectedKategori = note.kategori;
      _selectedOnem = note.onem;
      _selectedRenk = note.renk;
      _tamamlandi = note.tamamlandi;
    }
  }

  // Form validasyonu
  String? _validateBaslik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Başlık gereklidir';
    }
    if (value.trim().length < 3) {
      return 'Başlık en az 3 karakter olmalıdır';
    }
    return null;
  }

  // Form gönderimi
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final note = NoteModel(
        id: _isEditMode ? widget.note!.id : '',
        baslik: _baslikController.text.trim(),
        icerik: _icerikController.text.trim(),
        kategori: _selectedKategori,
        tamamlandi: _tamamlandi,
        onem: _selectedOnem,
        renk: _selectedRenk,
        olusturulmaTarihi: _isEditMode 
            ? widget.note!.olusturulmaTarihi 
            : Timestamp.now(),
        kullaniciId: _isEditMode 
            ? widget.note!.kullaniciId 
            : '',
      );

      if (_isEditMode) {
        await _noteService.updateNote(note);
      } else {
        await _noteService.addNote(note);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Not başarıyla güncellendi' 
                : 'Not başarıyla eklendi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Not Düzenle' : 'Yeni Not'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                _isEditMode ? 'Güncelle' : 'Kaydet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              TextFormField(
                controller: _baslikController,
                decoration: const InputDecoration(
                  labelText: 'Başlık *',
                  hintText: 'Not başlığınızı yazın',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _validateBaslik,
              ),
              const SizedBox(height: 16),

              // İçerik
              TextFormField(
                controller: _icerikController,
                decoration: const InputDecoration(
                  labelText: 'İçerik (Opsiyonel)',
                  hintText: 'Not detaylarınızı yazın',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Kategori seçimi
              Text(
                'Kategori *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: NoteCategory.tumKategoriler.map((kategori) {
                  final icon = NoteCategory.kategoriIkonlari[kategori] ?? '📝';
                  return DropdownMenuItem(
                    value: kategori,
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(kategori),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Öncelik seçimi
              Text(
                'Önem Derecesi *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedOnem,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: NotePriority.tumOnemler.map((onem) {
                  final icon = NotePriority.onemIkonlari[onem] ?? '⚪';
                  final name = NotePriority.onemIsimleri[onem] ?? '';
                  return DropdownMenuItem(
                    value: onem,
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOnem = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Renk seçimi
              Text(
                'Renk Etiketi *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: NoteColors.tumRenkler.map((renk) {
                    final color = Color(int.parse(renk.replaceAll('#', '0xFF')));
                    final isSelected = _selectedRenk == renk;
                    final renkAdi = NoteColors.renkIsimleri[renk] ?? '';
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRenk = renk;
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: Colors.black, width: 3)
                              : Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Seçili: ${NoteColors.renkIsimleri[_selectedRenk] ?? ''}',
                  style: TextStyle(
                    color: Color(int.parse(_selectedRenk.replaceAll('#', '0xFF'))),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tamamlandı checkbox'ı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _tamamlandi,
                        onChanged: (value) {
                          setState(() {
                            _tamamlandi = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tamamlandı olarak işaretle',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bu not tamamlanmış bir görev olarak işaretlenecek',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kategori ve öncelik bilgi kartı
              if (!_isEditMode) _buildInfoCard(),
              const SizedBox(height: 16),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditMode ? Icons.update : Icons.save),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Güncelle' : 'Kaydet',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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

  // Bilgi kartı
  Widget _buildInfoCard() {
    final categoryIcon = NoteCategory.kategoriIkonlari[_selectedKategori] ?? '📝';
    final priorityIcon = NotePriority.onemIkonlari[_selectedOnem] ?? '⚪';
    final color = Color(int.parse(_selectedRenk.replaceAll('#', '0xFF')));
    
    return Card(
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Not Önizleme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(categoryIcon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        _selectedKategori,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(priorityIcon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        NotePriority.onemIsimleri[_selectedOnem] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDescription(_selectedKategori),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori açıklaması
  String _getCategoryDescription(String kategori) {
    switch (kategori) {
      case NoteCategory.genel:
        return 'Genel notlar ve hatırlatıcılar';
      case NoteCategory.pazarlama:
        return 'Pazarlama stratejileri ve kampanya notları';
      case NoteCategory.personel:
        return 'Personel yönetimi ve insan kaynakları';
      case NoteCategory.uretim:
        return 'Üretim süreçleri ve operasyonlar';
      case NoteCategory.finans:
        return 'Finansal planlama ve bütçe notları';
      case NoteCategory.musteri:
        return 'Müşteri ilişkileri ve hizmet notları';
      case NoteCategory.tedarik:
        return 'Tedarik zinciri ve satın alma';
      case NoteCategory.kalite:
        return 'Kalite kontrol ve iyileştirme';
      case NoteCategory.teknoloji:
        return 'Teknoloji ve sistem geliştirme';
      case NoteCategory.hukuk:
        return 'Hukuki konular ve mevzuat';
      case NoteCategory.satis:
        return 'Satış stratejileri ve hedefler';
      case NoteCategory.proje:
        return 'Proje yönetimi ve takip';
      default:
        return 'Not kategorisi açıklaması';
    }
  }
}