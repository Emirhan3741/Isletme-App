import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class AddEditTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionPage({Key? key, this.transaction}) : super(key: key);

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();
  late final TextEditingController _amountController;
  bool _isLoading = false;
  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amountController = TextEditingController(text: transaction?.amount.toString() ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final updatedTransaction = widget.transaction!.copyWith(
          amount: double.parse(_amountController.text.trim()),
          updatedAt: DateTime.now(),
        );
        await _transactionService.updateTransaction(updatedTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İşlem güncellendi'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newTransaction = TransactionModel(
          amount: double.parse(_amountController.text.trim()),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _transactionService.addTransaction(newTransaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('İşlem eklendi'), backgroundColor: Colors.green),
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
        title: Text(_isEditMode ? 'İşlem Düzenle' : 'Yeni İşlem'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTransaction,
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
                    Text('İşlem Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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