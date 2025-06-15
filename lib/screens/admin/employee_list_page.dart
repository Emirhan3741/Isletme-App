// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
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
      return employee.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             employee.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _refreshEmployees() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
                  return const Center(child: Text('Aramanıza uygun çalışan bulunamadı.'));
                }
                return ListView.separated(
                  itemCount: employees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final employee = employees[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(employee.name),
                      subtitle: Text(employee.email),
                      trailing: Text(DateFormat('dd.MM.yyyy').format(employee.createdAt)),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditEmployeePage(employee: employee),
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