import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/stock_model.dart';
import '../../services/stock_service.dart';
import 'add_edit_stock_page.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  final StockService _stockService = StockService();
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';

  final List<String> _categories = [
    'Tümü',
    'Saç Bakım',
    'Cilt Bakım',
    'Makyaj',
    'Tırnak',
    'Masaj',
    'Ağda',
    'Kaş',
    'Diğer',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Yönetimi'),
        backgroundColor: Colors.pink.shade50,
        foregroundColor: Colors.pink.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddStock(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildStockList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.pink.shade50,
      child: Column(
        children: [
          // Arama kutusu
          TextField(
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Kategori filtresi
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.pink.shade100,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.pink.shade800
                          : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return StreamBuilder<List<StockModel>>(
      stream: _stockService.getUserStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final stocks = snapshot.data ?? [];
        final filteredStocks = _filterStocks(stocks);

        if (filteredStocks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Henüz stok eklenmemiş',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredStocks.length,
          itemBuilder: (context, index) {
            final stock = filteredStocks[index];
            return _buildStockCard(stock);
          },
        );
      },
    );
  }

  List<StockModel> _filterStocks(List<StockModel> stocks) {
    var filtered = stocks;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      filtered = filtered
          .where((stock) => stock.category == _selectedCategory)
          .toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((stock) =>
              stock.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              stock.brand.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Widget _buildStockCard(StockModel stock) {
    final isLowStock = stock.currentStock <= stock.minStock;
    final isExpiringSoon = stock.expiryDate != null &&
        stock.expiryDate!
            .isBefore(DateTime.now().add(const Duration(days: 30)));
    final isExpired =
        stock.expiryDate != null && stock.expiryDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToEditStock(stock),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stock.brand,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Süresi Dolmuş',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    )
                  else if (isExpiringSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Yakında Dolacak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    )
                  else if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stok Az',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Stok',
                      '${stock.currentStock}/${stock.minStock}',
                      Icons.inventory,
                      isLowStock ? Colors.amber : Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Fiyat',
                      '₺${stock.salePrice.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.blue,
                    ),
                  ),
                  if (stock.expiryDate != null)
                    Expanded(
                      child: _buildInfoItem(
                        'Son Kullanma',
                        DateFormat('dd/MM/yyyy').format(stock.expiryDate!),
                        Icons.schedule,
                        isExpired
                            ? Colors.red
                            : (isExpiringSoon ? Colors.orange : Colors.green),
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

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _navigateToAddStock() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditStockPage(),
      ),
    ).then((_) {
      // Sayfa geri döndüğünde listeyi yenile
      setState(() {});
    });
  }

  void _navigateToEditStock(StockModel stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStockPage(stock: stock),
      ),
    ).then((_) {
      // Sayfa geri döndüğünde listeyi yenile
      setState(() {});
    });
  }
}
