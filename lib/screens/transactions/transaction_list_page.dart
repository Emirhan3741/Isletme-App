import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';
import 'add_edit_transaction_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'Tümü'; // Tümü, Ödendi, Borç
  Map<String, CustomerModel> _customers = {};

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Müşteri bilgilerini yükle (cache için)
  void _loadCustomers() {
    _customerService.getCustomers().listen((customers) {
      final customerMap = <String, CustomerModel>{};
      for (var customer in customers) {
        customerMap[customer.id] = customer;
      }
      if (mounted) {
        setState(() {
          _customers = customerMap;
        });
      }
    });
  }

  // İşlemleri filtrele
  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    List<TransactionModel> filtered = transactions;

    // Ödeme durumu filtresi
    if (_selectedFilter != 'Tümü') {
      filtered = filtered.where((transaction) => 
        transaction.odemeDurumu == _selectedFilter).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final customer = _customers[transaction.musteriId];
        final customerName = customer != null 
          ? '${customer.ad} ${customer.soyad}'.toLowerCase()
          : '';
        
        return transaction.islemAdi.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               customerName.contains(_searchQuery.toLowerCase()) ||
               transaction.tutar.toString().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  // Finansal özet widget'i
  Widget _buildFinancialSummary() {
    return FutureBuilder<Map<String, double>>(
      future: _transactionService.getFinancialSummary(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'toplamBorc': 0.0, 'toplamOdeme': 0.0};
        final toplamBorc = data['toplamBorc'] ?? 0.0;
        final toplamOdeme = data['toplamOdeme'] ?? 0.0;
        final netDurum = toplamOdeme - toplamBorc;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finansal Özet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Toplam Ödeme',
                        amount: toplamOdeme,
                        color: Colors.green,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Toplam Borç',
                        amount: toplamBorc,
                        color: Colors.red,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Net Durum',
                        amount: netDurum,
                        color: netDurum >= 0 ? Colors.green : Colors.red,
                        icon: netDurum >= 0 ? Icons.trending_up : Icons.trending_down,
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
              hintText: 'İşlem, müşteri adı veya tutar ara...',
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
                'Filtrele: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tümü', 'Ödendi', 'Borç'].map((filter) {
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
            ],
          ),
        ],
      ),
    );
  }

  // İşlem kartı
  Widget _buildTransactionCard(TransactionModel transaction) {
    final customer = _customers[transaction.musteriId];
    final customerName = customer != null 
        ? '${customer.ad} ${customer.soyad}'
        : 'Müşteri bulunamadı';

    final isPaid = transaction.odemeDurumu == OdemeDurumu.odendi;
    final statusColor = isPaid ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetails(transaction, customer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - İşlem adı ve tutar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.islemAdi,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${NumberFormat('#,##0.00', 'tr_TR').format(transaction.tutar)} ₺',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // İkinci satır - Müşteri ve tarih
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd.MM.yyyy').format(transaction.tarih),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Alt satır - Durum ve ödeme tipi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      transaction.odemeDurumu,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    transaction.odemeTipi,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  // İşlem detayları modal
  void _showTransactionDetails(TransactionModel transaction, CustomerModel? customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
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
                              'İşlem Detayları',
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
                                        builder: (context) => AddEditTransactionPage(
                                          transaction: transaction,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(transaction),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Detay bilgileri
                        _DetailRow('İşlem Adı', transaction.islemAdi),
                        _DetailRow('Tutar', '${NumberFormat('#,##0.00', 'tr_TR').format(transaction.tutar)} ₺'),
                        _DetailRow('Müşteri', customer != null ? '${customer.ad} ${customer.soyad}' : 'Bilinmiyor'),
                        _DetailRow('Ödeme Durumu', transaction.odemeDurumu),
                        _DetailRow('Ödeme Tipi', transaction.odemeTipi),
                        _DetailRow('Tarih', DateFormat('dd.MM.yyyy').format(transaction.tarih)),
                        if (transaction.not.isNotEmpty) 
                          _DetailRow('Not', transaction.not),
                        _DetailRow('Oluşturulma', DateFormat('dd.MM.yyyy HH:mm').format(transaction.olusturulmaTarihi.toDate())),
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
  void _confirmDelete(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: Text('${transaction.islemAdi} işlemini silmek istediğinize emin misiniz?'),
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
                await _transactionService.deleteTransaction(transaction.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İşlem başarıyla silindi')),
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
        title: const Text('İşlemler'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Finansal özet
          _buildFinancialSummary(),
          
          // Filtre ve arama
          _buildFilterBar(),
          const SizedBox(height: 16),
          
          // İşlem listesi
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getTransactions(),
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

                final allTransactions = snapshot.data ?? [];
                final filteredTransactions = _filterTransactions(allTransactions);

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          allTransactions.isEmpty 
                              ? 'Henüz işlem bulunmuyor'
                              : 'Filtreye uygun işlem bulunamadı',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allTransactions.isEmpty
                              ? 'İlk işleminizi eklemek için + butonuna tıklayın'
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
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(filteredTransactions[index]);
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
              builder: (context) => const AddEditTransactionPage(),
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
            width: 120,
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