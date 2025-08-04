import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/feedback_utils.dart';
import '../../utils/validation_utils.dart';

class VeterinarySettingsPage extends StatefulWidget {
  const VeterinarySettingsPage({super.key});

  @override
  State<VeterinarySettingsPage> createState() => _VeterinarySettingsPageState();
}

class _VeterinarySettingsPageState extends State<VeterinarySettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Klinik Ayarları',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Klinik işleyişiniz için sabit değerleri yönetin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Aşı Türleri'),
          Tab(text: 'İşlem Türleri'),
          Tab(text: 'Stok Kategorileri'),
          Tab(text: 'Genel Ayarlar'),
        ],
        labelColor: const Color(0xFF059669),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF059669),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _VaccineTypesTab(),
        _TreatmentTypesTab(),
        _StockCategoriesTab(),
        _GeneralSettingsTab(),
      ],
    );
  }
}

class _VaccineTypesTab extends StatefulWidget {
  @override
  State<_VaccineTypesTab> createState() => _VaccineTypesTabState();
}

class _VaccineTypesTabState extends State<_VaccineTypesTab> {
  void _showAddVaccineDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddVaccineTypeDialog(
        onAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Klinik aşı türlerinizi yönetin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddVaccineDialog,
                icon: const Icon(Icons.add),
                label: const Text('Aşı Türü Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getVaccineTypesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  'Henüz aşı türü yok',
                  'İlk aşı türünüzü ekleyerek başlayın',
                  Icons.vaccines,
                  _showAddVaccineDialog,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildVaccineCard(data, doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVaccineCard(Map<String, dynamic> data, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vaccines, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Aşı',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (data['description'] != null)
                  Text(
                    data['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                if (data['intervalDays'] != null)
                  Text(
                    'Tekrar aralığı: ${data['intervalDays']} gün',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    const SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleVaccineAction(value, id, data),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getVaccineTypesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('veterinary_vaccine_types')
        .where('userId', isEqualTo: user.uid)
        .orderBy('name')
        .snapshots();
  }

  void _handleVaccineAction(
      String action, String id, Map<String, dynamic> data) {
    switch (action) {
      case 'edit':
        _showEditVaccineDialog(id, data);
        break;
      case 'delete':
        _deleteVaccineType(id);
        break;
    }
  }

  void _showEditVaccineDialog(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _AddVaccineTypeDialog(
        onAdded: () => setState(() {}),
        editId: id,
        editData: data,
      ),
    );
  }

  Future<void> _deleteVaccineType(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('veterinary_vaccine_types')
          .doc(id)
          .delete();
      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Aşı türü silindi');
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Silme hatası: $e');
      }
    }
  }

  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF059669)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: const Text('İlk Öğeyi Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatmentTypesTab extends StatefulWidget {
  @override
  State<_TreatmentTypesTab> createState() => _TreatmentTypesTabState();
}

class _TreatmentTypesTabState extends State<_TreatmentTypesTab> {
  void _showAddTreatmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTreatmentTypeDialog(
        onAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Klinik işlem türlerinizi yönetin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTreatmentDialog,
                icon: const Icon(Icons.add),
                label: const Text('İşlem Türü Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTreatmentTypesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(
                  'Henüz işlem türü yok',
                  'İlk işlem türünüzü ekleyerek başlayın',
                  Icons.medical_services,
                  _showAddTreatmentDialog,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildTreatmentCard(data, doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> data, String id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medical_services,
                color: Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'İşlem',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (data['description'] != null)
                  Text(
                    data['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                if (data['defaultPrice'] != null)
                  Text(
                    'Varsayılan ücret: ₺${data['defaultPrice']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    const SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleTreatmentAction(value, id, data),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getTreatmentTypesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('veterinary_treatment_types')
        .where('userId', isEqualTo: user.uid)
        .orderBy('name')
        .snapshots();
  }

  void _handleTreatmentAction(
      String action, String id, Map<String, dynamic> data) {
    switch (action) {
      case 'edit':
        _showEditTreatmentDialog(id, data);
        break;
      case 'delete':
        _deleteTreatmentType(id);
        break;
    }
  }

  void _showEditTreatmentDialog(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => _AddTreatmentTypeDialog(
        onAdded: () => setState(() {}),
        editId: id,
        editData: data,
      ),
    );
  }

  Future<void> _deleteTreatmentType(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('veterinary_treatment_types')
          .doc(id)
          .delete();
      if (mounted) {
        FeedbackUtils.showSuccess(context, 'İşlem türü silindi');
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Silme hatası: $e');
      }
    }
  }

  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF059669)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: const Text('İlk Öğeyi Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockCategoriesTab extends StatefulWidget {
  @override
  State<_StockCategoriesTab> createState() => _StockCategoriesTabState();
}

class _StockCategoriesTabState extends State<_StockCategoriesTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 80, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            Text(
              'Stok Kategorileri',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok kategorilerini yönetme özelliği yakında gelecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsTab extends StatefulWidget {
  @override
  State<_GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<_GeneralSettingsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSettingCard(
            'Klinik Bilgileri',
            'Klinik adı, adres ve iletişim bilgileri',
            Icons.business,
            () => _showClinicInfoDialog(),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Çalışma Saatleri',
            'Haftalık çalışma programı ve tatil günleri',
            Icons.schedule,
            () => _showWorkingHoursDialog(),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Bildirim Ayarları',
            'Hatırlatıcılar ve uyarı mesajları',
            Icons.notifications,
            () => _showNotificationSettings(),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            'Veri Yedekleme',
            'Verilerinizi yedekleyin ve geri yükleyin',
            Icons.backup,
            () => _showBackupOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
      String title, String description, IconData icon, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF059669), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showClinicInfoDialog() {
    FeedbackUtils.showInfo(
        context, 'Klinik bilgileri ayarları yakında gelecek');
  }

  void _showWorkingHoursDialog() {
    FeedbackUtils.showInfo(
        context, 'Çalışma saatleri ayarları yakında gelecek');
  }

  void _showNotificationSettings() {
    FeedbackUtils.showInfo(context, 'Bildirim ayarları yakında gelecek');
  }

  void _showBackupOptions() {
    FeedbackUtils.showInfo(
        context, 'Veri yedekleme özellikleri yakında gelecek');
  }
}

// Dialog Classes
class _AddVaccineTypeDialog extends StatefulWidget {
  final VoidCallback onAdded;
  final String? editId;
  final Map<String, dynamic>? editData;

  const _AddVaccineTypeDialog({
    required this.onAdded,
    this.editId,
    this.editData,
  });

  @override
  State<_AddVaccineTypeDialog> createState() => _AddVaccineTypeDialogState();
}

class _AddVaccineTypeDialogState extends State<_AddVaccineTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intervalController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      _nameController.text = widget.editData!['name'] ?? '';
      _descriptionController.text = widget.editData!['description'] ?? '';
      _intervalController.text =
          widget.editData!['intervalDays']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final data = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'intervalDays': _intervalController.text.isNotEmpty
            ? int.tryParse(_intervalController.text)
            : null,
        'updatedAt': Timestamp.now(),
      };

      if (widget.editId != null) {
        await FirebaseFirestore.instance
            .collection('veterinary_vaccine_types')
            .doc(widget.editId)
            .update(data);
      } else {
        data['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('veterinary_vaccine_types')
            .add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(
            context,
            widget.editId != null
                ? 'Aşı türü güncellendi'
                : 'Aşı türü eklendi');
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.editId != null
                          ? 'Aşı Türü Düzenle'
                          : 'Yeni Aşı Türü',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Aşı Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tekrar Aralığı (Gün)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.editId != null ? 'Güncelle' : 'Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTreatmentTypeDialog extends StatefulWidget {
  final VoidCallback onAdded;
  final String? editId;
  final Map<String, dynamic>? editData;

  const _AddTreatmentTypeDialog({
    required this.onAdded,
    this.editId,
    this.editData,
  });

  @override
  State<_AddTreatmentTypeDialog> createState() =>
      _AddTreatmentTypeDialogState();
}

class _AddTreatmentTypeDialogState extends State<_AddTreatmentTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      _nameController.text = widget.editData!['name'] ?? '';
      _descriptionController.text = widget.editData!['description'] ?? '';
      _priceController.text =
          widget.editData!['defaultPrice']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final data = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'defaultPrice': _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        'updatedAt': Timestamp.now(),
      };

      if (widget.editId != null) {
        await FirebaseFirestore.instance
            .collection('veterinary_treatment_types')
            .doc(widget.editId)
            .update(data);
      } else {
        data['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('veterinary_treatment_types')
            .add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        FeedbackUtils.showSuccess(
            context,
            widget.editId != null
                ? 'İşlem türü güncellendi'
                : 'İşlem türü eklendi');
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.editId != null
                          ? 'İşlem Türü Düzenle'
                          : 'Yeni İşlem Türü',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'İşlem Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: ValidationUtils.validateRequired,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Varsayılan Ücret (₺)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.editId != null ? 'Güncelle' : 'Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
