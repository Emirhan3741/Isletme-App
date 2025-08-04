import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/document_provider.dart';
import '../models/document_model.dart';

/// Kullanıcının yüklediği belgeleri listeleyen widget
class DocumentListWidget extends StatefulWidget {
  final String? panel;
  final String? customerId;
  final String? documentType;
  final String? status;
  final bool showFilters;

  const DocumentListWidget({
    Key? key,
    this.panel,
    this.customerId,
    this.documentType,
    this.status,
    this.showFilters = true,
  }) : super(key: key);

  @override
  State<DocumentListWidget> createState() => _DocumentListWidgetState();
}

class _DocumentListWidgetState extends State<DocumentListWidget> {
  String? selectedStatus;
  String? selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  void _loadDocuments() {
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    documentProvider.loadDocuments(
      panel: widget.panel,
      customerId: widget.customerId,
      documentType: selectedType ?? widget.documentType,
      status: selectedStatus ?? widget.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        return Column(
          children: [
            // Filtreler
            if (widget.showFilters) _buildFilters(documentProvider),

            // Belge listesi
            Expanded(
              child: _buildDocumentList(documentProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(DocumentProvider documentProvider) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      DropdownMenuItem(value: 'waiting', child: Text('Bekliyor')),
                      DropdownMenuItem(value: 'approved', child: Text('Onaylandı')),
                      DropdownMenuItem(value: 'rejected', child: Text('Reddedildi')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                      _loadDocuments();
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Belge Türü',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...documentProvider.getDocumentTypesForPanel(widget.panel ?? '')
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_formatDocumentType(type)),
                              )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                      });
                      _loadDocuments();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadDocuments,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Yenile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedStatus = null;
                      selectedType = null;
                    });
                    _loadDocuments();
                  },
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Temizle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(DocumentProvider documentProvider) {
    if (documentProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Belgeler yükleniyor...'),
          ],
        ),
      );
    }

    if (documentProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              documentProvider.error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (documentProvider.documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz belge yüklenmemiş',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDocuments(),
      child: ListView.builder(
        itemCount: documentProvider.documents.length,
        itemBuilder: (context, index) {
          final document = documentProvider.documents[index];
          return _buildDocumentCard(document, documentProvider);
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document, DocumentProvider documentProvider) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: _getStatusIcon(document.status),
        title: Text(
          _formatDocumentType(document.documentType),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(document.uploadedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (document.description.isNotEmpty)
              Text(
                document.description,
                style: TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(document, documentProvider);
            }
          },
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Panel', _formatPanel(document.panel)),
                _buildDetailRow('Durum', _getStatusText(document.status)),
                _buildDetailRow('Yükleme Tarihi', 
                    DateFormat('dd.MM.yyyy HH:mm').format(document.uploadedAt)),
                if (document.description.isNotEmpty)
                  _buildDetailRow('Açıklama', document.description),
                if (document.approvedBy != null)
                  _buildDetailRow('Onaylayan', document.approvedBy!),
                _buildDetailRow('Müşteri ID', document.customerId),
                if (document.adminComment != null && document.adminComment!.isNotEmpty)
                  _buildDetailRow('Admin Yorumu', document.adminComment!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'Onay Bekliyor';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      case 'under_review':
        return 'İnceleniyor';
      default:
        return status;
    }
  }

  String _formatPanel(String panel) {
    switch (panel) {
      case 'lawyer':
        return 'Avukat';
      case 'beauty':
        return 'Güzellik';
      case 'veterinary':
        return 'Veteriner';
      case 'education':
        return 'Eğitim';
      case 'sports':
        return 'Spor';
      case 'consulting':
        return 'Danışmanlık';
      case 'real_estate':
        return 'Emlak';
      default:
        return panel;
    }
  }

  String _formatDocumentType(String type) {
    return type.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showDeleteConfirmation(DocumentModel document, DocumentProvider documentProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Belgeyi Sil'),
        content: Text('Bu belgeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await documentProvider.deleteDocument(document.id!);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Belge başarıyla silindi'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }
}