import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/document_model.dart';
import '../../services/document_service.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/document_integration_helper.dart';

/// Admin paneli - belge onaylama sayfası
class AdminDocumentsApprovalPage extends StatefulWidget {
  const AdminDocumentsApprovalPage({super.key});

  @override
  State<AdminDocumentsApprovalPage> createState() => _AdminDocumentsApprovalPageState();
}

class _AdminDocumentsApprovalPageState extends State<AdminDocumentsApprovalPage> {
  String selectedStatus = 'waiting';
  String? selectedPanel;
  final DocumentService _documentService = DocumentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Belge Onay Merkezi'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStatsCards(),
          Expanded(
            child: _buildDocumentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Filtreler',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'waiting', child: Text('Onay Bekleyen')),
                      DropdownMenuItem(value: 'approved', child: Text('Onaylanan')),
                      DropdownMenuItem(value: 'rejected', child: Text('Reddedilen')),
                      DropdownMenuItem(value: 'all', child: Text('Tümü')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPanel,
                    decoration: InputDecoration(
                      labelText: 'Panel',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('Tüm Paneller')),
                      DropdownMenuItem(value: 'lawyer', child: Text('Avukat')),
                      DropdownMenuItem(value: 'beauty', child: Text('Güzellik')),
                      DropdownMenuItem(value: 'veterinary', child: Text('Veteriner')),
                      DropdownMenuItem(value: 'education', child: Text('Eğitim')),
                      DropdownMenuItem(value: 'sports', child: Text('Spor')),
                      DropdownMenuItem(value: 'real_estate', child: Text('Emlak')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPanel = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('documents').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final docs = snapshot.data!.docs
            .map((doc) => DocumentModel.fromFirestore(doc))
            .toList();

        final waiting = docs.where((d) => d.status == 'waiting').length;
        final approved = docs.where((d) => d.status == 'approved').length;
        final rejected = docs.where((d) => d.status == 'rejected').length;

        return Container(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Bekleyen',
                  waiting.toString(),
                  Colors.orange,
                  Icons.pending,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Onaylanan',
                  approved.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Reddedilen',
                  rejected.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Toplam',
                  docs.length.toString(),
                  Colors.blue,
                  Icons.description,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Belgeler yüklenirken hata oluştu'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belge bulunamadı'),
                Text(
                  'Seçili kriterlere uygun belge yok',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = DocumentModel.fromFirestore(snapshot.data!.docs[index]);
            return _buildDocumentCard(doc);
          },
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('documents')
        .orderBy('uploadedAt', descending: true);

    if (selectedStatus != 'all') {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    if (selectedPanel != null) {
      query = query.where('panel', isEqualTo: selectedPanel);
    }

    return query;
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _getStatusIcon(document.status),
        title: Row(
          children: [
            Expanded(
              child: Text(
                DocumentIntegrationHelper.formatDocumentType(document.documentType),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPanelColor(document.panel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DocumentIntegrationHelper.formatPanelName(document.panel),
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yükleyen: ${document.userId}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'Tarih: ${document.uploadedAt.day}.${document.uploadedAt.month}.${document.uploadedAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (document.description.isNotEmpty) ...[
                  Text(
                    'Açıklama:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    document.description,
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(height: 12),
                ],
                
                if (document.panelContextId != null) ...[
                  Text(
                    'Bağlı İşlem: ${document.panelContextId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                ],

                if (document.approvedBy != null) ...[
                  Text(
                    'Onaylayan: ${document.approvedBy}',
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
                  SizedBox(height: 12),
                ],

                // Admin sadece yorum ekleyebilir, silemez!
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCommentDialog(document),
                        icon: Icon(Icons.comment),
                        label: Text('Yorum Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (document.status == 'waiting') ...[
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addComment(document.id!, 'approved'),
                          icon: Icon(Icons.check),
                          label: Text('Onayla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addComment(document.id!, 'rejected'),
                          icon: Icon(Icons.close),
                          label: Text('Reddet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (document.status != 'waiting')
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: document.status == 'approved' 
                          ? Colors.green[50] 
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      document.status == 'approved' 
                          ? '✅ Bu belge onaylanmış' 
                          : '❌ Bu belge reddedilmiş',
                      style: TextStyle(
                        color: document.status == 'approved' 
                            ? Colors.green[700] 
                            : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'waiting':
        return Icon(Icons.pending, color: Colors.orange);
      case 'approved':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.description, color: Colors.grey);
    }
  }

  Color _getPanelColor(String panel) {
    return AppConstants.panelColors[panel] ?? Colors.grey;
  }

  /// Admin yorum ekleme dialog'u
  Future<void> _showCommentDialog(DocumentModel document) async {
    final commentController = TextEditingController(
      text: document.adminComment ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Admin Yorumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Belge: ${DocumentIntegrationHelper.formatDocumentType(document.documentType)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Müşteri: ${document.customerId}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Yorum',
                border: OutlineInputBorder(),
                hintText: 'Belge hakkında yorumunuz...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isNotEmpty) {
                await _addComment(document.id!, null, commentController.text);
              }
              Navigator.of(context).pop();
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Admin yorum ekleme/güncelleme
  Future<void> _addComment(String documentId, String? status, [String? comment]) async {
    try {
      await _documentService.addAdminComment(
        documentId: documentId,
        comment: comment ?? (status == 'approved' ? 'Onaylandı' : 'Reddedildi'),
        status: status,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status != null 
              ? 'Belge ${status == 'approved' ? 'onaylandı' : 'reddedildi'}'
              : 'Yorum eklendi'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}