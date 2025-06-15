import 'package:flutter/material.dart';
import 'package:randevu_erp/models/customer_model.dart';
import 'package:randevu_erp/services/customer_service.dart';

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
          id: widget.customer!.id,
        );
        await _customerService.updateCustomer(updatedCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer updated'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newCustomer = CustomerModel(
          id: UniqueKey().toString(),
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _customerService.addCustomer(newCustomer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer added'), backgroundColor: Colors.green),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Customer' : 'Add Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                child: Text(_isEditMode ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Cleaned for Web Build by Cursor 