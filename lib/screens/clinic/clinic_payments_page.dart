import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicPaymentsPage extends StatefulWidget {
  const ClinicPaymentsPage({super.key});

  @override
  State<ClinicPaymentsPage> createState() => _ClinicPaymentsPageState();
}

class _ClinicPaymentsPageState extends State<ClinicPaymentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPayments(), _loadPatients()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadPayments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('paymentDate', descending: true)
          .get();

      setState(() {
        _payments =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Ödemeleri yüklerken hata: $e');
    }
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPatientsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      setState(() {
        _patients =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Hastaları yüklerken hata: $e');
    }
  }

  List<Map<String, dynamic>> get filteredPayments {
    List<Map<String, dynamic>> filtered = _payments;

    if (_selectedFilter == 'gelir') {
      filtered =
          filtered.where((payment) => payment['kategori'] == 'gelir').toList();
    } else if (_selectedFilter == 'gider') {
      filtered =
          filtered.where((payment) => payment['kategori'] == 'gider').toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((payment) => (payment['description'] ?? '')
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
          // Başlık ve yeni ödeme butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'İşlemler & Ödemeler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni İşlem',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                    child: _buildStatCard('Toplam Gelir', _getTotalIncome(),
                        Colors.green, Icons.trending_up)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard('Toplam Gider', _getTotalExpense(),
                        Colors.red, Icons.trending_down)),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                    child: _buildStatCard(
                        'Net Kar',
                        _getNetProfit(),
                        _getNetProfit() >= 0 ? Colors.blue : Colors.red,
                        Icons.account_balance)),
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
                    hintText: 'İşlem ara',
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
                    _buildFilterChip('Gelir', 'gelir'),
                    _buildFilterChip('Gider', 'gider'),
                  ],
                ),
              ],
            ),
          ),

          // Ödeme listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, double value, Color color, IconData icon) {
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
            '₺${value.toStringAsFixed(0)}',
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
        selectedColor: Colors.orange.withValues(alpha: 0.2),
        checkmarkColor: Colors.orange,
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isIncome = payment['kategori'] == 'gelir';
    final color = isIncome ? Colors.green : Colors.red;
    final amount = (payment['amount'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(isIncome ? Icons.trending_up : Icons.trending_down,
              color: color),
        ),
        title: Text(payment['description'] ?? 'Açıklama yok'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment['patientName'] != null)
              Text('Hasta: ${payment['patientName']}'),
            Text('Tarih: ${_formatDate(payment['paymentDate'])}'),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}₺${amount.toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Henüz işlem kaydı yok',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('İlk işleminizi eklemek için "Yeni İşlem" butonuna tıklayın',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  double _getTotalIncome() {
    return _payments.where((p) => p['kategori'] == 'gelir').fold(0.0,
        (totalAmount, p) => totalAmount + ((p['amount'] ?? 0.0).toDouble()));
  }

  double _getTotalExpense() {
    return _payments.where((p) => p['kategori'] == 'gider').fold(0.0,
        (totalAmount, p) => totalAmount + ((p['amount'] ?? 0.0).toDouble()));
  }

  double _getNetProfit() {
    return _getTotalIncome() - _getTotalExpense();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tarih yok';
    DateTime dateTime =
        date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _AddPaymentDialog(patients: _patients, onSaved: _loadPayments),
    );
  }
}

// Ödeme ekleme dialog'u
class _AddPaymentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final VoidCallback onSaved;

  const _AddPaymentDialog({required this.patients, required this.onSaved});

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'gelir';
  String? _selectedPatientId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('Yeni İşlem',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),

              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                    labelText: 'Kategori', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'gelir', child: Text('Gelir')),
                  DropdownMenuItem(value: 'gider', child: Text('Gider')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),

              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Açıklama', border: OutlineInputBorder()),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Açıklama gerekli' : null,
              ),

              const SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                    labelText: 'Tutar (₺)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isEmpty == true) return 'Tutar gerekli';
                  if (double.tryParse(value!) == null)
                    return 'Geçerli tutar girin';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Hasta seçimi (sadece gelir için)
              if (_selectedCategory == 'gelir')
                DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: const InputDecoration(
                      labelText: 'Hasta (İsteğe bağlı)',
                      border: OutlineInputBorder()),
                  items:
                      widget.patients.map<DropdownMenuItem<String>>((patient) {
                    return DropdownMenuItem<String>(
                        value: patient['id'],
                        child: Text(patient['name'] ?? 'İsim yok'));
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedPatientId = value),
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
                      onPressed: _isLoading ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Kaydet'),
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

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final paymentData = {
        'userId': user.uid,
        'kategori': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'amount': double.parse(_amountController.text.trim()),
        'paymentDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
      };

      if (_selectedPatientId != null) {
        final patient =
            widget.patients.firstWhere((p) => p['id'] == _selectedPatientId);
        paymentData['patientId'] = _selectedPatientId!;
        paymentData['patientName'] = patient['name'];
      }

      await FirebaseFirestore.instance
          .collection(AppConstants.clinicPaymentsCollection)
          .add(paymentData);

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('İşlem kaydedildi'), backgroundColor: Colors.green),
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
