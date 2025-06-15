import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import 'add_edit_expense_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Tümü'; // Tümü veya kategoriler

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Giderleri filtrele
  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses) {
    List<ExpenseModel> filtered = expenses;

    // Kategori filtresi
    if (_selectedFilter != 'Tümü') {
      filtered = filtered.where((expense) => 
        expense.kategori == _selectedFilter).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.kategori.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               expense.not.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               expense.tutar.toString().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  // Gider özeti widget'i
  Widget _buildExpenseSummary() {
    return FutureBuilder<double>(
      future: _expenseService.getTotalExpenses(),
      builder: (context, snapshot) {
        final totalExpenses = snapshot.data ?? 0.0;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gider Özeti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Toplam Gider',
                        amount: totalExpenses,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<double>(
                        future: _expenseService.getMonthlyExpenses(),
                        builder: (context, monthSnapshot) {
                          final monthlyExpenses = monthSnapshot.data ?? 0.0;
                          return _SummaryCard(
                            title: 'Bu Ay',
                            amount: monthlyExpenses,
                            color: Colors.orange,
                            icon: Icons.calendar_month,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<double>(
                        future: _expenseService.getTodayExpenses(),
                        builder: (context, todaySnapshot) {
                          final todayExpenses = todaySnapshot.data ?? 0.0;
                          return _SummaryCard(
                            title: 'Bugün',
                            amount: todayExpenses,
                            color: Colors.blue,
                            icon: Icons.today,
                          );
                        },
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

  // Kategori özet kartları
  Widget _buildCategorySummary() {
    return FutureBuilder<Map<String, double>>(
      future: _expenseService.getCategoryExpenseSummary(),
      builder: (context, snapshot) {
        final categoryData = snapshot.data ?? {};
        
        if (categoryData.isEmpty) {
          return const SizedBox.shrink();
        }

        // En yüksek 3 kategoriyi göster
        final sortedCategories = categoryData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sortedCategories.take(3).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Yüksek Gider Kategorileri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...topCategories.map((entry) {
                  final category = entry.key;
                  final amount = entry.value;
                  final icon = ExpenseCategory.kategoriIkonlari[category] ?? '💼';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,##0.00', 'tr_TR').format(amount)} ₺',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
              hintText: 'Kategori, not veya tutar ara...',
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
          Row(
            children: [
              Text(
                'Kategori: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tümü', ...ExpenseCategory.tumKategoriler.take(5)].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showCategoryFilterDialog(),
              ),
            ],
          ),
        ],
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
            children: ['Tümü', ...ExpenseCategory.tumKategoriler].map((category) {
              final icon = category == 'Tümü' 
                  ? '📋' 
                  : ExpenseCategory.kategoriIkonlari[category] ?? '💼';
              
              return ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 20)),
                title: Text(category),
                selected: _selectedFilter == category,
                onTap: () {
                  setState(() {
                    _selectedFilter = category;
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

  // Gider kartı
  Widget _buildExpenseCard(ExpenseModel expense) {
    final categoryIcon = ExpenseCategory.kategoriIkonlari[expense.kategori] ?? '💼';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExpenseDetails(expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Kategori ve tutar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(categoryIcon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        expense.kategori,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${NumberFormat('#,##0.00', 'tr_TR').format(expense.tutar)} ₺',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Tarih
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(expense.tarih),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (expense.not.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expense.not,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gider detayları modal
  void _showExpenseDetails(ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          final categoryIcon = ExpenseCategory.kategoriIkonlari[expense.kategori] ?? '💼';
          
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gider Detayları',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditExpensePage(
                                          expense: expense,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(expense),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Detay bilgileri
                        _DetailRow('Kategori', '$categoryIcon ${expense.kategori}'),
                        _DetailRow('Tutar', '${NumberFormat('#,##0.00', 'tr_TR').format(expense.tutar)} ₺'),
                        _DetailRow('Tarih', DateFormat('dd.MM.yyyy').format(expense.tarih)),
                        if (expense.not.isNotEmpty) 
                          _DetailRow('Not', expense.not),
                        _DetailRow('Oluşturulma', DateFormat('dd.MM.yyyy HH:mm').format(expense.olusturulmaTarihi.toDate())),
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
  void _confirmDelete(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gideri Sil'),
        content: Text('${expense.kategori} giderini silmek istediğinize emin misiniz?'),
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
                await _expenseService.deleteExpense(expense.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gider başarıyla silindi')),
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
        title: const Text('Giderler'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Gider özeti
          _buildExpenseSummary(),
          
          // Kategori özeti
          _buildCategorySummary(),
          
          // Filtre ve arama
          _buildFilterBar(),
          const SizedBox(height: 16),
          
          // Gider listesi
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpenses(),
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

                final allExpenses = snapshot.data ?? [];
                final filteredExpenses = _filterExpenses(allExpenses);

                if (filteredExpenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          allExpenses.isEmpty 
                              ? 'Henüz gider bulunmuyor'
                              : 'Filtreye uygun gider bulunamadı',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allExpenses.isEmpty
                              ? 'İlk giderinizi eklemek için + butonuna tıklayın'
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
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      return _buildExpenseCard(filteredExpenses[index]);
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
              builder: (context) => const AddEditExpensePage(),
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
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
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
            '${NumberFormat('#,##0.00', 'tr_TR').format(amount)} ₺',
            style: TextStyle(
              fontSize: 14,
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
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}