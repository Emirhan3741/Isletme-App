import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import 'add_edit_expense_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({Key? key}) : super(key: key);

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses) {
    if (_searchQuery.isEmpty) return expenses;
    return expenses.where((expense) {
      return expense.category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             expense.amount.toString().contains(_searchQuery);
    }).toList();
  }

  Future<void> _refreshExpenses() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giderler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
              );
              if (result == true) _refreshExpenses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kategori veya tutar ara...',
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
            child: FutureBuilder<List<ExpenseModel>>(
              future: _expenseService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Kayıtlı gider yok.'));
                }
                final expenses = _filterExpenses(snapshot.data!);
                if (expenses.isEmpty) {
                  return const Center(child: Text('Aramanıza uygun gider bulunamadı.'));
                }
                return ListView.separated(
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final expense = expenses[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.money)),
                      title: Text('${expense.amount.toStringAsFixed(2)} ₺'),
                      subtitle: Text(expense.category.name),
                      trailing: Text(DateFormat('dd.MM.yyyy').format(expense.createdAt)),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditExpensePage(expense: expense),
                          ),
                        );
                        if (result == true) _refreshExpenses();
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
}
// Cleaned for Web Build by Cursor