import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/customer_service.dart';
import '../customers/customer_list_page.dart';
import '../customers/add_edit_customer_page.dart';
import '../appointments/calendar_page.dart';
import '../../lib/screens/transactions/transaction_list_page.dart';
import '../transactions/add_edit_transaction_page.dart';
import '../../lib/screens/expenses/expense_list_page.dart';
import '../../lib/screens/expenses/add_edit_expense_page.dart';
import '../../lib/screens/notes/notes_list_page.dart';
import '../../lib/screens/notes/add_edit_note_page.dart';
import '../../lib/screens/reports/report_dashboard_page.dart';
import '../../lib/screens/admin/employee_list_page.dart';
import '../../services/appointment_service.dart';
import '../../lib/services/note_service.dart';
import '../../lib/services/user_service.dart';
import '../../models/user_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const CustomersPage(),
    const CalendarPage(),
    const PaymentsPage(),
    const ExpensesPage(),
    const NotesPage(),
    const ReportsPage(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Ana Sayfa',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people_outlined),
      activeIcon: Icon(Icons.people),
      label: 'Müşteriler',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      activeIcon: Icon(Icons.calendar_today),
      label: 'Randevular',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.payment_outlined),
      activeIcon: Icon(Icons.payment),
      label: 'Ödemeler',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long),
      label: 'Giderler',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.note_outlined),
      activeIcon: Icon(Icons.note),
      label: 'Notlar',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      activeIcon: Icon(Icons.analytics),
      label: 'Raporlar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu ERP'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Bildirimler sayfası
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    authProvider.user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.person_outlined),
                      title: const Text('Profil'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        // Profil sayfasına yönlendir
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Ayarlar'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        // Ayarlar sayfasına yönlendir
                      },
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.logout_outlined),
                      title: const Text('Çıkış Yap'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context, authProvider);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: _navItems.take(4).toList(), // Mobilde sadece 4 item
            )
          : null,
      drawer: MediaQuery.of(context).size.width < 600 ? _buildDrawer() : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Randevu ERP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ..._buildDrawerItems(),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    final items = [
      {'icon': Icons.dashboard, 'title': 'Ana Sayfa', 'index': 0},
      {'icon': Icons.people, 'title': 'Müşteriler', 'index': 1},
      {'icon': Icons.calendar_today, 'title': 'Randevular', 'index': 2},
      {'icon': Icons.payment, 'title': 'Ödemeler', 'index': 3},
      {'icon': Icons.receipt_long, 'title': 'Giderler', 'index': 4},
      {'icon': Icons.note, 'title': 'Notlar', 'index': 5},
      {'icon': Icons.analytics, 'title': 'Raporlar', 'index': 6},
    ];

    return items.map((item) {
      return ListTile(
        leading: Icon(item['icon'] as IconData),
        title: Text(item['title'] as String),
        selected: _selectedIndex == item['index'],
        onTap: () {
          setState(() {
            _selectedIndex = item['index'] as int;
          });
          Navigator.pop(context);
        },
      );
    }).toList();
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.signOut();
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
}

// Ana sayfa içeriği
class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final CustomerService _customerService = CustomerService();
  final AppointmentService _appointmentService = AppointmentService();
  final NoteService _noteService = NoteService();
  final UserService _userService = UserService();
  
  int _customerCount = 0;
  int _todayAppointmentCount = 0;
  int _totalAppointmentCount = 0;
  int _totalNotesCount = 0;
  int _pendingNotesCount = 0;
  int _totalEmployeeCount = 0;
  bool _isOwner = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadCustomerCount(),
      _loadAppointmentCounts(),
      _loadNoteCounts(),
    ]);
  }

  Future<void> _loadUserInfo() async {
    try {
      final userProfile = await _userService.getCurrentUserProfile();
      final isOwner = await _userService.isCurrentUserOwner();
      final employeeCount = await _userService.getUserCount();
      
      if (mounted) {
        setState(() {
          _currentUser = userProfile;
          _isOwner = isOwner;
          _totalEmployeeCount = employeeCount;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler kalır
    }
  }

  Future<void> _loadCustomerCount() async {
    try {
      final count = await _customerService.getCustomerCount();
      if (mounted) {
        setState(() {
          _customerCount = count;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değer 0 kalır
    }
  }

  Future<void> _loadAppointmentCounts() async {
    try {
      final todayCount = await _appointmentService.getTodayAppointmentCount();
      final totalCount = await _appointmentService.getAppointmentCount();
      
      if (mounted) {
        setState(() {
          _todayAppointmentCount = todayCount;
          _totalAppointmentCount = totalCount;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler 0 kalır
    }
  }

  Future<void> _loadNoteCounts() async {
    try {
      final totalNotes = await _noteService.getTotalNotesCount();
      final pendingNotes = await _noteService.getPendingNotesCount();
      
      if (mounted) {
        setState(() {
          _totalNotesCount = totalNotes;
          _pendingNotesCount = pendingNotes;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler 0 kalır
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoşgeldin kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      size: 32,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoşgeldiniz!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUser?.adSoyad ?? authProvider.user?.displayName ?? 'Kullanıcı',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (_currentUser != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isOwner ? Colors.amber[100] : Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _currentUser!.rol.displayName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _isOwner ? Colors.amber[800] : Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İstatistik kartları
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  context,
                  'Bugünün Randevuları',
                  _todayAppointmentCount.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Toplam Müşteri',
                  _customerCount.toString(),
                  Icons.people,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Toplam Notlar',
                  _totalNotesCount.toString(),
                  Icons.note,
                  Colors.purple,
                ),
                if (_isOwner)
                  _buildStatCard(
                    context,
                    'Toplam Çalışan',
                    _totalEmployeeCount.toString(),
                    Icons.group,
                    Colors.indigo,
                  )
                else
                  _buildStatCard(
                    context,
                    'Bekleyen Notlar',
                    _pendingNotesCount.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hızlı işlemler
            Text(
              'Hızlı İşlemler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickAction(
                  context,
                  'Yeni Randevu',
                  Icons.add_box,
                  Colors.blue,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CalendarPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  'Yeni Müşteri',
                  Icons.person_add,
                  Colors.green,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditCustomerPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  'Yeni İşlem',
                  Icons.payment,
                  Colors.orange,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditTransactionPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  'Yeni Gider',
                  Icons.receipt_long,
                  Colors.red,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditExpensePage(),
                      ),
                    );
                  },
                ),
                _buildQuickAction(
                  context,
                  'Yeni Not',
                  Icons.note_add,
                  Colors.purple,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditNotePage(),
                      ),
                    );
                  },
                ),
                if (_isOwner)
                  _buildQuickAction(
                    context,
                    'Çalışan Yönetimi',
                    Icons.admin_panel_settings,
                    Colors.indigo,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmployeeListPage(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder sayfalar
class CustomersPage extends StatelessWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CustomerListPage();
  }
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CalendarPage();
  }
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TransactionListPage();
  }
}

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ExpenseListPage();
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const NotesListPage();
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ReportDashboardPage();
  }
} 