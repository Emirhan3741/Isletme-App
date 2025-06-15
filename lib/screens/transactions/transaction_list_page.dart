// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/customer_service.dart';
import '../../models/customer_model.dart';
import 'add_edit_transaction_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  PaymentStatus? _selectedFilter;
  Map<String, CustomerModel> _customers = {};
  CustomerModel? customer;

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
    _customerService.getCustomers().then((customers) {
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
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.amount.toString().contains(_searchQuery);
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = null;
                    });
                  },
                ),
                ...PaymentStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(status.name),
                      selected: _selectedFilter == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İşlem kartı
  Widget _buildTransactionCard(TransactionModel transaction) {
    final customer = _customers[transaction.customerId];
    final customerName = customer != null ? '${customer.name} ${customer.email}' : 'Unknown';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(transaction.operationName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${NumberFormat('#,##0.00', 'tr_TR').format(transaction.amount)} ₺', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[700])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Customer: $customerName'),
                  const SizedBox(width: 16),
                  Text('Status: ${transaction.paymentStatus.name}'),
                  const SizedBox(width: 16),
                  Text('Type: ${transaction.paymentType.name}'),
                ],
              ),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('dd.MM.yyyy').format(transaction.date)}'),
            ],
          ),
        ),
      ),
    );
  }

  // İşlem detayları modal
  void _showTransactionDetails(TransactionModel transaction) {
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
                        _DetailRow('İşlem Adı', transaction.operationName),
                        _DetailRow('Tutar', '${NumberFormat('#,##0.00', 'tr_TR').format(transaction.amount)} ₺'),
                        _DetailRow('Müşteri', customer != null ? '${customer?.name} ${customer?.email}' : 'Bilinmiyor'),
                        _DetailRow('Ödeme Durumu', transaction.paymentStatus.name),
                        _DetailRow('Ödeme Tipi', transaction.paymentType.name),
                        _DetailRow('Tarih', DateFormat('dd.MM.yyyy').format(transaction.date)),
                        if (transaction.note.isNotEmpty) 
                          _DetailRow('Not', transaction.note),
                        _DetailRow('Oluşturulma', DateFormat('dd.MM.yyyy HH:mm').format(transaction.createdAt ?? DateTime.now())),
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
        content: Text('${transaction.operationName} işlemini silmek istediğinize emin misiniz?'),
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
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşlemler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditTransactionPage()),
              );
              if (result == true) _refreshTransactions();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Kullanıcı bulunamadı'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tutar ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TransactionModel>>(
              future: _transactionService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Kayıtlı işlem yok.'));
                }
                final transactions = _filterTransactions(snapshot.data!);
                if (transactions.isEmpty) {
                  return const Center(child: Text('Aramanıza uygun işlem bulunamadı.'));
                }
                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final transaction = transactions[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.swap_horiz)),
                      title: Text('${transaction.amount.toStringAsFixed(2)} ₺'),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(transaction.createdAt)),
                      trailing: Text(DateFormat('HH:mm').format(transaction.createdAt)),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditTransactionPage(transaction: transaction),
                          ),
                        );
                        if (result == true) _refreshTransactions();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    setState(() {});
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

// Cleaned for Web Build by Cursor 