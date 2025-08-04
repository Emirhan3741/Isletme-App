import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/lawyer_client_model.dart';
import '../../core/models/case_model.dart';
import 'lawyer_documents_page.dart';
import 'add_edit_client_page.dart';

class ClientDetailPage extends StatefulWidget {
  final LawyerClientModel client;

  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<CaseModel> _cases = [];
  bool _isLoadingCases = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClientCases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientCases() async {
    setState(() => _isLoadingCases = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.lawyerCasesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('clientId', isEqualTo: widget.client.id)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _cases =
            snapshot.docs.map((doc) => CaseModel.fromFirestore(doc)).toList();
        _isLoadingCases = false;
      });
    } catch (e) {
      setState(() => _isLoadingCases = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Davalar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editClient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditClientPage(
          client: widget.client,
        ),
      ),
    );

    if (result == true) {
      // Sayfa güncellenebilir, ancak client modeli güncellenemez
      // Ana sayfa güncellendiğinde bu değişiklik yansıyacak
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müvekkil başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editClient,
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Telefon arama işlevi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.client.phone} aranıyor...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Ara',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.person),
                  text: 'Bilgiler',
                ),
                Tab(
                  icon: Icon(Icons.gavel),
                  text: 'Davalar',
                ),
                Tab(
                  icon: Icon(Icons.folder),
                  text: 'Belgeler',
                ),
              ],
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: AppConstants.textSecondary,
              indicatorColor: AppConstants.primaryColor,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bilgiler Sekmesi
          _buildInfoTab(),

          // Davalar Sekmesi
          _buildCasesTab(),

          // Belgeler Sekmesi
          LawyerDocumentsPage(
            clientId: widget.client.id,
            clientName: widget.client.name,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        AppConstants.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      widget.client.name.isNotEmpty
                          ? widget.client.name[0].toUpperCase()
                          : 'M',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Müvekkil',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.client.isActive
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.client.isActive ? 'Aktif' : 'Pasif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // İletişim Bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İletişim Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildInfoRow(Icons.phone, 'Telefon', widget.client.phone),
                  if (widget.client.email?.isNotEmpty == true)
                    _buildInfoRow(Icons.email, 'E-posta', widget.client.email!),
                  if (widget.client.address?.isNotEmpty == true)
                    _buildInfoRow(
                        Icons.location_on, 'Adres', widget.client.address!),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Kişisel Bilgiler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  if (widget.client.tcNo?.isNotEmpty == true)
                    _buildInfoRow(
                        Icons.badge, 'TC Kimlik No', widget.client.tcNo!),
                  if (widget.client.birthDate != null)
                    _buildInfoRow(
                      Icons.cake,
                      'Doğum Tarihi',
                      '${widget.client.birthDate!.day}/${widget.client.birthDate!.month}/${widget.client.birthDate!.year}',
                    ),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Kayıt Tarihi',
                    '${widget.client.createdAt.day}/${widget.client.createdAt.month}/${widget.client.createdAt.year}',
                  ),
                ],
              ),
            ),
          ),

          if (widget.client.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      widget.client.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCasesTab() {
    return Column(
      children: [
        // Üst bilgi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.client.name} - Davalar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Müvekkile ait davalar',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Toplam: ${_cases.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Dava listesi
        Expanded(
          child: _isLoadingCases
              ? const Center(child: CircularProgressIndicator())
              : _cases.isEmpty
                  ? _buildEmptyStateForCases()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      itemCount: _cases.length,
                      itemBuilder: (context, index) {
                        final caseItem = _cases[index];
                        return _buildCaseCard(caseItem);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateForCases() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gavel,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Bu müvekkile ait dava bulunamadı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Yeni dava eklemek için davalar sayfasını kullanabilirsiniz',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(CaseModel caseItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCaseStatusColor(caseItem.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: _getCaseStatusColor(caseItem.status),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseItem.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getCaseStatusColor(caseItem.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getCaseStatusColor(caseItem.status),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              caseItem.status,
                              style: TextStyle(
                                color: _getCaseStatusColor(caseItem.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            caseItem.caseType,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (caseItem.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                caseItem.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${caseItem.createdAt.day}/${caseItem.createdAt.month}/${caseItem.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const Spacer(),
                if (caseItem.courtName.isNotEmpty)
                  Text(
                    caseItem.courtName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
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

  Color _getCaseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return Colors.green;
      case 'beklemede':
        return Colors.orange;
      case 'kapalı':
        return Colors.grey;
      case 'reddedildi':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
