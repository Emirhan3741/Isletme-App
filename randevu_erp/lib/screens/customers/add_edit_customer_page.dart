import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class AddEditCustomerPage extends StatefulWidget {
  final CustomerModel? customer;

  const AddEditCustomerPage({Key? key, this.customer}) : super(key: key);

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  
  late final TextEditingController _adController;
  late final TextEditingController _soyadController;
  late final TextEditingController _telefonController;
  late final TextEditingController _epostaController;
  late final TextEditingController _notController;
  
  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    
    final customer = widget.customer;
    _adController = TextEditingController(text: customer?.ad ?? '');
    _soyadController = TextEditingController(text: customer?.soyad ?? '');
    _telefonController = TextEditingController(text: customer?.telefon ?? '');
    _epostaController = TextEditingController(text: customer?.eposta ?? '');
    _notController = TextEditingController(text: customer?.not ?? '');
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _epostaController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Telefon numarası kontrolü
      final cleanPhone = _telefonController.text.replaceAll(RegExp(r'[^\d]'), '');
      final phoneExists = await _customerService.isPhoneExists(
        cleanPhone,
        excludeCustomerId: _isEditing ? widget.customer!.id : null,
      );

      if (phoneExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu telefon numarası zaten kayıtlı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_isEditing) {
        // Güncelleme
        final updatedCustomer = widget.customer!.copyWith(
          ad: _adController.text.trim(),
          soyad: _soyadController.text.trim(),
          telefon: cleanPhone,
          eposta: _epostaController.text.trim().isEmpty ? null : _epostaController.text.trim(),
          not: _notController.text.trim().isEmpty ? null : _notController.text.trim(),
        );

        await _customerService.updateCustomer(updatedCustomer);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedCustomer.tamAd} güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Yeni ekleme
        final customer = await _customerService.addCustomer(
          ad: _adController.text.trim(),
          soyad: _soyadController.text.trim(),
          telefon: cleanPhone,
          eposta: _epostaController.text.trim().isEmpty ? null : _epostaController.text.trim(),
          not: _notController.text.trim().isEmpty ? null : _notController.text.trim(),
        );

        if (mounted && customer != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.tamAd} eklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: Text(
              _isEditing ? 'Güncelle' : 'Kaydet',
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
            // Kişisel Bilgiler Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kişisel Bilgiler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ad alanı
                    TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(
                        labelText: 'Ad *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad alanı gereklidir';
                        }
                        if (value.trim().length < 2) {
                          return 'Ad en az 2 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Soyad alanı
                    TextFormField(
                      controller: _soyadController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Soyad alanı gereklidir';
                        }
                        if (value.trim().length < 2) {
                          return 'Soyad en az 2 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İletişim Bilgileri Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İletişim Bilgileri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Telefon alanı
                    TextFormField(
                      controller: _telefonController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '0555 123 45 67',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        _PhoneNumberFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Telefon numarası gereklidir';
                        }
                        
                        final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
                        
                        if (cleanPhone.length < 10) {
                          return 'Telefon numarası en az 10 haneli olmalıdır';
                        }
                        
                        if (cleanPhone.length == 11 && !cleanPhone.startsWith('0')) {
                          return 'Geçerli bir telefon numarası girin';
                        }
                        
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // E-posta alanı
                    TextFormField(
                      controller: _epostaController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'ornek@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ek Bilgiler Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ek Bilgiler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Not alanı
                    TextFormField(
                      controller: _notController,
                      decoration: const InputDecoration(
                        labelText: 'Not',
                        prefixIcon: Icon(Icons.note_outlined),
                        hintText: 'Müşteri hakkında notlar...',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Kaydet/Güncelle Butonu
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Güncelle' : 'Müşteri Ekle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Bilgi notu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '* işaretli alanlar zorunludur',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Telefon numarası formatlamak için custom formatter
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    
    if (text.length >= 1) {
      if (text.startsWith('0')) {
        // 0555 123 45 67 format
        formatted = text.substring(0, 1);
        if (text.length > 1) {
          formatted += text.substring(1, text.length > 4 ? 4 : text.length);
        }
        if (text.length > 4) {
          formatted += ' ${text.substring(4, text.length > 7 ? 7 : text.length)}';
        }
        if (text.length > 7) {
          formatted += ' ${text.substring(7, text.length > 9 ? 9 : text.length)}';
        }
        if (text.length > 9) {
          formatted += ' ${text.substring(9, text.length > 11 ? 11 : text.length)}';
        }
      } else {
        // 555 123 45 67 format (0 olmadan)
        formatted = text.substring(0, text.length > 3 ? 3 : text.length);
        if (text.length > 3) {
          formatted += ' ${text.substring(3, text.length > 6 ? 6 : text.length)}';
        }
        if (text.length > 6) {
          formatted += ' ${text.substring(6, text.length > 8 ? 8 : text.length)}';
        }
        if (text.length > 8) {
          formatted += ' ${text.substring(8, text.length > 10 ? 10 : text.length)}';
        }
      }
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 