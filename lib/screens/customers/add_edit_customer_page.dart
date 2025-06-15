import 'package:flutter/material.dart';
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
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final updatedCustomer = widget.customer!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _customerService.updateCustomer(updatedCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Müşteri güncellendi'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newCustomer = CustomerModel(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _customerService.addCustomer(newCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Müşteri eklendi'), backgroundColor: Colors.green),
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
        title: Text(_isEditMode ? 'Müşteri Düzenle' : 'Yeni Müşteri'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
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
                    Text('Müşteri Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad Soyad alanı gereklidir';
                        }
                        if (value.trim().length < 3) {
                          return 'Ad Soyad en az 3 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta *',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'E-posta alanı gereklidir';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta giriniz';
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
// Cleaned for Web Build by Cursor 