import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Güzellik paneli belge yönetim sayfası
class BeautyDocumentsScreen extends StatefulWidget {
  final String? treatmentId; // Tedavi ID'si varsa

  const BeautyDocumentsScreen({
    Key? key,
    this.treatmentId,
  }) : super(key: key);

  @override
  State<BeautyDocumentsScreen> createState() => _BeautyDocumentsScreenState();
}

class _BeautyDocumentsScreenState extends State<BeautyDocumentsScreen> {
  String selectedTab = 'upload';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Güzellik Belgeleri'),
        backgroundColor: AppConstants.panelColors['beauty'],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedTab = 'upload'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab == 'upload' 
                                ? AppConstants.panelColors['beauty']! 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: selectedTab == 'upload' 
                                ? AppConstants.panelColors['beauty'] 
                                : Colors.grey,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fotoğraf Yükle',
                            style: TextStyle(
                              color: selectedTab == 'upload' 
                                  ? AppConstants.panelColors['beauty'] 
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedTab = 'list'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selectedTab == 'list' 
                                ? AppConstants.panelColors['beauty']! 
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: selectedTab == 'list' 
                                ? AppConstants.panelColors['beauty'] 
                                : Colors.grey,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Galeri',
                            style: TextStyle(
                              color: selectedTab == 'list' 
                                  ? AppConstants.panelColors['beauty'] 
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: selectedTab == 'upload'
          ? _buildUploadSection()
          : _buildGallerySection(),
    );
  }

  Widget _buildUploadSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Özel güzellik bilgilendirme kartı
          _buildBeautyInfoCard(),
          
          // Yükleme widget'ı
          DocumentUploadWidget(
            panel: 'beauty',
            panelContextId: widget.treatmentId,
            onDocumentUploaded: (document) {
              // Fotoğraf yüklendikten sonra galeri sekmesine geç
              setState(() => selectedTab = 'list');
              
              // Provider'ı güncelle
              Provider.of<DocumentProvider>(context, listen: false)
                  .refreshDocumentsForPanel('beauty');
            },
            allowedTypes: [
              'kimlik',
              'sağlık_raporu',
              'öncesi_fotoğraf',
              'sonrası_fotoğraf',
              'onay_formu',
            ],
          ),
          
          // Öncesi-Sonrası karşılaştırma önerileri
          _buildComparisonTips(),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        // Güzellik spesifik filtreler
        _buildBeautyFilters(),
        
        // Belge listesi
        Expanded(
          child: DocumentListWidget(
            panel: 'beauty',
            showFilters: false, // Özel filtreler kullanıyoruz
          ),
        ),
      ],
    );
  }

  Widget _buildBeautyInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.pink[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.face, color: AppConstants.panelColors['beauty']),
                SizedBox(width: 8),
                Text(
                  'Güzellik Tedavisi Fotoğrafları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.panelColors['beauty'],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Tedavi öncesi ve sonrası fotoğraflarınızı yükleyin\n'
              '• Fotoğraflar aynı açıdan ve ışıkta çekilmelidir\n'
              '• Yüz tedavileri için frontal ve yan görünüm fotoğrafları\n'
              '• Vücut tedavileri için ilgili bölgenin net görünümü\n'
              '• Fotoğraf kalitesi HD olmalıdır',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTips() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fotoğraf Çekim Önerileri',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(height: 8),
                      Text(
                        'Doğal Işık',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Gündüz doğal ışık tercih edin',
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.center_focus_strong, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'Aynı Açı',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Öncesi-sonrası aynı pozisyon',
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.high_quality, color: Colors.green),
                      SizedBox(height: 8),
                      Text(
                        'HD Kalite',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Yüksek çözünürlük kullanın',
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautyFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Provider.of<DocumentProvider>(context, listen: false)
                    .loadDocuments(panel: 'beauty', documentType: 'öncesi_fotoğraf');
              },
              icon: Icon(Icons.camera_front),
              label: Text('Öncesi'),
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
                    .loadDocuments(panel: 'beauty', documentType: 'sonrası_fotoğraf');
              },
              icon: Icon(Icons.camera_rear),
              label: Text('Sonrası'),
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
                    .loadDocuments(panel: 'beauty');
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