// CodeRabbit analyze fix: Dosya düzenlendi
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'add_edit_employee_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<UserModel> _allEmployees = [];
  List<UserModel> _filteredEmployees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterEmployees();
    });
  }

  void _filterEmployees() {
    if (_searchQuery.isEmpty) {
      _filteredEmployees = List.from(_allEmployees);
    } else {
      _filteredEmployees = _allEmployees.where((employee) {
        return employee.adSoyad.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               employee.eposta.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               employee.rol.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employees = await _userService.getAllEmployees();
      setState(() {
        _allEmployees = employees;
        _filterEmployees();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çalışanlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditEmployeePage(),
      ),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _navigateToEditEmployee(UserModel employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditEmployeePage(employee: employee),
      ),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _deleteEmployee(UserModel employee) async {
    // Onay diyalogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çalışanı Sil'),
        content: Text(
          '${employee.adSoyad} adlı çalışanı silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _userService.deleteEmployee(employee.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Çalışan başarıyla silindi'),
                backgroundColor: Colors.green,
              ),
            );
            _loadEmployees();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Çalışan silinirken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEmployeeDetails(UserModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Profil başlığı
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: employee.rol == UserRole.owner 
                        ? Colors.amber[100] 
                        : Colors.blue[100],
                    child: Icon(
                      employee.rol == UserRole.owner 
                          ? Icons.admin_panel_settings 
                          : Icons.person,
                      size: 30,
                      color: employee.rol == UserRole.owner 
                          ? Colors.amber[800] 
                          : Colors.blue[800],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.adSoyad,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          employee.rol.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: employee.rol == UserRole.owner 
                                ? Colors.amber[800] 
                                : Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Detaylar
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem(
                      icon: Icons.email,
                      title: 'E-posta',
                      value: employee.eposta,
                      color: Colors.blue,
                    ),
                    _buildDetailItem(
                      icon: Icons.badge,
                      title: 'Kullanıcı ID',
                      value: employee.id.substring(0, 8) + '...',
                      color: Colors.grey,
                    ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      title: 'Kayıt Tarihi',
                      value: DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                          .format(employee.oluşturulmaTarihi.toDate()),
                      color: Colors.green,
                    ),
                    _buildDetailItem(
                      icon: Icons.access_time,
                      title: 'Son Giriş',
                      value: DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                          .format(employee.lastSignIn),
                      color: Colors.orange,
                    ),
                    if (employee.photoURL != null)
                      _buildDetailItem(
                        icon: Icons.photo,
                        title: 'Profil Fotoğrafı',
                        value: 'Mevcut',
                        color: Colors.purple,
                      ),
                  ],
                ),
              ),

              // Action buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEditEmployee(employee);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Düzenle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (employee.rol == UserRole.worker) // Sadece worker'ları silebilir
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteEmployee(employee);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Sil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışan Yönetimi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEmployee,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // Arama ve istatistikler
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Çalışan ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // İstatistikler
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Toplam',
                        _allEmployees.length.toString(),
                        Icons.group,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Yönetici',
                        _allEmployees.where((e) => e.rol == UserRole.owner).length.toString(),
                        Icons.admin_panel_settings,
                        Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Çalışan',
                        _allEmployees.where((e) => e.rol == UserRole.worker).length.toString(),
                        Icons.person,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Çalışan listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadEmployees,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(UserModel employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: employee.rol == UserRole.owner 
              ? Colors.amber[100] 
              : Colors.blue[100],
          child: Icon(
            employee.rol == UserRole.owner 
                ? Icons.admin_panel_settings 
                : Icons.person,
            color: employee.rol == UserRole.owner 
                ? Colors.amber[800] 
                : Colors.blue[800],
          ),
        ),
        title: Text(
          employee.adSoyad,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(employee.eposta),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: employee.rol == UserRole.owner 
                        ? Colors.amber[100] 
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    employee.rol.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: employee.rol == UserRole.owner 
                          ? Colors.amber[800] 
                          : Colors.blue[800],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd.MM.yyyy').format(employee.oluşturulmaTarihi.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                _showEmployeeDetails(employee);
                break;
              case 'edit':
                _navigateToEditEmployee(employee);
                break;
              case 'delete':
                if (employee.rol == UserRole.worker) {
                  _deleteEmployee(employee);
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('Detaylar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Düzenle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (employee.rol == UserRole.worker)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Sil', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        onTap: () => _showEmployeeDetails(employee),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Arama kriterlerine uygun çalışan bulunamadı'
                : 'Henüz çalışan eklenmemiş',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Farklı anahtar kelimeler deneyin'
                : 'İlk çalışanını eklemek için + butonuna dokunun',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}