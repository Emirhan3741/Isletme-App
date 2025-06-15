import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/customer_model.dart';
import '../../services/transaction_service.dart';
import '../../services/customer_service.dart';

class AddEditTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;
  final String? preSelectedCustomerId;
  final String? preSelectedRandevuId;

  const AddEditTransactionPage({
    super.key,
    this.transaction,
    this.preSelectedCustomerId,
    this.preSelectedRandevuId,
  });

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();

  // Form controllers
  final TextEditingController _islemAdiController = TextEditingController();
  final TextEditingController _tutarController = TextEditingController();
  final TextEditingController _notController = TextEditingController();
  final TextEditingController _randevuIdController = TextEditingController();

  // Form değişkenleri
  CustomerModel? _selectedCustomer;
  String _selectedOdemeDurumu = OdemeDurumu.borc;
  String _selectedOdemeTipi = OdemeTipi.nakit;
  DateTime _selectedDate = DateTime.now();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _initializeForm();
  }

  @override
  void dispose() {
    _islemAdiController.dispose();
    _tutarController.dispose();
    _notController.dispose();
    _randevuIdController.dispose();
    super.dispose();
  }

  void _loadCustomers() {
    _customerService.getCustomers().listen((customers) {
      if (mounted) {
        setState(() {
          _customers = customers;
          
          // Eğer pre-selected customer varsa, onu seç
          if (widget.preSelectedCustomerId != null) {
            _selectedCustomer = customers.firstWhere(
              (customer) => customer.id == widget.preSelectedCustomerId,
              orElse: () => customers.isNotEmpty ? customers.first : throw Exception('Müşteri bulunamadı'),
            );
          }
        });
      }
    });
  }

  void _initializeForm() {
    if (_isEditMode) {
      final transaction = widget.transaction!;
      _islemAdiController.text = transaction.islemAdi;
      _tutarController.text = transaction.tutar.toString();
      _notController.text = transaction.not;
      _randevuIdController.text = transaction.randevuId;
      _selectedOdemeDurumu = transaction.odemeDurumu;
      _selectedOdemeTipi = transaction.odemeTipi;
      _selectedDate = transaction.tarih;
    } else {
      // Yeni işlem için pre-selected değerleri ayarla
      if (widget.preSelectedRandevuId != null) {
        _randevuIdController.text = widget.preSelectedRandevuId!;
      }
    }
  }

  // Müşteri seçim dialog'u
  void _showCustomerSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Seç'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _customers.isEmpty
              ? const Center(child: Text('Müşteri bulunamadı'))
              : ListView.builder(
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text('${customer.ad} ${customer.soyad}'),
                      subtitle: customer.telefon.isNotEmpty 
                          ? Text(customer.telefon) 
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
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
  String? _validateIslemAdi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'İşlem adı gereklidir';
    }
    if (value.trim().length < 2) {
      return 'İşlem adı en az 2 karakter olmalıdır';
    }
    return null;
  }

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

  String? _validateCustomer() {
    if (_selectedCustomer == null) {
      return 'Müşteri seçimi gereklidir';
    }
    return null;
  }

  // Form gönderimi
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    final customerError = _validateCustomer();
    if (customerError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(customerError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = TransactionModel(
        id: _isEditMode ? widget.transaction!.id : '',
        musteriId: _selectedCustomer!.id,
        randevuId: _randevuIdController.text.trim(),
        islemAdi: _islemAdiController.text.trim(),
        tutar: double.parse(_tutarController.text),
        odemeDurumu: _selectedOdemeDurumu,
        odemeTipi: _selectedOdemeTipi,
        not: _notController.text.trim(),
        tarih: _selectedDate,
        olusturulmaTarihi: _isEditMode 
            ? widget.transaction!.olusturulmaTarihi 
            : Timestamp.now(),
        ekleyenKullaniciId: _isEditMode 
            ? widget.transaction!.ekleyenKullaniciId 
            : '',
      );

      if (_isEditMode) {
        await _transactionService.updateTransaction(transaction);
      } else {
        await _transactionService.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'İşlem başarıyla güncellendi' 
                : 'İşlem başarıyla eklendi'),
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
        title: Text(_isEditMode ? 'İşlem Düzenle' : 'Yeni İşlem'),
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
              // Müşteri seçimi
              Text(
                'Müşteri *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCustomerSelection,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCustomer != null
                              ? '${_selectedCustomer!.ad} ${_selectedCustomer!.soyad}'
                              : 'Müşteri seçin',
                          style: TextStyle(
                            color: _selectedCustomer != null 
                                ? Colors.black 
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // İşlem adı
              TextFormField(
                controller: _islemAdiController,
                decoration: const InputDecoration(
                  labelText: 'İşlem Adı *',
                  hintText: 'Örn: Saç kesimi, Boyama, Makyaj',
                  border: OutlineInputBorder(),
                ),
                validator: _validateIslemAdi,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _tutarController,
                decoration: const InputDecoration(
                  labelText: 'Tutar *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  suffixText: '₺',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: _validateTutar,
              ),
              const SizedBox(height: 16),

              // Ödeme durumu
              Text(
                'Ödeme Durumu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedOdemeDurumu,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: OdemeDurumu.tumDurumlar.map((durum) {
                  return DropdownMenuItem(
                    value: durum,
                    child: Text(durum),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOdemeDurumu = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Ödeme tipi
              Text(
                'Ödeme Tipi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedOdemeTipi,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: OdemeTipi.tumTipler.map((tip) {
                  return DropdownMenuItem(
                    value: tip,
                    child: Text(tip),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedOdemeTipi = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Tarih
              Text(
                'Tarih',
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Randevu ID (opsiyonel)
              TextFormField(
                controller: _randevuIdController,
                decoration: const InputDecoration(
                  labelText: 'Randevu ID (Opsiyonel)',
                  hintText: 'İlgili randevu ID\'si',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Not
              TextFormField(
                controller: _notController,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  hintText: 'İşlemle ilgili notlar',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

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
                      : Text(
                          _isEditMode ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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