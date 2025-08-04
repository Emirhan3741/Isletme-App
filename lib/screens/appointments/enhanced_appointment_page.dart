import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/enhanced_file_upload_service.dart';
import '../../widgets/file_upload_widgets.dart';
import '../../providers/auth_provider.dart';

class EnhancedAppointmentPage extends StatefulWidget {
  final String? appointmentId;
  final bool isEditing;

  const EnhancedAppointmentPage({
    super.key,
    this.appointmentId,
    this.isEditing = false,
  });

  @override
  State<EnhancedAppointmentPage> createState() =>
      _EnhancedAppointmentPageState();
}

class _EnhancedAppointmentPageState extends State<EnhancedAppointmentPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final EnhancedFileUploadService _uploadService = EnhancedFileUploadService();

  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Form data
  String? _selectedCustomerId;
  String? _selectedServiceId;
  String? _selectedStaffId;
  DateTime? _selectedStartDateTime;
  DateTime? _selectedEndDateTime;
  String _selectedStatus = 'scheduled';
  String _selectedPriority = 'normal';
  String _selectedPaymentStatus = 'pending';

  // State management
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _appointmentData;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _documents = [];

  // Constants
  static const List<String> _statusOptions = [
    'scheduled',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'no_show',
  ];

  static const List<String> _priorityOptions = [
    'low',
    'normal',
    'high',
    'urgent',
  ];

  static const List<String> _paymentStatusOptions = [
    'pending',
    'partial',
    'paid',
    'refunded',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load supporting data in parallel
      final futures = await Future.wait([
        _firestoreService.getCustomers(),
        _firestoreService.getServices(isActive: true),
        _firestoreService.getStaff(isActive: true),
      ]);

      setState(() {
        _customers = futures[0];
        _services = futures[1];
        _staff = futures[2];
      });

      // Load appointment data if editing
      if (widget.isEditing && widget.appointmentId != null) {
        await _loadAppointmentData();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppointmentData() async {
    try {
      final appointmentData = await _firestoreService.getGenericDocument(
        collection: FirestoreService.appointmentsCollection,
        docId: widget.appointmentId!,
      );

      if (appointmentData != null) {
        setState(() {
          _appointmentData = appointmentData;
          _titleController.text = appointmentData['title'] ?? '';
          _descriptionController.text = appointmentData['description'] ?? '';
          _notesController.text = appointmentData['notes'] ?? '';
          _priceController.text = (appointmentData['price'] ?? 0.0).toString();
          _selectedCustomerId = appointmentData['customerId'];
          _selectedServiceId = appointmentData['serviceId'];
          _selectedStaffId = appointmentData['staffId'];
          _selectedStatus = appointmentData['status'] ?? 'scheduled';
          _selectedPriority = appointmentData['priority'] ?? 'normal';
          _selectedPaymentStatus =
              appointmentData['paymentStatus'] ?? 'pending';

          final startTimestamp = appointmentData['startDateTime'] as Timestamp?;
          final endTimestamp = appointmentData['endDateTime'] as Timestamp?;
          _selectedStartDateTime = startTimestamp?.toDate();
          _selectedEndDateTime = endTimestamp?.toDate();
        });

        // Load documents
        await _loadDocuments();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load appointment: ${e.toString()}');
    }
  }

  Future<void> _loadDocuments() async {
    if (widget.appointmentId == null) return;

    try {
      final documents = await _uploadService.getEntityDocuments(
        entityType: 'appointment',
        entityId: widget.appointmentId!,
      );

      setState(() {
        _documents = documents;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load documents: ${e.toString()}');
    }
  }

  Future<bool> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to first tab if validation fails
      return false;
    }

    if (_selectedCustomerId == null || _selectedServiceId == null) {
      _showErrorSnackBar('Please select a customer and service');
      return false;
    }

    if (_selectedStartDateTime == null || _selectedEndDateTime == null) {
      _showErrorSnackBar('Please select start and end times');
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appointmentData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'customerId': _selectedCustomerId!,
        'serviceId': _selectedServiceId!,
        'staffId': _selectedStaffId,
        'startDateTime': Timestamp.fromDate(_selectedStartDateTime!),
        'endDateTime': Timestamp.fromDate(_selectedEndDateTime!),
        'duration':
            _selectedEndDateTime!.difference(_selectedStartDateTime!).inMinutes,
        'status': _selectedStatus,
        'priority': _selectedPriority,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'currency': 'TRY',
        'paymentStatus': _selectedPaymentStatus,
        'sector': Provider.of<AuthProvider>(context, listen: false)
                .currentUser
                ?.sector ??
            '',
        'location': '',
        'reminderSent': false,
        'documents': _documents.map((doc) => doc['id']).toList(),
        'metadata': {},
      };

      String appointmentId;
      if (widget.isEditing && widget.appointmentId != null) {
        await _firestoreService.updateGenericDocument(
          collection: FirestoreService.appointmentsCollection,
          docId: widget.appointmentId!,
          data: appointmentData,
        );
        appointmentId = widget.appointmentId!;

        // Log the update action
        await _firestoreService.logAction(
          action: 'appointment_updated',
          entityType: 'appointment',
          entityId: appointmentId,
          details: {'title': appointmentData['title']},
        );
      } else {
        appointmentId = await _firestoreService.createAppointment(
          appointmentData: appointmentData,
        );

        // Log the creation action
        await _firestoreService.logAction(
          action: 'appointment_created',
          entityType: 'appointment',
          entityId: appointmentId,
          details: {'title': appointmentData['title']},
        );
      }

      _showSuccessSnackBar(
        widget.isEditing
            ? 'Appointment updated successfully'
            : 'Appointment created successfully',
      );

      return true;
    } catch (e) {
      _showErrorSnackBar('Failed to save appointment: ${e.toString()}');
      return false;
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDateTime({required bool isStartTime}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_selectedStartDateTime ?? DateTime.now())
          : (_selectedEndDateTime ?? _selectedStartDateTime ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime
              ? (_selectedStartDateTime ?? DateTime.now())
              : (_selectedEndDateTime ??
                  _selectedStartDateTime ??
                  DateTime.now()),
        ),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _selectedStartDateTime = dateTime;
            // Auto-set end time to 1 hour later if not set
            if (_selectedEndDateTime == null ||
                _selectedEndDateTime!.isBefore(dateTime)) {
              _selectedEndDateTime = dateTime.add(const Duration(hours: 1));
            }
          } else {
            _selectedEndDateTime = dateTime;
          }
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Appointment' : 'New Appointment'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.attach_file), text: 'Documents'),
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveAppointment,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.isEditing ? 'Update' : 'Save',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildDocumentsTab(),
                _buildPreviewTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selection Fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _customers.map<DropdownMenuItem<String>>((customer) {
                        return DropdownMenuItem<String>(
                          value: customer['id'],
                          child: Text(
                              '${customer['firstName']} ${customer['lastName']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Service Selection
                    DropdownButtonFormField<String>(
                      value: _selectedServiceId,
                      decoration: const InputDecoration(
                        labelText: 'Service *',
                        border: OutlineInputBorder(),
                      ),
                      items: _services.map<DropdownMenuItem<String>>((service) {
                        return DropdownMenuItem<String>(
                          value: service['id'],
                          child: Text(
                              '${service['name']} - ${service['price']} TRY'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedServiceId = value;
                          // Auto-fill price from service
                          final selectedService = _services.firstWhere(
                            (service) => service['id'] == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selectedService.isNotEmpty) {
                            _priceController.text =
                                (selectedService['price'] ?? 0.0).toString();
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a service';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Staff Selection
                    DropdownButtonFormField<String>(
                      value: _selectedStaffId,
                      decoration: const InputDecoration(
                        labelText: 'Staff Member',
                        border: OutlineInputBorder(),
                      ),
                      items: _staff.map<DropdownMenuItem<String>>((staff) {
                        return DropdownMenuItem<String>(
                          value: staff['id'],
                          child: Text(
                              '${staff['firstName']} ${staff['lastName']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStaffId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(
                              _selectedStartDateTime
                                      ?.toString()
                                      .substring(0, 16) ??
                                  'Not selected',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectDateTime(isStartTime: true),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(
                              _selectedEndDateTime
                                      ?.toString()
                                      .substring(0, 16) ??
                                  'Not selected',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () => _selectDateTime(isStartTime: false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status and Priority
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status & Priority',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: _statusOptions
                                .map<DropdownMenuItem<String>>((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: _priorityOptions
                                .map<DropdownMenuItem<String>>((priority) {
                              return DropdownMenuItem<String>(
                                value: priority,
                                child: Text(priority.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (TRY)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPaymentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status',
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentStatusOptions
                                .map<DropdownMenuItem<String>>((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentStatus = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Internal Notes',
                        border: OutlineInputBorder(),
                        hintText:
                            'Add any internal notes about this appointment...',
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (widget.appointmentId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Save appointment first',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'You need to save the appointment before uploading documents',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FileListWidget(
            entityType: 'appointment',
            entityId: widget.appointmentId!,
            allowUpload: true,
            allowDelete: true,
            uploadButtonText: 'Add Document',
            allowedExtensions: const [
              'pdf',
              'jpg',
              'jpeg',
              'png',
              'doc',
              'docx'
            ],
          ),
          const SizedBox(height: 16),
          // Quick upload buttons for common document types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Upload',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FileUploadButton(
                        module: 'appointment',
                        entityId: widget.appointmentId!,
                        documentType: 'contract',
                        buttonText: 'Contract',
                        icon: Icons.description,
                        onUploadComplete: _loadDocuments,
                      ),
                      FileUploadButton(
                        module: 'appointment',
                        entityId: widget.appointmentId!,
                        documentType: 'invoice',
                        buttonText: 'Invoice',
                        icon: Icons.receipt,
                        onUploadComplete: _loadDocuments,
                      ),
                      FileUploadButton(
                        module: 'appointment',
                        entityId: widget.appointmentId!,
                        documentType: 'medical_report',
                        buttonText: 'Medical Report',
                        icon: Icons.medical_services,
                        onUploadComplete: _loadDocuments,
                      ),
                      FileUploadButton(
                        module: 'appointment',
                        entityId: widget.appointmentId!,
                        documentType: 'photo',
                        buttonText: 'Photo',
                        icon: Icons.camera_alt,
                        allowedExtensions: const ['jpg', 'jpeg', 'png'],
                        onUploadComplete: _loadDocuments,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointment Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildPreviewRow(
                  'Title',
                  _titleController.text.isEmpty
                      ? 'Not set'
                      : _titleController.text),
              _buildPreviewRow(
                  'Description',
                  _descriptionController.text.isEmpty
                      ? 'Not set'
                      : _descriptionController.text),
              if (_selectedCustomerId != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Customer', () {
                  final customer = _customers.firstWhere(
                    (c) => c['id'] == _selectedCustomerId,
                    orElse: () => <String, dynamic>{},
                  );
                  return customer.isNotEmpty
                      ? '${customer['firstName']} ${customer['lastName']}'
                      : 'Unknown';
                }()),
              ],
              if (_selectedServiceId != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Service', () {
                  final service = _services.firstWhere(
                    (s) => s['id'] == _selectedServiceId,
                    orElse: () => <String, dynamic>{},
                  );
                  return service.isNotEmpty ? service['name'] : 'Unknown';
                }()),
              ],
              if (_selectedStaffId != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Staff', () {
                  final staff = _staff.firstWhere(
                    (s) => s['id'] == _selectedStaffId,
                    orElse: () => <String, dynamic>{},
                  );
                  return staff.isNotEmpty
                      ? '${staff['firstName']} ${staff['lastName']}'
                      : 'Unknown';
                }()),
              ],
              if (_selectedStartDateTime != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Start Time',
                    _selectedStartDateTime!.toString().substring(0, 16)),
              ],
              if (_selectedEndDateTime != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('End Time',
                    _selectedEndDateTime!.toString().substring(0, 16)),
              ],
              if (_selectedStartDateTime != null &&
                  _selectedEndDateTime != null) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Duration',
                    '${_selectedEndDateTime!.difference(_selectedStartDateTime!).inMinutes} minutes'),
              ],
              const SizedBox(height: 8),
              _buildPreviewRow('Status', _selectedStatus.toUpperCase()),
              _buildPreviewRow('Priority', _selectedPriority.toUpperCase()),
              _buildPreviewRow(
                  'Payment Status', _selectedPaymentStatus.toUpperCase()),
              if (_priceController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Price', '${_priceController.text} TRY'),
              ],
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPreviewRow('Notes', _notesController.text),
              ],
              if (_documents.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPreviewRow(
                    'Documents', '${_documents.length} file(s) attached'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
