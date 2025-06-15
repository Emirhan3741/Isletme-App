import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class AddEditExpensePage extends StatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpensePage({Key? key, this.expense}) : super(key: key);

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseService _expenseService = ExpenseService();
  late final TextEditingController _amountController;
  ExpenseCategory _selectedCategory = ExpenseCategory.rent;
  bool _isLoading = false;
  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    _selectedCategory = expense?.category ?? ExpenseCategory.rent;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final updatedExpense = widget.expense!.copyWith(
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory,
          createdAt: widget.expense!.createdAt,
          id: widget.expense!.id,
        );
        await _expenseService.updateExpense(updatedExpense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gider güncellendi'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newExpense = ExpenseModel(
          id: UniqueKey().toString(),
          amount: double.parse(_amountController.text.trim()),
          category: _selectedCategory,
          createdAt: DateTime.now(),
        );
        await _expenseService.addExpense(newExpense);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gider eklendi'), backgroundColor: Colors.green),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Gider Düzenle' : 'Yeni Gider'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: Text(
              _isEditMode ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gider Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Tutar *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tutar alanı gereklidir';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Geçerli bir tutar giriniz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ExpenseCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedCategory = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Cleaned for Web Build by Cursor 