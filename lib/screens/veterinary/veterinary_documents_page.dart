import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Veteriner paneli belge yönetim sayfası
class VeterinaryDocumentsPage extends StatefulWidget {
  final String customerId; // Hasta sahibi ID'si zorunlu
  final String? patientName;

  const VeterinaryDocumentsPage({
    super.key,
    required this.customerId,
    this.patientName,
  });

  @override
  State<VeterinaryDocumentsPage> createState() => _VeterinaryDocumentsPageState();
}

class _VeterinaryDocumentsPageState extends State<VeterinaryDocumentsPage>
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
        title: Text(widget.patientName != null 
            ? '${widget.patientName} - Belgeler' 
            : 'Veteriner Belgeleri'),
        backgroundColor: AppConstants.panelColors['veterinary'],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.pets),
              text: 'Belge Yükle',
            ),
            Tab(
              icon: Icon(Icons.folder),
              text: 'Hasta Belgeleri',
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
                // Veteriner özel bilgilendirme
                _buildVetInfoCard(),
                
                // Yükleme widget'ı
                DocumentUploadWidget(
                  panel: 'veterinary',
                  customerId: widget.customerId,
                  onDocumentUploaded: (document) {
                    _tabController.animateTo(1);
                    Provider.of<DocumentProvider>(context, listen: false)
                        .loadDocuments(panel: 'veterinary', customerId: widget.customerId);
                  },
                  allowedTypes: [
                    'kimlik',
                    'hayvan_kimlik',
                    'aşı_kartı',
                    'reçete',
                    'kan_tahlili',
                    'röntgen',
                    'muayene_raporu',
                  ],
                ),
                
                // Belge türleri açıklama
                _buildDocumentTypesCard(),
              ],
            ),
          ),
          
          // Belge listesi sekmesi
          Column(
            children: [
              // Veteriner özel filtreler
              _buildVetFilters(),
              
              Expanded(
                child: DocumentListWidget(
                  panel: 'veterinary',
                  customerId: widget.customerId,
                  showFilters: false, // Özel filtreler kullanıyoruz
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVetInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, color: AppConstants.panelColors['veterinary']),
                SizedBox(width: 8),
                Text(
                  'Veteriner Belge Yönetimi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.panelColors['veterinary'],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Hasta belgelerini düzenli yükleyin\n'
              '• Aşı kayıtlarını güncel tutun\n'
              '• Muayene raporlarını detaylı açıklayın\n'
              '• Röntgen ve tahlil sonuçlarını ekleyin\n'
              '• Reçete bilgilerini tam yazın',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypesCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belge Türleri Açıklama',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 12),
            _buildDocTypeItem('🆔', 'Hayvan Kimlik', 'Pet pasaportu, mikroçip bilgileri'),
            _buildDocTypeItem('💉', 'Aşı Kartı', 'Aşı takvimi ve kayıtları'),
            _buildDocTypeItem('🩺', 'Muayene Raporu', 'Genel muayene bulguları'),
            _buildDocTypeItem('🩸', 'Kan Tahlili', 'Laboratuvar test sonuçları'),
            _buildDocTypeItem('📷', 'Röntgen', 'Radyoloji görüntüleri'),
            _buildDocTypeItem('💊', 'Reçete', 'İlaç ve tedavi önerileri'),
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

  Widget _buildVetFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'veterinary', documentType: 'aşı_kartı');
              },
              icon: Icon(Icons.medical_services),
              label: Text('Aşılar'),
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
                    .loadDocuments(panel: 'veterinary', documentType: 'kan_tahlili');
              },
              icon: Icon(Icons.bloodtype),
              label: Text('Tahliller'),
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
                    .loadDocuments(panel: 'veterinary', documentType: 'röntgen');
              },
              icon: Icon(Icons.visibility),
              label: Text('Röntgen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'veterinary');
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