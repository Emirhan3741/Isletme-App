import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';


import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyCustomerListPage extends StatefulWidget {
  const BeautyCustomerListPage({super.key});

  @override
  State<BeautyCustomerListPage> createState() => _BeautyCustomerListPageState();
}

class _BeautyCustomerListPageState extends State<BeautyCustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  String _searchQuery = '';
  List<CustomerModel> _customers = [];
  bool _isLoading = true;
  int _totalCustomers = 0;
  int _newThisMonth = 0;
  int _vipCustomers = 0;

  @override
  void initState() {
    super.initState();
    _initializeSalon();
    _loadCustomers();
  }

  Future<void> _initializeSalon() async {
    try {
      await _customerService.initializeSalon();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salon başlatma hatası: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final customers = await _customerService.getCustomers();

      // İstatistikleri hesapla
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);

      setState(() {
        _customers = customers;
        _totalCustomers = customers.length;
        _newThisMonth =
            customers.where((c) => c.createdAt.isAfter(thisMonth)).length;
        _vipCustomers = customers.where((c) => c.totalSpent > 1000).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.customersLoadError}: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  List<CustomerModel> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;

    // Özel filtreler
    if (_searchQuery == 'vip') {
      return _customers
          .where((customer) => customer.totalSpent > 1000)
          .toList();
    }
    if (_searchQuery == 'debt') {
      return _customers.where((customer) => customer.debtAmount > 0).toList();
    }
    if (_searchQuery == 'new') {
      final thisMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      return _customers
          .where((customer) => customer.createdAt.isAfter(thisMonth))
          .toList();
    }

    // Normal arama
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.phone.contains(_searchQuery) ||
          customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.customerTag
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.customers,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve İstatistikler
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Arama Çubuğu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        "${localizations.search} (${localizations.customerName}, ${localizations.phoneNumber}, ${localizations.email})...",
                    prefixIcon: const Icon(Icons.search_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                      borderSide:
                          const BorderSide(color: AppConstants.textLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                      borderSide:
                          const BorderSide(color: AppConstants.textLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                      borderSide: const BorderSide(
                          color: AppConstants.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppConstants.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingMedium,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // İstatistik Kartları
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: localizations.totalCustomers,
                        value: _totalCustomers.toString(),
                        icon: Icons.people_outline,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.newThisMonth,
                        value: _newThisMonth.toString(),
                        icon: Icons.person_add_outlined,
                        color: AppConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.vipCustomers,
                        value: _vipCustomers.toString(),
                        icon: Icons.star_outline,
                        color: AppConstants.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Müşteri Listesi
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              size: 64,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "Arama sonucu bulunamadı"
                                  : "Henüz müşteri eklenmemiş",
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              ElevatedButton.icon(
                                onPressed: _addNewCustomer,
                                icon: const Icon(Icons.add),
                                label: const Text("İlk müşteriyi ekle"),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            return _CustomerCard(
                              customer: customer,
                              onTap: () => _showCustomerDetails(customer),
                              onEdit: () => _editCustomer(customer),
                              onDelete: () => _deleteCustomer(customer.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewCustomer,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Yeni Müşteri",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filtrele"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text("VIP Müşteriler"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = 'vip';
                });
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.warning, color: AppConstants.errorColor),
              title: const Text("Borçlu Müşteriler"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = 'debt';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.new_releases),
              title: const Text("Bu Ay Yeni"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = 'new';
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text("Filtreyi Temizle"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Telefon: ${customer.phone}"),
            if (customer.email.isNotEmpty) Text("Email: ${customer.email}"),
            if (customer.birthDate != null)
              Text("Doğum Tarihi: ${_formatDate(customer.birthDate!)}"),
            if (customer.lastVisit != null)
              Text("Son Ziyaret: ${_formatDate(customer.lastVisit!)}"),
            Text("Toplam Harcama: ₺${customer.totalSpent.toStringAsFixed(2)}"),
            if (customer.debtAmount > 0)
              Text("Borç: ₺${customer.debtAmount.toStringAsFixed(2)}"),
            Text("Ziyaret Sayısı: ${customer.totalVisits}"),
            Text("Müşteri Seviyesi: ${customer.loyaltyLevel}"),
            if (customer.customerTag.isNotEmpty)
              Text("Etiket: ${customer.customerTag}"),
            if (customer.notes.isNotEmpty) Text("Notlar: ${customer.notes}"),
            Text("Kayıt Tarihi: ${_formatDate(customer.createdAt)}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editCustomer(customer);
            },
            child: const Text("Düzenle"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _formatDateShort(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}";
  }

  void _addNewCustomer() {
    showDialog(
      context: context,
      builder: (context) => _EnhancedCustomerForm(
        onSaved: () {
          Navigator.pop(context);
          _loadCustomers(); // Müşteri listesini yenile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Müşteri başarıyla eklendi"),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _editCustomer(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => _EnhancedCustomerForm(
        customerId: customer.id,
        onSaved: () {
          Navigator.pop(context);
          _loadCustomers(); // Müşteri listesini yenile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Müşteri başarıyla güncellendi"),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _deleteCustomer(String customerId) {
    final localizations = AppLocalizations.of(context)!;

    // Validate customerId before showing dialog
    if (customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geçersiz müşteri ID: Müşteri silinemiyor'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteCustomerTitle),
        content: Text(localizations.deleteCustomerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _customerService.deleteCustomer(customerId);
                if (mounted) {
                  Navigator.pop(context);
                  _loadCustomers(); // Listeyi yenile
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.customerDeletedSuccess),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${localizations.deleteError}: $e'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppConstants.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                          ),
                          if (customer.totalSpent > 1000) // VIP müşteri
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.warningColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (customer.debtAmount > 0) // Borçlu müşteri
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.errorColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'BORÇ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (customer.email.isNotEmpty)
                        Text(
                          customer.email,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppConstants.textSecondary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: AppConstants.errorColor),
                          const SizedBox(width: 8),
                          Text('Sil',
                              style: TextStyle(color: AppConstants.errorColor)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: customer.lastVisit != null
                        ? "Son: ${customer.lastVisit!.day.toString().padLeft(2, '0')}.${customer.lastVisit!.month.toString().padLeft(2, '0')}"
                        : "İlk ziyaret",
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.attach_money_outlined,
                    label: customer.debtAmount > 0
                        ? "Borç: ₺${customer.debtAmount.toStringAsFixed(0)}"
                        : "₺${customer.totalSpent.toStringAsFixed(0)}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.repeat_outlined,
                    label: "${customer.totalVisits} ziyaret",
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.star_outline,
                    label: customer.loyaltyLevel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppConstants.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedCustomerForm extends StatefulWidget {
  final String? customerId;
  final VoidCallback onSaved;

  const _EnhancedCustomerForm({
    this.customerId,
    required this.onSaved,
  });

  @override
  State<_EnhancedCustomerForm> createState() => _EnhancedCustomerFormState();
}

class _EnhancedCustomerFormState extends State<_EnhancedCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _customerTagController = TextEditingController();
  final _debtAmountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  String _selectedGender = 'Kadın';
  DateTime? _selectedBirthDate;
  List<Map<String, dynamic>> _attachedFiles = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _hasLoadedData = false;

  final List<String> _genderOptions = ['Kadın', 'Erkek', 'Belirtmek İstemiyor'];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customerId != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditMode && !_hasLoadedData) {
      _hasLoadedData = true;
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    if (widget.customerId == null) return;

    try {
      setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final customer = CustomerModel.fromMap({...data, 'id': doc.id});

        // Form alanlarını doldur
        final nameParts = customer.name.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        _lastNameController.text =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        _phoneController.text = customer.phone;
        _emailController.text = customer.email;
        _customerTagController.text = customer.customerTag;
        _debtAmountController.text = customer.debtAmount.toString();
        _notesController.text = customer.notes;

        setState(() {
          _selectedGender = data['gender'] ?? 'Kadın';
          _selectedBirthDate = customer.birthDate;
          _attachedFiles =
              List<Map<String, dynamic>>.from(data['attachedFiles'] ?? []);
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müşteri bilgileri yüklenirken hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _customerTagController.dispose();
    _debtAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Icon(
                        _isEditMode ? Icons.edit : Icons.person_add,
                        color: AppConstants.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditMode ? 'Müşteri Düzenle' : 'Yeni Müşteri Ekle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Form
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kişisel Bilgiler Bölümü
                            _buildSectionTitle(
                                'Kişisel Bilgiler', Icons.person),
                            const SizedBox(height: 16),

                            // Ad Soyad
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ad *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ad gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Soyad *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Soyad gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Telefon ve Cinsiyet
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon Numarası *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone_outlined),
                                      hintText: '05XX XXX XX XX',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Telefon numarası gerekli';
                                      }
                                      if (value.length < 10) {
                                        return 'Geçerli telefon numarası girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: const InputDecoration(
                                      labelText: 'Cinsiyet',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.person_pin_outlined),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    isExpanded: true,
                                    items: _genderOptions
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(
                                              gender,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Email ve Doğum Tarihi
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value)) {
                                          return 'Geçerli email adresi girin';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectBirthDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Doğum Tarihi',
                                        border: OutlineInputBorder(),
                                        prefixIcon:
                                            Icon(Icons.calendar_today_outlined),
                                      ),
                                      child: Text(
                                        _selectedBirthDate != null
                                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                            : 'Tarih seçin',
                                        style: TextStyle(
                                          color: _selectedBirthDate != null
                                              ? Colors.black87
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // İş Bilgileri Bölümü
                            _buildSectionTitle('İş Bilgileri', Icons.business),
                            const SizedBox(height: 16),

                            // Etiket ve Borç Tutarı
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _customerTagController,
                                    decoration: const InputDecoration(
                                      labelText: 'Müşteri Etiketi',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.label_outline),
                                      hintText: 'VIP, Düzenli, Yeni vb.',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _debtAmountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Borç Tutarı (₺)',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons
                                          .account_balance_wallet_outlined),
                                      hintText: '0.00',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (double.tryParse(value) == null) {
                                          return 'Geçerli tutar girin';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Notlar
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note_outlined),
                                hintText: 'Müşteri hakkında özel notlar...',
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 24),

                            // Dosyalar Bölümü
                            _buildSectionTitle('Dosyalar', Icons.attach_file),
                            const SizedBox(height: 16),

                            // Dosya Ekleme Butonu
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label:
                                  const Text('Dosya Ekle (JPEG, PDF, Excel)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor
                                    .withValues(alpha: 0.1),
                                foregroundColor: AppConstants.primaryColor,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Ekli Dosyalar Listesi
                            if (_attachedFiles.isNotEmpty) ...[
                              const Text(
                                'Ekli Dosyalar:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_attachedFiles.length, (index) {
                                final file = _attachedFiles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getFileIcon(file['extension']),
                                        color: AppConstants.primaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file['name'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '${file['extension'].toUpperCase()}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeFile(index),
                                        icon: const Icon(Icons.delete_outline),
                                        color: AppConstants.errorColor,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveCustomer,
                        child: Text(_isEditMode ? 'Güncelle' : 'Kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  Future<void> _pickFile() async {
    // Basit dosya seçimi simülasyonu
    final fileName = 'dosya_${DateTime.now().millisecondsSinceEpoch}';
    final fileData = {
      'name': '$fileName.pdf',
      'extension': 'pdf',
      'uploadedAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _attachedFiles.add(fileData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosya eklendi (demo)'),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.description;
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Kullanıcı oturumu bulunamadı';

      final debtAmount = double.tryParse(_debtAmountController.text) ?? 0.0;

      // Create CustomerModel for CustomerService
      final customer = CustomerModel(
        id: _isEditMode ? widget.customerId! : '',
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        customerTag: _customerTagController.text.trim(),
        debtAmount: debtAmount,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        totalSpent: 0.0,
        totalVisits: 0,
        lastVisit: null,
      );

      if (_isEditMode) {
        await _customerService.updateCustomer(customer);
      } else {
        await _customerService.addCustomer(customer);
      }

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
