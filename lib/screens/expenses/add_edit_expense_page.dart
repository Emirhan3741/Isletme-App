// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/expense_model.dart';
import '../../widgets/file_upload_widget.dart';

class AddEditExpensePage extends StatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpensePage({super.key, this.expense});

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'rent';
  bool _isRecurring = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _hasReceiptUploaded = false;

  final List<String> _categories = [
    'rent',
    'salary',
    'material',
    'marketing',
    'bills',
    'maintenance',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final expense = widget.expense!;
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _descriptionController.text = expense.description;
    _selectedCategory = expense.category;
    _isRecurring = expense.isRecurring;
    _selectedDate = expense.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'rent':
        return 'Kira';
      case 'salary':
        return 'Maaş';
      case 'material':
        return 'Malzeme';
      case 'marketing':
        return 'Pazarlama';
      case 'bills':
        return 'Faturalar';
      case 'maintenance':
        return 'Bakım';
      case 'other':
        return 'Diğer';
      default:
        return category;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final expenseData = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'isRecurring': _isRecurring,
        'date': Timestamp.fromDate(_selectedDate),
        'hasReceipt': _hasReceiptUploaded,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.expense?.id != null) {
        // Güncelleme
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.expense!.id)
            .update(expenseData);
      } else {
        // Yeni kayıt
        expenseData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('expenses')
            .add(expenseData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gider ${widget.expense?.id != null ? 'güncellendi' : 'eklendi'}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.expense?.id != null ? 'Gider Düzenle' : 'Yeni Gider',
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: Text(
              widget.expense?.id != null ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gider Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),

                      // Başlık
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Gider Başlığı *',
                          hintText: 'Örn: Ofis Kirası',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Gider başlığı gereklidir';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tutar ve Kategori
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Tutar *',
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money),
                                suffixText: '₺',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tutar gereklidir';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Geçersiz tutar';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Tutar 0\'dan büyük olmalıdır';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Kategori',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child:
                                      Text(_getCategoryDisplayName(category)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tarih
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tarih',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Açıklama
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          hintText: 'Gider detayları...',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tekrarlayan gider
                      SwitchListTile(
                        title: Text('Tekrarlayan Gider'),
                        subtitle: Text('Aylık olarak tekrarlansın'),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: AppConstants.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Fiş/Fatura Yükleme
              CommonCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fiş/Fatura Eki',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Text(
                        'Giderinizin fiş veya faturasını yükleyerek kayıtlarınızı tamamlayabilirsiniz.',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      FileUploadWidget(
                        onUploadComplete: (result) {},
                        module: 'expenses',
                        collection: 'expense_receipts',
                        additionalData: {
                          'expenseId': widget.expense?.id ?? 'new',
                          'title': 'Gider Fişi/Faturası',
                          'category': _selectedCategory,
                          'amount':
                              double.tryParse(_amountController.text) ?? 0.0,
                        },
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        onUploadSuccess: () {
                          setState(() {
                            _hasReceiptUploaded = true;
                          });
                        },
                        onUploadError: (error) {
                          setState(() {
                            _hasReceiptUploaded = false;
                          });
                        },
                        isRequired: false,
                        showPreview: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.expense?.id != null
                              ? 'Gideri Güncelle'
                              : 'Gideri Kaydet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
