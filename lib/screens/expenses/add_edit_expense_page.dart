import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';

class AddEditExpensePage extends StatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpensePage({
    super.key,
    this.expense,
  });

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseService _expenseService = ExpenseService();

  // Form controllers
  final TextEditingController _tutarController = TextEditingController();
  final TextEditingController _notController = TextEditingController();

  // Form değişkenleri
  String _selectedKategori = ExpenseCategory.kira;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _notController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditMode) {
      final expense = widget.expense!;
      _tutarController.text = expense.tutar.toString();
      _notController.text = expense.not;
      _selectedKategori = expense.kategori;
      _selectedDate = expense.tarih;
    }
  }

  // Tarih seçimi
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Form validasyonu
  String? _validateTutar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tutar gereklidir';
    }
    final tutar = double.tryParse(value);
    if (tutar == null) {
      return 'Geçerli bir tutar giriniz';
    }
    if (tutar <= 0) {
      return 'Tutar 0\'dan büyük olmalıdır';
    }
    return null;
  }

  // Form gönderimi
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = ExpenseModel(
        id: _isEditMode ? widget.expense!.id : '',
        kategori: _selectedKategori,
        tutar: double.parse(_tutarController.text),
        tarih: _selectedDate,
        not: _notController.text.trim(),
        olusturulmaTarihi: _isEditMode 
            ? widget.expense!.olusturulmaTarihi 
            : Timestamp.now(),
        ekleyenKullaniciId: _isEditMode 
            ? widget.expense!.ekleyenKullaniciId 
            : '',
      );

      if (_isEditMode) {
        await _expenseService.updateExpense(expense);
      } else {
        await _expenseService.addExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Gider başarıyla güncellendi' 
                : 'Gider başarıyla eklendi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Gider Düzenle' : 'Yeni Gider'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                _isEditMode ? 'Güncelle' : 'Kaydet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori seçimi
              Text(
                'Kategori *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ExpenseCategory.tumKategoriler.map((kategori) {
                  final icon = ExpenseCategory.kategoriIkonlari[kategori] ?? '💼';
                  return DropdownMenuItem(
                    value: kategori,
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(kategori),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _tutarController,
                decoration: const InputDecoration(
                  labelText: 'Tutar *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                  suffixText: '₺',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: _validateTutar,
              ),
              const SizedBox(height: 16),

              // Tarih
              Text(
                'Tarih *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Not
              TextFormField(
                controller: _notController,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  hintText: 'Giderle ilgili notlar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Kategori bilgi kartı
              if (!_isEditMode) _buildCategoryInfo(),
              const SizedBox(height: 16),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditMode ? Icons.update : Icons.save),
                            const SizedBox(width: 8),
                            Text(
                              _isEditMode ? 'Güncelle' : 'Kaydet',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kategori bilgi kartı
  Widget _buildCategoryInfo() {
    final categoryIcon = ExpenseCategory.kategoriIkonlari[_selectedKategori] ?? '💼';
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(categoryIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Seçili Kategori: $_selectedKategori',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDescription(_selectedKategori),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori açıklaması
  String _getCategoryDescription(String kategori) {
    switch (kategori) {
      case ExpenseCategory.kira:
        return 'Mağaza, salon veya ofis kirası';
      case ExpenseCategory.elektrik:
        return 'Elektrik faturası ve enerji giderleri';
      case ExpenseCategory.su:
        return 'Su faturası ve su giderleri';
      case ExpenseCategory.dogalgaz:
        return 'Doğalgaz faturası ve ısıtma giderleri';
      case ExpenseCategory.telefon:
        return 'Telefon faturası ve iletişim giderleri';
      case ExpenseCategory.internet:
        return 'İnternet faturası ve teknoloji giderleri';
      case ExpenseCategory.maas:
        return 'Çalışan maaşları ve bordro ödemeleri';
      case ExpenseCategory.malzeme:
        return 'İş malzemeleri ve ekipman alımları';
      case ExpenseCategory.temizlik:
        return 'Temizlik malzemeleri ve hizmetleri';
      case ExpenseCategory.reklam:
        return 'Pazarlama ve reklam harcamaları';
      case ExpenseCategory.vergi:
        return 'Vergiler ve resmi ödemeler';
      case ExpenseCategory.sigorta:
        return 'Sigorta primleri ve güvence ödemeleri';
      case ExpenseCategory.yakıt:
        return 'Araç yakıtı ve ulaşım giderleri';
      case ExpenseCategory.yemek:
        return 'Yemek ve ikram giderleri';
      case ExpenseCategory.egitim:
        return 'Eğitim ve gelişim harcamaları';
      case ExpenseCategory.bakim:
        return 'Bakım, onarım ve tamir giderleri';
      case ExpenseCategory.diger:
        return 'Diğer işletme giderleri';
      default:
        return 'Gider kategorisi açıklaması';
    }
  }
} 