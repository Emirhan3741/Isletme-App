import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Avukat paneli belge yönetim sayfası
class LawyerDocumentsPage extends StatefulWidget {
  final String clientId; // Müşteri ID'si zorunlu
  final String? clientName;

  const LawyerDocumentsPage({
    super.key,
    required this.clientId,
    this.clientName,
  });

  @override
  State<LawyerDocumentsPage> createState() => _LawyerDocumentsPageState();
}

class _LawyerDocumentsPageState extends State<LawyerDocumentsPage>
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
        title: Text(widget.clientName != null 
            ? '${widget.clientName} - Belgeler' 
            : 'Avukat Belgeleri'),
        backgroundColor: AppConstants.panelColors['lawyer'],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.cloud_upload),
              text: 'Belge Yükle',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Belgelerim',
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
                // İstatistikler
                _buildStatsCard(),
                
                // Yükleme widget'ı
                DocumentUploadWidget(
                  panel: 'lawyer',
                  customerId: widget.clientId,
                  onDocumentUploaded: (document) {
                    // Belge yüklendikten sonra liste sekmesine geç
                    _tabController.animateTo(1);
                    
                    // Provider'ı güncelle
                    Provider.of<DocumentProvider>(context, listen: false)
                        .loadDocuments(panel: 'lawyer', customerId: widget.clientId);
                  },
                  allowedTypes: [
                    'kimlik',
                    'ikametgah',
                    'dava_evrakı',
                    'sözleşme',
                    'mahkeme_kararı',
                    'vekaletname',
                  ],
                ),
                
                // Bilgilendirme kartı
                _buildInfoCard(),
              ],
            ),
          ),
          
          // Belge listesi sekmesi
          DocumentListWidget(
            panel: 'lawyer',
            customerId: widget.clientId,
            showFilters: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        return FutureBuilder<Map<String, int>>(
          future: documentProvider.getDocumentStats('lawyer'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }

            final stats = snapshot.data!;
            return Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belge İstatistikleri',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Toplam', 
                            stats['toplam'] ?? 0, 
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Bekleyen', 
                            stats['onay_bekleyen'] ?? 0, 
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Onaylanan', 
                            stats['onaylanan'] ?? 0, 
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Reddedilen', 
                            stats['reddedilen'] ?? 0, 
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Belge Yükleme Kuralları',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Maksimum dosya boyutu: 10MB\n'
              '• Desteklenen formatlar: PDF, JPG, PNG, DOC, DOCX\n'
              '• Belge türünü doğru seçin\n'
              '• Açıklama kısmına belge hakkında detay ekleyin\n'
              '• Yüklenen belgeler onay bekleyecektir',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}