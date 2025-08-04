// Refactored by Cursor

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/transaction_service.dart';

import '../../services/service_service.dart';

class AddEditAppointmentPage extends StatefulWidget {
  final AppointmentModel? appointment;
  final String currentUserId;

  const AddEditAppointmentPage({
    Key? key,
    this.appointment,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<AddEditAppointmentPage> createState() => _AddEditAppointmentPageState();
}

class _AddEditAppointmentPageState extends State<AddEditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();

  // Controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // State variables
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCustomerId;
  String? _selectedEmployeeId;
  String? _selectedServiceId;
  AppointmentStatus _selectedStatus = AppointmentStatus.pending;
  bool _isPaid = false;
  bool _isLoading = false;
  int _estimatedDuration = 60; // dakika cinsinden varsayılan süre

  // Getter for current user ID
  String get _currentUserId => widget.currentUserId;

  // Data lists
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _employees = [];

  final ServiceService _serviceService = ServiceService();

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadData();
  }

  void _initializeFields() {
    if (widget.appointment != null) {
      final appointment = widget.appointment!;
      _customerNameController.text = appointment.customerName ?? '';
      _notesController.text = appointment.notes ?? '';
      _priceController.text = appointment.price?.toString() ?? '';
      _selectedDate = appointment.date;
      _selectedTime = appointment.time;
      _selectedEmployeeId = appointment.employeeId;
      _selectedCustomerId = appointment.customerId;
      _selectedServiceId = appointment.serviceId;
      _selectedStatus = appointment.status;
      _isPaid = appointment.isPaid;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCustomers(),
      _loadEmployees(),
      _loadServices(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadCustomers() async {
    try {
      final customerSnap =
          await FirebaseFirestore.instance.collection('customers').get();
      if (mounted) {
        setState(() {
          _customers = customerSnap.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? 'İsimsiz Müşteri',
                    ...doc.data()
                  })
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteri listesi yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employeeSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();
      if (mounted) {
        setState(() {
          _employees = employeeSnap.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? 'İsimsiz Çalışan',
                    ...doc.data()
                  })
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çalışan listesi yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _loadServices() async {
    try {
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      setState(() {
        _services = servicesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] ?? '',
                  'price': (doc['price'] ?? 0.0).toDouble(),
                  'category': doc['category'] ?? '',
                  'duration':
                      (doc['duration'] ?? 60).toInt(), // varsayılan 60 dakika
                })
            .toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Hizmetler yüklenirken hata: $e');
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    // Çakışma kontrolü
    if (_selectedEmployeeId != null) {
      final hasConflict = await _checkAppointmentConflict();
      if (hasConflict) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Seçilen çalışan bu saatte başka bir randevuya sahip!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final appointmentData = AppointmentModel(
        id: widget.appointment?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId,
        customerId: _selectedCustomerId,
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : _selectedCustomerId != null
                ? _customers
                    .firstWhere((c) => c['id'] == _selectedCustomerId)['name']
                : null,
        employeeId: _selectedEmployeeId,
        employeeName: _selectedEmployeeId != null
            ? _employees
                .firstWhere((e) => e['id'] == _selectedEmployeeId)['name']
            : null,
        serviceId: _selectedServiceId,
        // serviceName is a getter, not a constructor parameter
        date: _selectedDate,
        time: _selectedTime,
        duration: _estimatedDuration,
        status: _selectedStatus,
        notes: _notesController.text.trim(),
        price: double.tryParse(_priceController.text.trim()),
        // isPaid is a getter, not a constructor parameter
        createdAt: widget.appointment?.createdAt ?? DateTime.now(),
        updatedAt: widget.appointment != null ? DateTime.now() : null,
      );

      if (widget.appointment == null) {
        await _appointmentService.addAppointment(appointmentData);

        if (_selectedStatus == AppointmentStatus.completed && _isPaid) {
          try {
            await TransactionService().addFromAppointment(appointmentData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gelir kaydı oluşturulamadı!')),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Randevu başarıyla oluşturuldu! 🎉'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        await _appointmentService.updateAppointment(appointmentData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Randevu başarıyla güncellendi! ✅'),
                backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddCustomerModal() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCustomerModal(
        onSaved: (customerData) {
          Navigator.pop(context, customerData);
        },
      ),
    );

    if (result != null) {
      // Yeni müşteriyi listeye ekle ve seç
      setState(() {
        _customers.add({
          'id': result['id']!,
          'name': result['name']!,
          'phone': result['phone'] ?? '',
          'email': result['email'] ?? '',
        });
        _selectedCustomerId = result['id'];
        _customerNameController.text = result['name']!;
      });
    }
  }

  Future<bool> _checkAppointmentConflict() async {
    try {
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final endDateTime =
          appointmentDateTime.add(Duration(minutes: _estimatedDuration));

      final conflictQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('employeeId', isEqualTo: _selectedEmployeeId)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate))
          .get();

      for (final doc in conflictQuery.docs) {
        if (widget.appointment?.id == doc.id)
          continue; // Kendi randevusunu atla

        final existingTime =
            TimeOfDay.fromDateTime((doc['time'] as Timestamp).toDate());
        final existingDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          existingTime.hour,
          existingTime.minute,
        );
        final existingEndDateTime =
            existingDateTime.add(Duration(minutes: doc['duration'] ?? 60));

        // Çakışma kontrolü
        if ((appointmentDateTime.isBefore(existingEndDateTime) &&
            endDateTime.isAfter(existingDateTime))) {
          return true; // Çakışma var
        }
      }
      return false; // Çakışma yok
    } catch (e) {
      if (kDebugMode) debugPrint('Çakışma kontrolü hatası: $e');
      return false;
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    String? Function(String?)? validator,
    String hint = 'Seçiniz...',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
            filled: true,
            fillColor: const Color(0xFFF5F9FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1A73E8)),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durum',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AppointmentStatus>(
              value: _selectedStatus,
              isExpanded: true,
              onChanged: (value) => setState(() => _selectedStatus = value!),
              items: AppointmentStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(status.icon, color: status.color, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        status.text,
                        style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.appointment != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Randevu Düzenle ✏️' : 'Yeni Randevu 📅',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isEdit ? Icons.save : Icons.add, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          isEdit ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Veriler yükleniyor...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Müşteri Bilgileri Kartı
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8)
                                      .withValues(alpha: 25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1A73E8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Müşteri Bilgileri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Müşteri Seçimi *',
                                  value: _selectedCustomerId,
                                  items: _customers
                                      .map((c) => DropdownMenuItem(
                                            value: c['id'] as String,
                                            child: Text(c['name'] as String),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCustomerId = val;
                                      if (val != null) {
                                        final customer = _customers
                                            .firstWhere((c) => c['id'] == val);
                                        _customerNameController.text =
                                            customer['name'] as String;
                                      }
                                    });
                                  },
                                  icon: Icons.person,
                                  validator: (val) => val == null
                                      ? 'Lütfen bir müşteri seçin'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                margin: const EdgeInsets.only(top: 24),
                                child: ElevatedButton.icon(
                                  onPressed: _showAddCustomerModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'Yeni\nMüşteri',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCustomTextField(
                            controller: _customerNameController,
                            label: 'Müşteri Adı',
                            icon: Icons.person_outline,
                            hint: 'Müşteri adını girin veya yukarıdan seçin',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hizmet Bilgileri Kartı
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.work,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Hizmet Bilgileri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField(
                            label: 'Hizmet Seçimi',
                            value: _selectedServiceId,
                            items: _services
                                .map((s) => DropdownMenuItem(
                                      value: s['id'] as String,
                                      child:
                                          Text('${s['name']} - ${s['price']}₺'),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedServiceId = val;
                                if (val != null) {
                                  final service = _services
                                      .firstWhere((s) => s['id'] == val);
                                  _priceController.text =
                                      service['price'].toString();
                                  _estimatedDuration =
                                      service['duration'] as int;
                                }
                              });
                            },
                            icon: Icons.work,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Çalışan Seçimi',
                            value: _selectedEmployeeId,
                            items: _employees
                                .map((e) => DropdownMenuItem(
                                      value: e['id'] as String,
                                      child: Text(e['name'] as String),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedEmployeeId = val),
                            icon: Icons.badge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Randevu Detayları Kartı
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.event,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Randevu Detayları',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimeSelector(
                                  label: 'Tarih',
                                  value: DateFormat('dd MMMM yyyy', 'tr_TR')
                                      .format(_selectedDate),
                                  icon: Icons.calendar_today,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 1)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateTimeSelector(
                                  label: 'Saat',
                                  value:
                                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  icon: Icons.access_time,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime,
                                    );
                                    if (time != null) {
                                      setState(() => _selectedTime = time);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomTextField(
                                  controller: TextEditingController(
                                      text: _estimatedDuration.toString()),
                                  label: 'Süre (dakika)',
                                  icon: Icons.timer,
                                  keyboardType: TextInputType.number,
                                  hint: 'Randevu süresi',
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final duration = int.tryParse(value);
                                      if (duration == null || duration <= 0) {
                                        return 'Geçerli bir süre girin';
                                      }
                                      _estimatedDuration = duration;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCustomTextField(
                                  controller: _priceController,
                                  label: 'Tutar (₺)',
                                  icon: Icons.money,
                                  keyboardType: TextInputType.number,
                                  hint: 'Hizmet ücreti',
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (double.tryParse(value) == null) {
                                        return 'Geçerli bir tutar girin';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusSelector(),
                          const SizedBox(height: 16),
                          _buildCustomTextField(
                            controller: _notesController,
                            label: 'Notlar',
                            icon: Icons.note,
                            maxLines: 3,
                            hint: 'Randevu ile ilgili notlarınız...',
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isPaid
                                  ? Colors.green.withValues(alpha: 25)
                                  : Colors.grey.withValues(alpha: 25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isPaid
                                    ? Colors.green.withValues(alpha: 76)
                                    : Colors.grey.withValues(alpha: 76),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isPaid ? Icons.check_circle : Icons.payment,
                                  color: _isPaid
                                      ? Colors.green
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Ödeme Durumu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isPaid
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _isPaid,
                                  onChanged: (val) =>
                                      setState(() => _isPaid = val),
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class AddCustomerModal extends StatefulWidget {
  final Function(Map<String, String>) onSaved;

  const AddCustomerModal({
    Key? key,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final customerId = now.millisecondsSinceEpoch.toString();

      final customerData = {
        'id': customerId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .set(customerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Müşteri başarıyla eklendi! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onSaved({
          'id': customerId,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Yeni Müşteri Ekle 👤',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad *',
                  hintText: 'Müşteri adını girin',
                  prefixIcon:
                      const Icon(Icons.person, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: const Color(0xFFF5F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad Soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  hintText: '05XX XXX XX XX',
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: const Color(0xFFF5F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  hintText: 'ornek@email.com',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF1A73E8)),
                  filled: true,
                  fillColor: const Color(0xFFF5F9FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A73E8), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Müşteri Ekle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
