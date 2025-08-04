import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../models/document_model.dart';

/// Belge yükleme widget'ı - tüm panellerde kullanılabilir
class DocumentUploadWidget extends StatefulWidget {
  final String panel;
  final String customerId; // Müşteri ID'si zorunlu
  final Function(DocumentModel)? onDocumentUploaded;
  final List<String>? allowedTypes;

  const DocumentUploadWidget({
    Key? key,
    required this.panel,
    required this.customerId,
    this.onDocumentUploaded,
    this.allowedTypes,
  }) : super(key: key);

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  String? selectedDocumentType;
  final TextEditingController descriptionController = TextEditingController();
  File? selectedFile;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, documentProvider, child) {
        final documentTypes = widget.allowedTypes ?? 
            documentProvider.getDocumentTypesForPanel(widget.panel);

        return Card(
          elevation: 4,
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Belge Yükle',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),

                // Belge türü seçimi
                DropdownButtonFormField<String>(
                  value: selectedDocumentType,
                  decoration: InputDecoration(
                    labelText: 'Belge Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: documentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_formatDocumentType(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDocumentType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen belge türü seçin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Dosya seçimi
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attachment),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedFile?.path.split('/').last ?? 'Dosya Seç',
                            style: TextStyle(
                              color: selectedFile != null 
                                  ? Colors.green 
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(Icons.folder_open),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Açıklama
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama (Opsiyonel)',
                    border: OutlineInputBorder(),
                    hintText: 'Belge hakkında kısa açıklama...',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Yükleme ilerlemesi
                if (documentProvider.isLoading || documentProvider.uploadProgress > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: documentProvider.uploadProgress,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${(documentProvider.uploadProgress * 100).toInt()}% tamamlandı',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),

                // Hata mesajı
                if (documentProvider.error != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            documentProvider.error!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 16),
                          onPressed: documentProvider.clearError,
                        ),
                      ],
                    ),
                  ),

                // Yükle butonu
                ElevatedButton.icon(
                  onPressed: documentProvider.isLoading ? null : _uploadDocument,
                  icon: documentProvider.isLoading 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.cloud_upload),
                  label: Text(
                    documentProvider.isLoading ? 'Yükleniyor...' : 'Belgeyi Yükle',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçme hatası: $e')),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir dosya seçin')),
      );
      return;
    }

    if (selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen belge türü seçin')),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    
    final document = await documentProvider.uploadDocument(
      file: selectedFile!,
      panel: widget.panel,
      customerId: widget.customerId,
      documentType: selectedDocumentType!,
      description: descriptionController.text,
    );

    if (document != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belge başarıyla yüklendi'),
          backgroundColor: Colors.green,
        ),
      );

      // Form'u temizle
      setState(() {
        selectedFile = null;
        selectedDocumentType = null;
        descriptionController.clear();
      });

      // Callback çağır
      if (widget.onDocumentUploaded != null) {
        widget.onDocumentUploaded!(document);
      }
    }
  }

  String _formatDocumentType(String type) {
    return type.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}