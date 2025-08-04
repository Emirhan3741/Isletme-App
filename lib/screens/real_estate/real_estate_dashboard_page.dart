import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/ai_chatbox_widget_modern.dart';

import '../auth/login_page.dart';

// Import placeholder pages
import 'real_estate_properties_page.dart';
import 'real_estate_clients_page.dart';
import 'real_estate_appointments_page.dart';
import 'real_estate_contracts_page.dart';
import 'real_estate_payments_page.dart';
import 'real_estate_expenses_page.dart';
import 'real_estate_calendar_page.dart';
import 'real_estate_documents_page.dart';
import 'real_estate_notes_page.dart';
import 'real_estate_reports_page.dart';
import 'real_estate_settings_page.dart';

class RealEstateDashboardPage extends StatefulWidget {
  const RealEstateDashboardPage({super.key});

  @override
  State<RealEstateDashboardPage> createState() =>
      _RealEstateDashboardPageState();
}

class _RealEstateDashboardPageState extends State<RealEstateDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'color': Colors.blue},
    {'icon': Icons.home_work, 'title': 'İlanlar', 'color': Colors.orange},
    {'icon': Icons.people, 'title': 'Müşteriler', 'color': Colors.green},
    {'icon': Icons.schedule, 'title': 'Randevular', 'color': Colors.purple},
    {'icon': Icons.description, 'title': 'Sözleşmeler', 'color': Colors.indigo},
    {'icon': Icons.calendar_today, 'title': 'Takvim', 'color': Colors.teal},
    {'icon': Icons.payment, 'title': 'Ödemeler', 'color': Colors.green[700]},
    {'icon': Icons.money_off, 'title': 'Giderler', 'color': Colors.red},
    {'icon': Icons.folder, 'title': 'Belgeler', 'color': Colors.brown},
    {'icon': Icons.note, 'title': 'Notlar', 'color': Colors.amber},
    {'icon': Icons.bar_chart, 'title': 'Raporlar', 'color': Colors.cyan},
    {'icon': Icons.settings, 'title': 'Ayarlar', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sol Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emlak Ofisi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Yönetim Paneli',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item['icon'],
                            color: isSelected ? Colors.orange : item['color'],
                            size: 20,
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.orange
                                  : const Color(0xFF475569),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          dense: true,
                        ),
                      );
                    },
                  ),
                ),

                // Logout Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ana İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : _buildPageContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const RealEstatePropertiesPage();
      case 2:
        return const RealEstateClientsPage();
      case 3:
        return const RealEstateAppointmentsPage();
      case 4:
        return const RealEstateContractsPage();
      case 5:
        return const RealEstateCalendarPage();
      case 6:
        return const RealEstatePaymentsPage();
      case 7:
        return const RealEstateExpensesPage();
      case 8:
        return const RealEstateDocumentsPage(customerId: '');
      case 9:
        return const RealEstateNotesPage();
      case 10:
        return const RealEstateReportsPage();
      case 11:
        return const RealEstateSettingsPage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emlak Ofisi Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Portföy ve müşteri yönetimi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni İlan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // İstatistik Kartları
          GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Aktif İlanlar',
                '24',
                Icons.home_work,
                Colors.orange,
                () => setState(() => _selectedIndex = 1),
              ),
              _buildStatCard(
                'Toplam Müşteri',
                '156',
                Icons.people,
                Colors.green,
                () => setState(() => _selectedIndex = 2),
              ),
              _buildStatCard(
                'Bu Ay Randevu',
                '43',
                Icons.schedule,
                Colors.purple,
                () => setState(() => _selectedIndex = 3),
              ),
              _buildStatCard(
                'Bekleyen Sözleşme',
                '8',
                Icons.description,
                Colors.indigo,
                () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Alt Kısım - Hızlı Eylemler ve Son Aktiviteler
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hızlı Eylemler
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hızlı İşlemler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickAction(
                          'Yeni İlan Ekle',
                          Icons.add_home,
                          Colors.orange,
                          () => setState(() => _selectedIndex = 1)),
                      _buildQuickAction(
                          'Müşteri Ekle',
                          Icons.person_add,
                          Colors.green,
                          () => setState(() => _selectedIndex = 2)),
                      _buildQuickAction(
                          'Randevu Planla',
                          Icons.schedule,
                          Colors.purple,
                          () => setState(() => _selectedIndex = 3)),
                      _buildQuickAction(
                          'Sözleşme Oluştur',
                          Icons.description,
                          Colors.indigo,
                          () => setState(() => _selectedIndex = 4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Son Müşteriler
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Son Müşteriler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selectedIndex = 2),
                            child: const Text('Tümünü Gör'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRecentCustomer(
                          'Ahmet Yılmaz', 'Villa araştırıyor', '2 saat önce'),
                      _buildRecentCustomer(
                          'Zeynep Kaya', 'Apart satacak', '5 saat önce'),
                      _buildRecentCustomer(
                          'Mehmet Demir', 'Dükkan kiralaycak', '1 gün önce'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey[400], size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCustomer(String name, String note, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
        
        // 🤖 AI Chatbox Widget
        const ModernAIChatboxWidget(),
      ],
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
