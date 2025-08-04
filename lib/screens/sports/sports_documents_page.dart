import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Spor paneli belge yönetim sayfası
class SportsDocumentsPage extends StatefulWidget {
  final String customerId; // Üye ID'si zorunlu
  final String? programId;

  const SportsDocumentsPage({
    super.key,
    required this.customerId,
    this.programId,
  });

  @override
  State<SportsDocumentsPage> createState() => _SportsDocumentsPageState();
}

class _SportsDocumentsPageState extends State<SportsDocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spor Belgeleri'),
        backgroundColor: AppConstants.panelColors['sports'],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.fitness_center),
              text: 'Belge Yükle',
            ),
            Tab(
              icon: Icon(Icons.sports),
              text: 'Spor Belgeleri',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Belge yükleme sekmesi
          SingleChildScrollView(
            child: Column(
              children: [
                _buildSportsInfoCard(),
                DocumentUploadWidget(
                  panel: 'sports',
                  customerId: widget.customerId,
                  onDocumentUploaded: (document) {
                    _tabController.animateTo(1);
                    Provider.of<DocumentProvider>(context, listen: false)
                        .loadDocuments(panel: 'sports', customerId: widget.customerId);
                  },
                  allowedTypes: [
                    'kimlik',
                    'sağlık_raporu',
                    'spor_lisansı',
                    'antrenman_programı',
                    'beslenme_planı',
                  ],
                ),
                _buildSportsTypesCard(),
              ],
            ),
          ),
          
          // Belge listesi sekmesi
          Column(
            children: [
              _buildSportsFilters(),
              Expanded(
                child: DocumentListWidget(
                  panel: 'sports',
                  customerId: widget.customerId,
                  showFilters: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportsInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: AppConstants.panelColors['sports']),
                SizedBox(width: 8),
                Text(
                  'Spor Belge Yönetimi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.panelColors['sports'],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Spor lisanslarını güncel tutun\n'
              '• Sağlık raporlarını düzenli yükleyin\n'
              '• Antrenman programlarını paylaşın\n'
              '• Beslenme planlarını ekleyin\n'
              '• Performans takip belgelerini saklayın',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsTypesCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spor Belge Türleri',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 12),
            _buildDocTypeItem('🏃', 'Spor Lisansı', 'Federasyon ve kulüp lisansları'),
            _buildDocTypeItem('🏥', 'Sağlık Raporu', 'Spor hekimi raporları'),
            _buildDocTypeItem('💪', 'Antrenman Programı', 'Kişisel antrenman planları'),
            _buildDocTypeItem('🥗', 'Beslenme Planı', 'Diyet ve beslenme programları'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTypeItem(String emoji, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportsFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'sports', documentType: 'sağlık_raporu');
              },
              icon: Icon(Icons.medical_services),
              label: Text('Sağlık'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'sports', documentType: 'spor_lisansı');
              },
              icon: Icon(Icons.card_membership),
              label: Text('Lisans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'sports', documentType: 'antrenman_programı');
              },
              icon: Icon(Icons.fitness_center),
              label: Text('Program'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'sports');
              },
              icon: Icon(Icons.refresh),
              label: Text('Tümü'),
            ),
          ),
        ],
      ),
    );
  }
}