// Refactored by Cursor

import 'package:flutter/material.dart';

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
      return expense.amount.toString().contains(_searchQuery);
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
                MaterialPageRoute(
                  builder: (context) => const AddEditExpensePage(),
                ),
              );
              if (result == true) {
                setState(() {});
              }
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
              decoration: const InputDecoration(
                labelText: 'Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _expenseService.getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final expenses = _filterExpenses(snapshot.data ?? []);

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text('Gider bulunamadı'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshExpenses,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(
                            expense.amount.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            expense.createdAt.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditExpensePage(
                                    expense: expense,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                      );
                    },
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
