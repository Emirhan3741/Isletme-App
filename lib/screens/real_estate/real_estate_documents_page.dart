import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Emlak paneli belge yönetim sayfası
class RealEstateDocumentsPage extends StatefulWidget {
  final String customerId; // Müşteri ID'si zorunlu
  final String? propertyId;

  const RealEstateDocumentsPage({
    super.key,
    required this.customerId,
    this.propertyId,
  });

  @override
  State<RealEstateDocumentsPage> createState() => _RealEstateDocumentsPageState();
}

class _RealEstateDocumentsPageState extends State<RealEstateDocumentsPage>
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
        title: Text('Emlak Belgeleri'),
        backgroundColor: AppConstants.panelColors['real_estate'],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.home_work),
              text: 'Belge Yükle',
            ),
            Tab(
              icon: Icon(Icons.folder_shared),
              text: 'Emlak Belgeleri',
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
                _buildRealEstateInfoCard(),
                DocumentUploadWidget(
                  panel: 'real_estate',
                  customerId: widget.customerId,
                  onDocumentUploaded: (document) {
                    _tabController.animateTo(1);
                    Provider.of<DocumentProvider>(context, listen: false)
                        .loadDocuments(panel: 'real_estate', customerId: widget.customerId);
                  },
                  allowedTypes: [
                    'kimlik',
                    'tapu',
                    'yapı_ruhsatı',
                    'iskan_ruhsatı',
                    'emlak_ekspertiz',
                    'mülk_fotoğrafları',
                  ],
                ),
                _buildRealEstateTypesCard(),
              ],
            ),
          ),
          
          // Belge listesi sekmesi
          Column(
        children: [
              _buildRealEstateFilters(),
              Expanded(
                child: DocumentListWidget(
                  panel: 'real_estate',
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

  Widget _buildRealEstateInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.brown[50],
      child: Padding(
        padding: EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                Icon(Icons.home_work, color: AppConstants.panelColors['real_estate']),
                SizedBox(width: 8),
                Text(
                  'Emlak Belge Yönetimi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.panelColors['real_estate'],
                ),
              ),
            ],
          ),
            SizedBox(height: 12),
            Text(
              '• Tapu belgelerini güvenli saklayın\n'
              '• Yapı ve iskan ruhsatlarını yükleyin\n'
              '• Emlak ekspertiz raporlarını ekleyin\n'
              '• Mülk fotoğraflarını düzenli güncelleyin\n'
              '• Yasal belgelerin güncel olduğundan emin olun',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildRealEstateTypesCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Emlak Belge Türleri',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 12),
            _buildDocTypeItem('🏠', 'Tapu', 'Mülkiyet belgesi'),
            _buildDocTypeItem('🏗️', 'Yapı Ruhsatı', 'İnşaat izin belgesi'),
            _buildDocTypeItem('✅', 'İskan Ruhsatı', 'Oturma izin belgesi'),
            _buildDocTypeItem('📊', 'Emlak Ekspertiz', 'Değerleme raporu'),
            _buildDocTypeItem('📸', 'Mülk Fotoğrafları', 'İç ve dış mekan görüntüleri'),
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

  Widget _buildRealEstateFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'real_estate', documentType: 'tapu');
              },
              icon: Icon(Icons.description),
              label: Text('Tapu'),
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
                    .loadDocuments(panel: 'real_estate', documentType: 'mülk_fotoğrafları');
              },
              icon: Icon(Icons.photo_library),
              label: Text('Fotoğraf'),
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
                    .loadDocuments(panel: 'real_estate', documentType: 'emlak_ekspertiz');
              },
              icon: Icon(Icons.assessment),
              label: Text('Ekspertiz'),
                              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[100],
                foregroundColor: Colors.orange[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'real_estate');
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