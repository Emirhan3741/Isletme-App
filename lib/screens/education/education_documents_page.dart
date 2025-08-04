import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/document_upload_widget.dart';
import '../../widgets/document_list_widget.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../core/constants/app_constants.dart';

/// Eğitim paneli belge yönetim sayfası
class EducationDocumentsPage extends StatefulWidget {
  final String customerId; // Öğrenci ID'si zorunlu
  final String? courseId;

  const EducationDocumentsPage({
    super.key,
    required this.customerId,
    this.courseId,
  });

  @override
  State<EducationDocumentsPage> createState() => _EducationDocumentsPageState();
}

class _EducationDocumentsPageState extends State<EducationDocumentsPage>
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
        title: Text('Eğitim Belgeleri'),
        backgroundColor: AppConstants.panelColors['education'],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.school),
              text: 'Belge Yükle',
            ),
            Tab(
              icon: Icon(Icons.library_books),
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
                _buildEducationInfoCard(),
                DocumentUploadWidget(
                  panel: 'education',
                  customerId: widget.customerId,
                  onDocumentUploaded: (document) {
                    _tabController.animateTo(1);
                    Provider.of<DocumentProvider>(context, listen: false)
                        .loadDocuments(panel: 'education', customerId: widget.customerId);
                  },
                  allowedTypes: [
                    'kimlik',
                    'diploma',
                    'sertifika',
                    'cv',
                    'referans_mektubu',
                    'transkript',
                  ],
                ),
                _buildEducationTypesCard(),
              ],
            ),
          ),
          
          // Belge listesi sekmesi
          DocumentListWidget(
            panel: 'education',
            customerId: widget.customerId,
            showFilters: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.purple[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: AppConstants.panelColors['education']),
                SizedBox(width: 8),
                Text(
                  'Eğitim Belge Sistemi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppConstants.panelColors['education'],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Öğrenci evraklarını düzenli saklayın\n'
              '• Diploma ve sertifikaları yükleyin\n'
              '• CV ve referans mektuplarını güncel tutun\n'
              '• Transkript belgelerini ekleyin\n'
              '• Belgelerin orijinal kopyalarını saklayın',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationTypesCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eğitim Belge Türleri',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 12),
            _buildDocTypeItem('🎓', 'Diploma', 'Mezuniyet belgeleri'),
            _buildDocTypeItem('📜', 'Sertifika', 'Kurs ve yeterlilik belgeleri'),
            _buildDocTypeItem('📄', 'CV', 'Özgeçmiş belgesi'),
            _buildDocTypeItem('✍️', 'Referans Mektubu', 'Referans ve tavsiye mektupları'),
            _buildDocTypeItem('📊', 'Transkript', 'Not dökümü ve ders kayıtları'),
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
}