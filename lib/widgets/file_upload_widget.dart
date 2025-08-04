import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/file_upload_service.dart';
import '../core/constants/app_constants.dart';

class UploadedFileData {
  final String fileName;
  final String originalFileName;
  final String fileUrl;
  final String fileExtension;
  final int fileSizeBytes;
  final double fileSizeMB;
  final DateTime uploadDate;
  final String storagePath;

  UploadedFileData({
    required this.fileName,
    required this.originalFileName,
    required this.fileUrl,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.fileSizeMB,
    required this.uploadDate,
    required this.storagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'originalFileName': originalFileName,
      'fileUrl': fileUrl,
      'fileExtension': fileExtension,
      'fileSizeBytes': fileSizeBytes,
      'fileSizeMB': fileSizeMB,
      'uploadDate': uploadDate.toIso8601String(),
      'storagePath': storagePath,
    };
  }
}

class FileUploadWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onUploadComplete;
  final List<String>? allowedExtensions;
  final int? maxFileSize;
  final String category;
  final String? module;
  final String? collection;
  final Map<String, dynamic>? additionalData;
  final VoidCallback? onUploadSuccess;
  final Function(String)? onUploadError;
  final bool isRequired;
  final bool showPreview;
  final String? initialFileUrl;
  final String? initialFileName;

  const FileUploadWidget({
    super.key,
    required this.onUploadComplete,
    this.allowedExtensions,
    this.maxFileSize,
    this.category = 'general',
    this.module,
    this.collection,
    this.additionalData,
    this.onUploadSuccess,
    this.onUploadError,
    this.isRequired = false,
    this.showPreview = true,
    this.initialFileUrl,
    this.initialFileName,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FileUploadService _uploadService = FileUploadService();
  List<PlatformFile> _uploadedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  UploadedFileData? _uploadedFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialFileUrl != null && widget.initialFileName != null) {
      _uploadedFile = UploadedFileData(
        fileName: widget.initialFileName!,
        originalFileName: widget.initialFileName!,
        fileUrl: widget.initialFileUrl!,
        fileExtension: widget.initialFileName!.split('.').last,
        fileSizeBytes: 0,
        fileSizeMB: 0,
        uploadDate: DateTime.now(),
        storagePath: '',
      );
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size
        if (file.size > (widget.maxFileSize ?? 10 * 1024 * 1024)) {
          throw Exception('Dosya boyutu çok büyük');
        }

        // Create upload data
        final uploadResult = UploadedFileData(
          fileName: file.name,
          originalFileName: file.name,
          fileUrl: 'temp_url', // This would be set by actual upload service
          fileExtension: file.extension ?? '',
          fileSizeBytes: file.size,
          fileSizeMB: file.size / (1024 * 1024),
          uploadDate: DateTime.now(),
          storagePath: 'temp_path',
        );

        setState(() {
          _uploadedFile = uploadResult;
          _isUploading = false;
        });

        widget.onUploadComplete(uploadResult.toMap());
        widget.onUploadSuccess?.call();
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
      widget.onUploadError?.call(e.toString());
    }
  }

  void _removeFile() {
    setState(() {
      _uploadedFile = null;
      _uploadedFiles.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_uploadedFile != null && widget.showPreview) ...[
            _buildFilePreview(),
            const SizedBox(height: 16),
          ],
          if (_uploadedFile == null) ...[
            _buildUploadArea(),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Column(
      children: [
        if (_isUploading) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text('Yükleniyor... ${(_uploadProgress * 100).toInt()}%'),
        ] else ...[
          InkWell(
            onTap: _pickAndUploadFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dosya seçmek için tıklayın',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Desteklenen formatlar: ${widget.allowedExtensions?.join(', ') ?? 'Tüm dosya tipleri'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maksimum dosya boyutu: ${(widget.maxFileSize ?? 10 * 1024 * 1024) ~/ (1024 * 1024)} MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilePreview() {
    final file = _uploadedFile!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file.fileExtension),
            color: AppConstants.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalFileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${file.fileSizeMB.toStringAsFixed(2)} MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeFile,
            icon: const Icon(Icons.close),
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.attach_file;
    }
  }
}

// Additional file upload widget with different UI
class SimpleFileUploadWidget extends StatefulWidget {
  final String? module;
  final String? collection;
  final Map<String, dynamic>? additionalData;
  final Function()? onUploadSuccess;
  final Function(String)? onUploadError;
  final bool isRequired;
  final bool showPreview;

  const SimpleFileUploadWidget({
    super.key,
    this.module,
    this.collection,
    this.additionalData,
    this.onUploadSuccess,
    this.onUploadError,
    this.isRequired = false,
    this.showPreview = true,
  });

  @override
  State<SimpleFileUploadWidget> createState() => _SimpleFileUploadWidgetState();
}

class _SimpleFileUploadWidgetState extends State<SimpleFileUploadWidget> {
  final FileUploadService _uploadService = FileUploadService();
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_isUploading ? 'Yükleniyor...' : 'Dosya Seç'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        // Simulate upload success
        await Future.delayed(const Duration(seconds: 1));
        widget.onUploadSuccess?.call();
      }
    } catch (e) {
      _errorMessage = e.toString();
      widget.onUploadError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
