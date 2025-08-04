// Refactored by Cursor

import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/employee_invite_generator.dart';
import 'add_edit_employee_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({Key? key}) : super(key: key);

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterEmployees(List<UserModel> employees) {
    if (_searchQuery.isEmpty) return employees;
    return employees.where((employee) {
      return employee.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _refreshEmployees() async {
    setState(() {});
  }

  Future<void> _generateAndShareInviteLink() async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Davet linki oluştur
      final inviteLink = await EmployeeInviteGenerator.createEmployeeInvite(
        businessId:
            'default_business', // Bu işletme ID'si gerçek veriden gelecek
        metadata: {
          'createdBy': 'admin',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Loading dialog'u kapat
      if (mounted) Navigator.pop(context);

      // Başarı dialog'u göster
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Davet Linki Oluşturuldu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Çalışan davet linki başarıyla oluşturuldu!'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    inviteLink,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bu linki çalışana göndererek kayıt olmasını sağlayabilirsiniz.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await EmployeeInviteGenerator.shareViaWhatsApp(
                      inviteLink,
                      message:
                          'Merhaba! Çalışan kaydı için özel davet linkiniz hazır:',
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('WhatsApp paylaşımı başarısız: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('WhatsApp ile Paylaş'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat (eğer açık ise)
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Davet linki oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Çalışan Davet Linki Oluştur',
            onPressed: _generateAndShareInviteLink,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Çalışan Ekle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditEmployeePage()),
              );
              if (result == true) _refreshEmployees();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ad veya e-posta ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _userService.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Kayıtlı çalışan yok.'));
                }
                final employees = _filterEmployees(snapshot.data!);
                if (employees.isEmpty) {
                  return const Center(
                      child: Text('Aramanıza uygun çalışan bulunamadı.'));
                }
                return ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final employee = employees[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(employee.name),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditEmployeePage(employee: employee),
                          ),
                        );
                        if (result == true) _refreshEmployees();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Cleaned for Web Build by Cursor
