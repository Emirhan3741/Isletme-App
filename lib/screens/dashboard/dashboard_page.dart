// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:randevu_erp/screens/transactions/add_edit_transaction_page.dart';
import 'package:randevu_erp/screens/admin/employee_list_page.dart';
import 'package:randevu_erp/screens/transactions/transaction_list_page.dart';
import 'package:randevu_erp/screens/expenses/expense_list_page.dart';
import 'package:randevu_erp/screens/expenses/add_edit_expense_page.dart';
import 'package:randevu_erp/screens/notes/notes_list_page.dart';
import 'package:randevu_erp/screens/notes/add_edit_note_page.dart';
import 'package:randevu_erp/screens/reports/report_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Dummy pages for navigation (gerçek sayfalarınız varsa import edin)
class CustomerListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Customers')));
}
class TransactionListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Transactions')));
}
class ExpenseListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Expenses')));
}
class NotesListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Notes')));
}
class ReportDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Reports')));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  Future<int> _getCount(String collection) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCountCard(
                    title: 'Customers',
                    icon: Icons.people,
                    collection: 'customers',
                  ),
                  _DashboardCountCard(
                    title: 'Transactions',
                    icon: Icons.swap_horiz,
                    collection: 'transactions',
                  ),
                  _DashboardCountCard(
                    title: 'Expenses',
                    icon: Icons.money_off,
                    collection: 'expenses',
                  ),
                  _DashboardCountCard(
                    title: 'Notes',
                    icon: Icons.note,
                    collection: 'notes',
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

class _DashboardCountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collection;

  const _DashboardCountCard({
    required this.title,
    required this.icon,
    required this.collection,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection(collection).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Error', style: TextStyle(color: Colors.red));
                }
                final count = snapshot.data?.size ?? 0;
                return Text('$count', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Dashboard by Cursor
// Cleaned for Web Build by Cursor 