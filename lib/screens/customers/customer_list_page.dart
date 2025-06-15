import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import 'add_edit_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({Key? key}) : super(key: key);

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerModel> _filterCustomers(List<CustomerModel> customers) {
    if (_searchQuery.isEmpty) return customers;
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (customer.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  Future<void> _refreshCustomers() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditCustomerPage()),
              );
              if (result == true) _refreshCustomers();
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
            child: FutureBuilder<List<CustomerModel>>(
              future: _customerService.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Kayıtlı müşteri yok.'));
                }
                final customers = _filterCustomers(snapshot.data!);
                if (customers.isEmpty) {
                  return const Center(child: Text('Aramanıza uygun müşteri bulunamadı.'));
                }
                return ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final customer = customers[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(customer.name),
                      subtitle: Text(customer.email ?? ''),
                      trailing: Text(DateFormat('dd.MM.yyyy').format(customer.createdAt)),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditCustomerPage(customer: customer),
                          ),
                        );
                        if (result == true) _refreshCustomers();
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