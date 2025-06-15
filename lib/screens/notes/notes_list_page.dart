import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/note_service.dart';
import 'add_edit_note_page.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final NoteService _noteService = NoteService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategoryFilter = 'Tümü';
  String _selectedStatusFilter = 'Tümü'; // Tümü, Tamamlandı, Bekliyor
  int _selectedPriorityFilter = 0; // 0: Tümü, 1-5: Öncelik

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Notları filtrele
  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    List<NoteModel> filtered = notes;

    // Kategori filtresi
    if (_selectedCategoryFilter != 'Tümü') {
      filtered = filtered.where((note) => 
        note.kategori == _selectedCategoryFilter).toList();
    }

    // Durum filtresi
    if (_selectedStatusFilter == 'Tamamlandı') {
      filtered = filtered.where((note) => note.tamamlandi).toList();
    } else if (_selectedStatusFilter == 'Bekliyor') {
      filtered = filtered.where((note) => !note.tamamlandi).toList();
    }

    // Öncelik filtresi
    if (_selectedPriorityFilter > 0) {
      filtered = filtered.where((note) => 
        note.onem == _selectedPriorityFilter).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.baslik.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.icerik.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Öncelik ve tamamlanma durumuna göre sırala
    filtered.sort((a, b) {
      // Önce tamamlanmamış notları göster
      if (a.tamamlandi != b.tamamlandi) {
        return a.tamamlandi ? 1 : -1;
      }
      // Sonra öncelik seviyesine göre sırala (yüksek önce)
      if (a.onem != b.onem) {
        return b.onem.compareTo(a.onem);
      }
      // Son olarak oluşturulma tarihine göre (yeni önce)
      return b.olusturulmaTarihi.compareTo(a.olusturulmaTarihi);
    });

    return filtered;
  }

  // Not özeti widget'i
  Widget _buildNotesSummary() {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        _noteService.getTotalNotesCount(),
        _noteService.getCompletedNotesCount(),
        _noteService.getPendingNotesCount(),
      ]),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? [0, 0, 0];
        final totalNotes = counts[0];
        final completedNotes = counts[1];
        final pendingNotes = counts[2];

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not Özeti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Toplam',
                        count: totalNotes,
                        color: Colors.blue,
                        icon: Icons.notes,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Tamamlandı',
                        count: completedNotes,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Bekliyor',
                        count: pendingNotes,
                        color: Colors.orange,
                        icon: Icons.pending,
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

  // Filtre ve arama çubuğu
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Arama çubuğu
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Başlık, içerik veya kategori ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Filtre butonları
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Kategori filtresi
                _buildFilterChip(
                  'Kategori: $_selectedCategoryFilter',
                  onTap: () => _showCategoryFilterDialog(),
                ),
                const SizedBox(width: 8),
                
                // Durum filtresi
                _buildFilterChip(
                  'Durum: $_selectedStatusFilter',
                  onTap: () => _showStatusFilterDialog(),
                ),
                const SizedBox(width: 8),
                
                // Öncelik filtresi
                _buildFilterChip(
                  'Öncelik: ${_selectedPriorityFilter == 0 ? 'Tümü' : NotePriority.onemIsimleri[_selectedPriorityFilter]}',
                  onTap: () => _showPriorityFilterDialog(),
                ),
                const SizedBox(width: 8),
                
                // Filtreleri temizle
                if (_selectedCategoryFilter != 'Tümü' || 
                    _selectedStatusFilter != 'Tümü' || 
                    _selectedPriorityFilter != 0 ||
                    _searchQuery.isNotEmpty)
                  _buildFilterChip(
                    'Temizle',
                    onTap: () => _clearFilters(),
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filtre chip widget'i
  Widget _buildFilterChip(String label, {required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.1),
          border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color ?? Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Kategori filtre dialog'u
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: ['Tümü', ...NoteCategory.tumKategoriler].map((category) {
              final icon = category == 'Tümü' 
                  ? '📋' 
                  : NoteCategory.kategoriIkonlari[category] ?? '📝';
              
              return ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 20)),
                title: Text(category),
                selected: _selectedCategoryFilter == category,
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = category;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Durum filtre dialog'u
  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Tümü', 'Tamamlandı', 'Bekliyor'].map((status) {
            IconData icon;
            Color color;
            switch (status) {
              case 'Tamamlandı':
                icon = Icons.check_circle;
                color = Colors.green;
                break;
              case 'Bekliyor':
                icon = Icons.pending;
                color = Colors.orange;
                break;
              default:
                icon = Icons.list;
                color = Colors.blue;
            }
            
            return ListTile(
              leading: Icon(icon, color: color),
              title: Text(status),
              selected: _selectedStatusFilter == status,
              onTap: () {
                setState(() {
                  _selectedStatusFilter = status;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Öncelik filtre dialog'u
  void _showPriorityFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öncelik Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('📋', style: TextStyle(fontSize: 20)),
              title: const Text('Tümü'),
              selected: _selectedPriorityFilter == 0,
              onTap: () {
                setState(() {
                  _selectedPriorityFilter = 0;
                });
                Navigator.pop(context);
              },
            ),
            ...NotePriority.tumOnemler.map((priority) {
              final icon = NotePriority.onemIkonlari[priority] ?? '⚪';
              final name = NotePriority.onemIsimleri[priority] ?? '';
              
              return ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 20)),
                title: Text(name),
                selected: _selectedPriorityFilter == priority,
                onTap: () {
                  setState(() {
                    _selectedPriorityFilter = priority;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Filtreleri temizle
  void _clearFilters() {
    setState(() {
      _selectedCategoryFilter = 'Tümü';
      _selectedStatusFilter = 'Tümü';
      _selectedPriorityFilter = 0;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // Not kartı
  Widget _buildNoteCard(NoteModel note) {
    final categoryIcon = NoteCategory.kategoriIkonlari[note.kategori] ?? '📝';
    final priorityIcon = NotePriority.onemIkonlari[note.onem] ?? '⚪';
    final color = Color(int.parse(note.renk.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showNoteDetails(note),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır - Başlık ve tamamlanma durumu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.baslik,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: note.tamamlandi 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: note.tamamlandi 
                              ? Colors.grey[600] 
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tamamlanma checkbox'ı
                    InkWell(
                      onTap: () => _toggleNoteCompletion(note),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          note.tamamlandi 
                              ? Icons.check_circle 
                              : Icons.radio_button_unchecked,
                          color: note.tamamlandi 
                              ? Colors.green 
                              : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // İçerik
                if (note.icerik.isNotEmpty) ...[
                  Text(
                    note.icerik,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: note.tamamlandi 
                          ? Colors.grey[500] 
                          : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Alt satır - Kategori, öncelik, tarih
                Row(
                  children: [
                    // Kategori
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(categoryIcon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            note.kategori,
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
                    
                    // Öncelik
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(priorityIcon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            NotePriority.onemIsimleri[note.onem] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Tarih
                    Text(
                      DateFormat('dd.MM.yyyy').format(note.olusturulmaTarihi.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Not tamamlanma durumunu değiştir
  Future<void> _toggleNoteCompletion(NoteModel note) async {
    try {
      await _noteService.toggleNoteCompletion(note.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  // Not detayları modal
  void _showNoteDetails(NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          final categoryIcon = NoteCategory.kategoriIkonlari[note.kategori] ?? '📝';
          final priorityIcon = NotePriority.onemIkonlari[note.onem] ?? '⚪';
          final color = Color(int.parse(note.renk.replaceAll('#', '0xFF')));
          
          return Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle çubuğu
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // İçerik
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık ve işlemler
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.baslik,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: note.tamamlandi 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    note.tamamlandi 
                                        ? Icons.check_circle 
                                        : Icons.radio_button_unchecked,
                                    color: note.tamamlandi 
                                        ? Colors.green 
                                        : Colors.grey[400],
                                  ),
                                  onPressed: () => _toggleNoteCompletion(note),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditNotePage(
                                          note: note,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(note),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // İçerik
                        if (note.icerik.isNotEmpty) ...[
                          Text(
                            'İçerik',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.icerik,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Detay bilgileri
                        _DetailRow('Kategori', '$categoryIcon ${note.kategori}'),
                        _DetailRow('Öncelik', '$priorityIcon ${NotePriority.onemIsimleri[note.onem]}'),
                        _DetailRow('Renk', Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )),
                        _DetailRow('Durum', note.tamamlandi ? '✅ Tamamlandı' : '⏳ Bekliyor'),
                        _DetailRow('Oluşturulma', DateFormat('dd.MM.yyyy HH:mm').format(note.olusturulmaTarihi.toDate())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Silme onayı
  void _confirmDelete(NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu Sil'),
        content: Text('${note.baslik} notunu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Bottom sheet'i kapat
              try {
                await _noteService.deleteNote(note.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not başarıyla silindi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Not özeti
          _buildNotesSummary(),
          
          // Filtre ve arama
          _buildFilterBar(),
          const SizedBox(height: 16),
          
          // Not listesi
          Expanded(
            child: StreamBuilder<List<NoteModel>>(
              stream: _noteService.getNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final allNotes = snapshot.data ?? [];
                final filteredNotes = _filterNotes(allNotes);

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          allNotes.isEmpty 
                              ? 'Henüz not bulunmuyor'
                              : 'Filtreye uygun not bulunamadı',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allNotes.isEmpty
                              ? 'İlk notunuzu eklemek için + butonuna tıklayın'
                              : 'Farklı filtreler deneyin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(filteredNotes[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditNotePage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Özet kartı widget'i
class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Detay satırı widget'i
class _DetailRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: value is Widget 
                ? value
                : Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }
}