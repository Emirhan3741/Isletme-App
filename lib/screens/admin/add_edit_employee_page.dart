import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class AddEditEmployeePage extends StatefulWidget {
  final UserModel? employee;

  const AddEditEmployeePage({Key? key, this.employee}) : super(key: key);

  @override
  State<AddEditEmployeePage> createState() => _AddEditEmployeePageState();
}

class _AddEditEmployeePageState extends State<AddEditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool get _isEditMode => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _nameController = TextEditingController(text: employee?.name ?? '');
    _emailController = TextEditingController(text: employee?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final updatedEmployee = widget.employee!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _userService.updateUser(updatedEmployee, '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Çalışan güncellendi'), backgroundColor: Colors.green),
          );
        }
      } else {
        final newEmployee = UserModel(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userService.addUser(newEmployee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Çalışan eklendi'), backgroundColor: Colors.green),
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
        title: Text(_isEditMode ? 'Çalışan Düzenle' : 'Yeni Çalışan'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEmployee,
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
                    Text('Çalışan Bilgileri', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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