// Refactored by Cursor

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:printing/printing.dart'; // Package not added to dependencies

import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../utils/export_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // _loadCustomers metodu kaldırıldı - Stream kullanılacak

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// 🔍 Filtered Customers Getter
  List<CustomerModel> get _filteredCustomers {
    // StreamBuilder kullanıldığı için burada mock data döndürüyoruz
    // Gerçek filtering logic StreamBuilder içinde yapılacak
    return [];
  }

  /// 👤 User Getter
  UserModel? get user {
    // Firebase Auth'dan current user alıp UserModel'e convert et
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return UserModel(
        id: currentUser.uid,
        name: currentUser.displayName ?? 'Admin',
        email: currentUser.email ?? '',
        role: 'admin',
        sector: 'admin',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  List<CustomerModel> _getFilteredCustomers(List<CustomerModel> customers) {
    if (_searchQuery.isEmpty) return customers;

    return customers.where((customer) {
      final fullName =
          '${customer.firstName} ${customer.lastName}'.toLowerCase();
      final email = customer.email.toLowerCase();
      final phone = customer.phone.toLowerCase();
      final searchQuery = _searchQuery.toLowerCase();

      return fullName.contains(searchQuery) ||
          email.contains(searchQuery) ||
          phone.contains(searchQuery);
    }).toList();
  }

  Future<void> _deleteCustomer(String customerId) async {
    try {
      await _customerService.deleteCustomer(customerId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Müşteri silindi'),
          backgroundColor: AppConstants.successColor,
        ),
      );

      // Stream will automatically update the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _exportCsv() async {
    try {
      if (!kIsWeb) {
        final csv = ExportUtils.customersToCsv(_filteredCustomers);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/customer_export.csv');
        await file.writeAsString(csv);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('CSV dosyası oluşturuldu.'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export hatası: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      if (!kIsWeb) {
        final pdfBytes = await ExportUtils.customersToPdf(_filteredCustomers);
        // await Printing.layoutPdf(onLayout: (format) async => pdfBytes); // Package not added
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export hatası: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportJson() async {
    try {
      final jsonStr = ExportUtils.allDataToJson(
          {'customers': _filteredCustomers.map((c) => c.toMap()).toList()});
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/customer_backup.json');
        await file.writeAsString(jsonStr);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('JSON yedeği oluşturuldu.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('JSON export hatası: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showAddCustomerModal() {
    showDialog(
      context: context,
      builder: (context) => AddCustomerModal(
        onSaved: () {
          // Stream will automatically update after addition
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditCustomerModal(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => EditCustomerModal(
        customer: customer,
        onSaved: () {
          // Stream will automatically update after edit
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _confirmDeleteCustomer(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        title: Text(
          "Müşteri Sil",
          style: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "${customer.name} adlı müşteriyi silmek istediğinizden emin misiniz?",
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "İptal",
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              ),
            ),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        title: Text(
          "Müşteriler",
          style: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                // Dashboard'a yönlendirme
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Arama kutusu
            CommonCard(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterCustomers,
                      decoration: InputDecoration(
                        hintText: "müşteri ara...",
                        prefixIcon: const Icon(Icons.search),
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
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: Text(
                      "Etiket",
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Tüm Etiketler",
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: AppConstants.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Müşteri listesi
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: _customerService.getCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final customers = snapshot.data ?? [];
                  final filteredCustomers = _getFilteredCustomers(customers);

                  if (filteredCustomers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppConstants.paddingMedium,
                        ),
                        child: _buildCustomerCard(customer),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return CommonCard(
      onTap: () => _showEditCustomerModal(customer),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Icon(
                Icons.person,
                color: AppConstants.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (customer.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 14,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppConstants.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "KAYIT TARİHİ",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Bugün", // TODO: Gerçek tarih
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "BORÇ",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₺0,00", // TODO: Gerçek borç tutarı
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "İŞLEMLER",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppConstants.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCustomerModal(customer);
                        break;
                      case 'delete':
                        _confirmDeleteCustomer(customer);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Düzenle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: AppConstants.errorColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            decoration: BoxDecoration(
              color: AppConstants.textSecondary.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusXLarge),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            _searchController.text.isNotEmpty
                ? "Henüz müşteri bulunmuyor"
                : "Henüz müşteri bulunmuyor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchController.text.isNotEmpty
                ? "İlk müşterinizi ekleyerek başlayın."
                : "İlk müşterinizi ekleyerek başlayın.",
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            ElevatedButton.icon(
              onPressed: _showAddCustomerModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                elevation: AppConstants.elevationSmall,
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                "+ Yeni müşteri",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Export Seçenekleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF1A73E8)),
              title: const Text("CSV Export"),
              subtitle: const Text("Excel ile açılabilir tablo"),
              onTap: () {
                Navigator.pop(context);
                _exportCsv();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("PDF Export"),
              subtitle: const Text("Yazdırılabilir doküman"),
              onTap: () {
                Navigator.pop(context);
                _exportPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.green),
              title: const Text("JSON Backup"),
              subtitle: const Text("Tam veri yedeği"),
              onTap: () {
                Navigator.pop(context);
                _exportJson();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Add Customer Modal
class AddCustomerModal extends StatefulWidget {
  final VoidCallback onSaved;

  const AddCustomerModal({Key? key, required this.onSaved}) : super(key: key);

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final customer = CustomerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _customerService.addCustomer(customer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Yeni Müşteri"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CustomTextField(
              hint: "Ad",
              controller: _firstNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "Soyad",
              controller: _lastNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Soyad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "Telefon",
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "E-posta (isteğe bağlı)",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("Kaydet"),
        ),
      ],
    );
  }
}

// Modern Edit Customer Modal
class EditCustomerModal extends StatefulWidget {
  final CustomerModel customer;
  final VoidCallback onSaved;

  const EditCustomerModal({
    Key? key,
    required this.customer,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<EditCustomerModal> createState() => _EditCustomerModalState();
}

class _EditCustomerModalState extends State<EditCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.customer.firstName);
    _lastNameController = TextEditingController(text: widget.customer.lastName);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _emailController = TextEditingController(text: widget.customer.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCustomer = widget.customer.copyWith(
        name:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      await _customerService.updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Müşteri Düzenle"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CustomTextField(
              hint: "Ad",
              controller: _firstNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "Soyad",
              controller: _lastNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Soyad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "Telefon",
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CustomTextField(
              hint: "E-posta (isteğe bağlı)",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("Güncelle"),
        ),
      ],
    );
  }
}

// Modern Custom TextField
class _CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.hint,
    this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
