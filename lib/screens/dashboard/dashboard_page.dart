// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

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