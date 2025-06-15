import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _dashboardItems = [
    {
      'title': 'Müşteriler',
      'subtitle': 'Müşteri yönetimi',
      'icon': Icons.people,
      'color': Colors.blue,
      'count': '0',
    },
    {
      'title': 'İşlemler',
      'subtitle': 'Gelir ve giderler',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'count': '0',
    },
    {
      'title': 'Notlar',
      'subtitle': 'Görevler ve notlar',
      'icon': Icons.note,
      'color': Colors.orange,
      'count': '0',
    },
    {
      'title': 'Giderler',
      'subtitle': 'İşletme giderleri',
      'icon': Icons.shopping_cart,
      'color': Colors.red,
      'count': '0',
    },
    {
      'title': 'Raporlar',
      'subtitle': 'Finansal raporlar',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'count': '0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu ERP'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundImage: authProvider.user?.photoURL != null
                      ? NetworkImage(authProvider.user!.photoURL!)
                      : null,
                  child: authProvider.user?.photoURL == null
                      ? Text(
                          authProvider.user?.displayName.isNotEmpty == true
                              ? authProvider.user!.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.user?.displayName ?? 'Kullanıcı',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              authProvider.user?.email ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Çıkış Yap'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin mesajı
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoş geldiniz, ${authProvider.user?.displayName ?? 'Kullanıcı'}!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'İşletme yönetim sisteminize erişim sağlandı',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Hızlı erişim kartları
            Text(
              'Hızlı Erişim',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Grid view için responsive yapı
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth > 600) crossAxisCount = 3;
                if (constraints.maxWidth > 900) crossAxisCount = 4;
                if (constraints.maxWidth > 1200) crossAxisCount = 5;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _dashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = _dashboardItems[index];
                    return _buildDashboardCard(item);
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Platform bilgisi
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  color: authProvider.isFirebaseSupported 
                      ? Colors.green.shade50 
                      : Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          authProvider.isFirebaseSupported 
                              ? Icons.cloud 
                              : Icons.storage,
                          color: authProvider.isFirebaseSupported 
                              ? Colors.green 
                              : Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.isFirebaseSupported 
                                    ? 'Bulut Depolama Aktif' 
                                    : 'Yerel Depolama Aktif',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                authProvider.isFirebaseSupported 
                                    ? 'Verileriniz Firebase\'de güvenle saklanıyor'
                                    : 'Verileriniz bilgisayarınızda güvenle saklanıyor',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Sayfalar oluşturulduktan sonra navigasyon eklenecek
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item['title']} modülü henüz hazır değil'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'],
                  size: 32,
                  color: item['color'],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['count'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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