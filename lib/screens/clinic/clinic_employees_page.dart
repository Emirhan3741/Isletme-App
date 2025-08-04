import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicEmployeesPage extends StatefulWidget {
  const ClinicEmployeesPage({super.key});

  @override
  State<ClinicEmployeesPage> createState() => _ClinicEmployeesPageState();
}

class _ClinicEmployeesPageState extends State<ClinicEmployeesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicEmployeesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('name')
          .get();

      setState(() {
        _employees =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Çalışanları yüklerken hata: $e');
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get filteredEmployees {
    List<Map<String, dynamic>> filtered = _employees;

    if (_selectedFilter == 'aktif') {
      filtered = filtered.where((emp) => emp['isActive'] == true).toList();
    } else if (_selectedFilter == 'pasif') {
      filtered = filtered.where((emp) => emp['isActive'] == false).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((emp) =>
              (emp['name'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (emp['position'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Başlık ve yeni çalışan butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Çalışanlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEmployeeDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni Çalışan',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // İstatistik kartları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard('Toplam Çalışan', _employees.length,
                        Colors.blue, Icons.people)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard('Aktif', _getActiveEmployeeCount(),
                        Colors.green, Icons.person)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard('Pasif', _getInactiveEmployeeCount(),
                        Colors.red, Icons.person_off)),
              ],
            ),
          ),

          // Arama ve filtreler
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Çalışan ara (Ad, pozisyon)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('Tümü', 'tumu'),
                    _buildFilterChip('Aktif', 'aktif'),
                    _buildFilterChip('Pasif', 'pasif'),
                  ],
                ),
              ],
            ),
          ),

          // Çalışan listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEmployees.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          return _buildEmployeeCard(employee);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(title,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedFilter = value),
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.indigo.withValues(alpha: 0.2),
        checkmarkColor: Colors.indigo,
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final isActive = employee['isActive'] ?? true;
    final salary = (employee['salary'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.person : Icons.person_off,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(employee['name'] ?? 'Ad yok'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pozisyon: ${employee['position'] ?? 'Belirtilmemiş'}'),
            Text('Telefon: ${employee['phone'] ?? 'Yok'}'),
            if (salary > 0) Text('Maaş: ₺${salary.toStringAsFixed(0)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? Colors.green : Colors.red),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditEmployeeDialog(employee),
            ),
          ],
        ),
        onTap: () => _showEmployeeDetail(employee),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Henüz çalışan kaydı yok',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('İlk çalışanınızı eklemek için "Yeni Çalışan" butonuna tıklayın',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  int _getActiveEmployeeCount() {
    return _employees.where((emp) => emp['isActive'] == true).length;
  }

  int _getInactiveEmployeeCount() {
    return _employees.where((emp) => emp['isActive'] == false).length;
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditEmployeeDialog(onSaved: _loadEmployees),
    );
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) =>
          _AddEditEmployeeDialog(employee: employee, onSaved: _loadEmployees),
    );
  }

  void _showEmployeeDetail(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee['name'] ?? 'Çalışan Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pozisyon: ${employee['position'] ?? 'Belirtilmemiş'}'),
            Text('Telefon: ${employee['phone'] ?? 'Yok'}'),
            Text('E-posta: ${employee['email'] ?? 'Yok'}'),
            Text('Maaş: ₺${(employee['salary'] ?? 0.0).toStringAsFixed(0)}'),
            Text('Durum: ${employee['isActive'] == true ? 'Aktif' : 'Pasif'}'),
            if (employee['startDate'] != null)
              Text('Başlangıç Tarihi: ${_formatDate(employee['startDate'])}'),
            if (employee['notes'] != null && employee['notes'].isNotEmpty)
              Text('Notlar: ${employee['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tarih yok';
    DateTime dateTime =
        date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }
}

// Çalışan ekleme/düzenleme dialog'u
class _AddEditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final VoidCallback onSaved;

  const _AddEditEmployeeDialog({this.employee, required this.onSaved});

  @override
  State<_AddEditEmployeeDialog> createState() => _AddEditEmployeeDialogState();
}

class _AddEditEmployeeDialogState extends State<_AddEditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() {
    final emp = widget.employee!;
    _nameController.text = emp['name'] ?? '';
    _positionController.text = emp['position'] ?? '';
    _phoneController.text = emp['phone'] ?? '';
    _emailController.text = emp['email'] ?? '';
    _salaryController.text = (emp['salary'] ?? 0.0).toString();
    _notesController.text = emp['notes'] ?? '';
    _isActive = emp['isActive'] ?? true;
    if (emp['startDate'] != null) {
      _startDate = emp['startDate'] is Timestamp
          ? emp['startDate'].toDate()
          : DateTime.parse(emp['startDate'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_add, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            isEditing ? 'Çalışan Düzenle' : 'Yeni Çalışan',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),

                // Ad
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Ad Soyad *', border: OutlineInputBorder()),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Ad gerekli' : null,
                ),

                const SizedBox(height: 16),

                // Pozisyon
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                      labelText: 'Pozisyon *', border: OutlineInputBorder()),
                  validator: (value) =>
                      value?.trim().isEmpty == true ? 'Pozisyon gerekli' : null,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    // Telefon
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            labelText: 'Telefon', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Maaş
                    Expanded(
                      child: TextFormField(
                        controller: _salaryController,
                        decoration: const InputDecoration(
                            labelText: 'Maaş (₺)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // E-posta
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: 'E-posta', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Durum
                SwitchListTile(
                  title: const Text('Aktif Çalışan'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),

                const SizedBox(height: 16),

                // Notlar
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                      labelText: 'Notlar', border: OutlineInputBorder()),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEmployee,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(isEditing ? 'Güncelle' : 'Kaydet'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final employeeData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'position': _positionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'salary': double.tryParse(_salaryController.text.trim()) ?? 0.0,
        'notes': _notesController.text.trim(),
        'isActive': _isActive,
        'startDate': Timestamp.fromDate(_startDate),
        'updatedAt': Timestamp.now(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicEmployeesCollection)
            .doc(widget.employee!['id'])
            .update(employeeData);
      } else {
        employeeData['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicEmployeesCollection)
            .add(employeeData);
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isEditing ? 'Çalışan güncellendi' : 'Çalışan eklendi'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
