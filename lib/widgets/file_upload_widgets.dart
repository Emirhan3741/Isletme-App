import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/enhanced_file_upload_service.dart';

/// File upload button with progress indicator and error handling
class FileUploadButton extends StatefulWidget {
  final String module;
  final String? entityId;
  final String documentType;
  final String? title;
  final String? description;
  final List<String>? tags;
  final List<String>? allowedExtensions;
  final VoidCallback? onUploadComplete;
  final Function(String)? onUploadError;
  final String buttonText;
  final IconData? icon;
  final Color? buttonColor;
  final bool enabled;
  final double? maxWidth;

  const FileUploadButton({
    super.key,
    required this.module,
    this.entityId,
    required this.documentType,
    this.title,
    this.description,
    this.tags,
    this.allowedExtensions,
    this.onUploadComplete,
    this.onUploadError,
    this.buttonText = 'Upload File',
    this.icon,
    this.buttonColor,
    this.enabled = true,
    this.maxWidth,
  });

  @override
  State<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends State<FileUploadButton> {
  final EnhancedFileUploadService _uploadService = EnhancedFileUploadService();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  Future<void> _handleUpload() async {
    if (!widget.enabled || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      FileUploadResultExtended result;

      switch (widget.module) {
        case 'profile':
          result = await _uploadService.uploadProfilePhoto(
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'appointment':
          if (widget.entityId == null) {
            throw Exception('Appointment ID is required');
          }
          result = await _uploadService.uploadAppointmentDocument(
            appointmentId: widget.entityId!,
            documentType: widget.documentType,
            title: widget.title,
            description: widget.description,
            tags: widget.tags,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'customer':
          if (widget.entityId == null) {
            throw Exception('Customer ID is required');
          }
          result = await _uploadService.uploadCustomerDocument(
            customerId: widget.entityId!,
            documentType: widget.documentType,
            title: widget.title,
            description: widget.description,
            tags: widget.tags,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'staff':
          if (widget.entityId == null) {
            throw Exception('Staff ID is required');
          }
          result = await _uploadService.uploadStaffDocument(
            staffId: widget.entityId!,
            documentType: widget.documentType,
            title: widget.title,
            description: widget.description,
            tags: widget.tags,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'service':
          if (widget.entityId == null) {
            throw Exception('Service ID is required');
          }
          result = await _uploadService.uploadServiceDocument(
            serviceId: widget.entityId!,
            documentType: widget.documentType,
            title: widget.title,
            description: widget.description,
            tags: widget.tags,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'general':
        default:
          result = await _uploadService.uploadGeneralDocument(
            documentType: widget.documentType,
            title: widget.title,
            description: widget.description,
            tags: widget.tags,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
      }

      if (result.success) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        widget.onUploadComplete?.call();
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      HapticFeedback.lightImpact();
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Upload failed: $errorMsg')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleUpload,
            ),
          ),
        );
      }
      widget.onUploadError?.call(errorMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget button = SizedBox(
      width: widget.maxWidth,
      child: ElevatedButton.icon(
        onPressed: widget.enabled && !_isUploading ? _handleUpload : null,
        icon: _isUploading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Icon(widget.icon ?? Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : widget.buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.buttonColor ?? theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );

    if (_isUploading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.buttonColor ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    return button;
  }
}

/// File list widget with upload, download, and delete capabilities
class FileListWidget extends StatefulWidget {
  final String entityType;
  final String entityId;
  final String? documentType;
  final bool allowUpload;
  final bool allowDelete;
  final String uploadButtonText;
  final List<String>? allowedExtensions;

  const FileListWidget({
    super.key,
    required this.entityType,
    required this.entityId,
    this.documentType,
    this.allowUpload = true,
    this.allowDelete = true,
    this.uploadButtonText = 'Add File',
    this.allowedExtensions,
  });

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  final EnhancedFileUploadService _uploadService = EnhancedFileUploadService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final documents = await _uploadService.getEntityDocuments(
        entityType: widget.entityType,
        entityId: widget.entityId,
        documentType: widget.documentType,
      );

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDocument(String documentId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _uploadService.deleteDocument(documentId);
        if (success) {
          HapticFeedback.lightImpact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('File deleted successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadDocuments(); // Refresh the list
        } else {
          throw Exception('Failed to delete file');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Delete failed: ${e.toString()}'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
        return Icons.video_file;
      case 'mp3':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.allowUpload)
                  FileUploadButton(
                    module: widget.entityType,
                    entityId: widget.entityId,
                    documentType: widget.documentType ?? 'general',
                    buttonText: widget.uploadButtonText,
                    icon: Icons.add,
                    allowedExtensions: widget.allowedExtensions,
                    onUploadComplete: _loadDocuments,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load files',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadDocuments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_documents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No files yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (widget.allowUpload) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Upload your first file using the button above',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _documents.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  final fileName =
                      doc['originalFileName'] as String? ?? 'Unknown';
                  final fileSize = doc['fileSizeBytes'] as int? ?? 0;
                  final fileExtension = doc['fileExtension'] as String? ?? '';
                  final uploadDate =
                      (doc['uploadedAt'] as Timestamp?)?.toDate();
                  final fileUrl = doc['fileUrl'] as String? ?? '';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getFileIcon(fileExtension),
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(fileName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatFileSize(fileSize)),
                        if (uploadDate != null)
                          Text(
                            'Uploaded: ${uploadDate.day}/${uploadDate.month}/${uploadDate.year}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fileUrl != null)
                          IconButton(
                            onPressed: () {
                              // TODO: Implement file download/view
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('File download will be implemented'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.download),
                            tooltip: 'Download',
                          ),
                        if (widget.allowDelete)
                          IconButton(
                            onPressed: () =>
                                _deleteDocument(doc['id'], fileName),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            color: theme.colorScheme.error,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Storage usage widget
class StorageUsageWidget extends StatefulWidget {
  const StorageUsageWidget({super.key});

  @override
  State<StorageUsageWidget> createState() => _StorageUsageWidgetState();
}

class _StorageUsageWidgetState extends State<StorageUsageWidget> {
  final EnhancedFileUploadService _uploadService = EnhancedFileUploadService();
  StorageUsageStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final stats = await _uploadService.getStorageUsage();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Unable to load storage usage')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Storage Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Total: ${_stats!.formattedTotalSize}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Files: ${_stats!.totalFiles}'),
              ],
            ),
            if (_stats!.categorySize.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'By Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._stats!.categorySize.entries.map((entry) {
                final sizeMB = entry.value;
                final sizeText = sizeMB < 1024
                    ? '${sizeMB.toStringAsFixed(1)} MB'
                    : '${(sizeMB / 1024).toStringAsFixed(2)} GB';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        sizeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
