// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../core/widgets/form_field_with_custom_option.dart';

class AddEditTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionPage({Key? key, this.transaction}) : super(key: key);

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  bool _isLoading = false;
  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;

    _titleController = TextEditingController(text: transaction?.title ?? '');
    _amountController =
        TextEditingController(text: transaction?.amount.toString() ?? '');
    _descriptionController =
        TextEditingController(text: transaction?.description ?? '');

    _selectedType = transaction?.type ?? TransactionType.income;
    _selectedCategory = TransactionCategory.values.firstWhere(
      (e) => e.name == transaction?.category,
      orElse: () => TransactionCategory.other,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final transactionData = TransactionModel(
        id: widget.transaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.transaction?.userId ?? '',
        type: _selectedType,
        category: _selectedCategory.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        fileUrls: widget.transaction?.fileUrls ?? [],
      );

      if (_isEditMode) {
        await _transactionService.updateTransaction(transactionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İşlem başarıyla güncellendi! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _transactionService.addTransaction(transactionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İşlem başarıyla eklendi! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required ValueChanged onChanged,
    required IconData icon,
    String? Function(dynamic)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEditMode;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'İşlem Düzenle ✏️' : 'Yeni İşlem 💰',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isEdit ? Icons.save : Icons.add, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // İşlem Bilgileri Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1A73E8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF1A73E8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'İşlem Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCustomTextField(
                      controller: _titleController,
                      label: 'İşlem Başlığı *',
                      icon: Icons.title,
                      hint: 'İşlem açıklaması girin',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'İşlem başlığı gerekli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _amountController,
                      label: 'Tutar (₺) *',
                      icon: Icons.money,
                      keyboardType: TextInputType.number,
                      hint: 'Tutarı girin',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tutar gerekli';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCustomTextField(
                      controller: _descriptionController,
                      label: 'Açıklama',
                      icon: Icons.note,
                      maxLines: 3,
                      hint: 'Detaylı açıklama (opsiyonel)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori ve Tip Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTypeColor(_selectedType)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTypeIcon(_selectedType),
                            color: _getTypeColor(_selectedType),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Kategori ve Tip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FormFieldWithCustomOption<TransactionType>(
                      label: 'İşlem Tipi *',
                      value: _selectedType,
                      options: TransactionType.values,
                      optionLabel: (type) => TransactionModel(
                          id: '',
                          userId: '',
                          type: type,
                          category: 'other',
                          title: '',
                          description: '',
                          amount: 0,
                          createdAt: DateTime.now(),
                          fileUrls: []).getTypeText(localizations),
                      optionValue: (type) => type.name,
                      icon: Icons.category,
                      onChanged: (value) => setState(
                          () => _selectedType = value ?? _selectedType),
                      validator: (value) =>
                          value == null ? 'İşlem tipi seçin' : null,
                      customOptionLabel: 'Özel İşlem Tipi',
                      customInputLabel: 'Özel İşlem Tipi',
                      customInputHint: 'Özel işlem tipi açıklaması...',
                      fieldType: FormFieldType.dropdown,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    FormFieldWithCustomOption<TransactionCategory>(
                      label: 'Kategori *',
                      value: _selectedCategory,
                      options: TransactionCategory.values,
                      optionLabel: (category) => TransactionModel(
                          id: '',
                          userId: '',
                          type: _selectedType,
                          category: category.name,
                          title: '',
                          description: '',
                          amount: 0,
                          createdAt: DateTime.now(),
                          fileUrls: []).getCategoryText(localizations),
                      optionValue: (category) => category.name,
                      icon: Icons.label,
                      onChanged: (value) => setState(
                          () => _selectedCategory = value ?? _selectedCategory),
                      validator: (value) =>
                          value == null ? 'Kategori seçin' : null,
                      customOptionLabel: 'Özel Kategori',
                      customInputLabel: 'Özel Kategori',
                      customInputHint: 'Özel kategori açıklaması...',
                      fieldType: FormFieldType.dropdown,
                      isRequired: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Özet Kartı
            if (_titleController.text.isNotEmpty &&
                _amountController.text.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.summarize,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'İşlem Özeti',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getTypeColor(_selectedType)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getTypeColor(_selectedType)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(_getTypeIcon(_selectedType),
                                    color: _getTypeColor(_selectedType)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _titleController.text.isNotEmpty
                                        ? _titleController.text
                                        : 'İşlem Başlığı',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_selectedType == TransactionType.expense ? '-' : '+'}${_amountController.text.isNotEmpty ? _amountController.text : '0'}₺',
                                  style: TextStyle(
                                    color: _getTypeColor(_selectedType),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            if (_descriptionController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.note,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _descriptionController.text,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
