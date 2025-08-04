import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ClinicAppointmentsPage extends StatefulWidget {
  const ClinicAppointmentsPage({super.key});

  @override
  State<ClinicAppointmentsPage> createState() => _ClinicAppointmentsPageState();
}

class _ClinicAppointmentsPageState extends State<ClinicAppointmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'tumu';
  bool _isLoading = false;
  List<ClinicAppointment> _appointments = [];
  List<ClinicPatient> _patients = [];
  List<ClinicService> _services = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadAppointments(),
      _loadPatients(),
      _loadServices(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicAppointmentsCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('appointmentDate', descending: true)
          .get();

      final appointments = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicAppointment(
          id: doc.id,
          userId: user.uid,
          patientId: data['patientId'] ?? '',
          patientName: data['patientName'] ?? '',
          serviceId: data['serviceId'],
          serviceName: data['serviceName'] ?? '',
          appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
          duration: data['duration'] ?? 60,
          price: (data['price'] ?? 0.0).toDouble(),
          status: data['status'] ?? 'pending',
          priority: data['priority'] ?? 'normal',
          notes: data['notes'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _appointments = appointments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Randevuları yüklerken hata: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadPatients() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicPatientsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final patients = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicPatient(
          id: doc.id,
          userId: user.uid,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          email: data['email'],
          isVip: data['isVip'] ?? false,
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _patients = patients);
    } catch (e) {
      if (kDebugMode) debugPrint('Hastaları yüklerken hata: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.clinicServicesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      final services = snapshot.docs.map((doc) {
        final data = doc.data();
        return ClinicService(
          id: doc.id,
          userId: user.uid,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          duration: data['duration'] ?? 60,
          description: data['description'],
          isActive: data['isActive'] ?? true,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      setState(() => _services = services);
    } catch (e) {
      if (kDebugMode) debugPrint('Hizmetleri yüklerken hata: $e');
    }
  }

  List<ClinicAppointment> get filteredAppointments {
    List<ClinicAppointment> filtered = _appointments;

    // Durum filtreleme
    if (_selectedFilter == 'pending') {
      filtered = filtered.where((app) => app.status == 'pending').toList();
    } else if (_selectedFilter == 'confirmed') {
      filtered = filtered.where((app) => app.status == 'confirmed').toList();
    } else if (_selectedFilter == 'completed') {
      filtered = filtered.where((app) => app.status == 'completed').toList();
    } else if (_selectedFilter == 'cancelled') {
      filtered = filtered.where((app) => app.status == 'cancelled').toList();
    } else if (_selectedFilter == 'today') {
      final today = DateTime.now();
      filtered = filtered
          .where((app) =>
              app.appointmentDate.year == today.year &&
              app.appointmentDate.month == today.month &&
              app.appointmentDate.day == today.day)
          .toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((app) =>
              app.patientName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              app.serviceName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Üst başlık ve yeni randevu butonu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Randevular',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Yeni Randevu',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arama kutusu
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Randevu ara (Hasta adı, hizmet)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide:
                      BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filtre butonları
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tümü', 'tumu'),
                  _buildFilterChip('Bugün', 'today'),
                  _buildFilterChip('Bekliyor', 'pending'),
                  _buildFilterChip('Onaylı', 'confirmed'),
                  _buildFilterChip('Tamamlandı', 'completed'),
                  _buildFilterChip('İptal', 'cancelled'),
                ],
              ),
            ),
          ),

          // Randevu listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAppointments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        backgroundColor: AppConstants.surfaceColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConstants.primaryColor,
        labelStyle: TextStyle(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(ClinicAppointment appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final priorityColor = _getPriorityColor(appointment.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: AppConstants.elevationSmall,
      child: InkWell(
        onTap: () => _showAppointmentDetail(appointment),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Hasta adı ve durum
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.patientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Hizmet bilgisi
              Row(
                children: [
                  const Icon(Icons.medical_services,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.serviceName,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  if (appointment.priority != 'normal')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPriorityText(appointment.priority),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Tarih, saat ve süre
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(appointment.appointmentDate)} - ${_formatTime(appointment.appointmentDate)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '(${appointment.duration} dk)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingSmall),

              // Ücret ve işlemler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₺${appointment.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (appointment.status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _updateAppointmentStatus(
                              appointment, 'confirmed'),
                          tooltip: 'Onayla',
                        ),
                      if (appointment.status == 'confirmed')
                        IconButton(
                          icon: const Icon(Icons.done_all, color: Colors.blue),
                          onPressed: () => _updateAppointmentStatus(
                              appointment, 'completed'),
                          tooltip: 'Tamamla',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () =>
                            _showEditAppointmentDialog(appointment),
                        tooltip: 'Düzenle',
                      ),
                      if (appointment.status != 'completed')
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateAppointmentStatus(
                              appointment, 'cancelled'),
                          tooltip: 'İptal Et',
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 64,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchQuery.isNotEmpty
                ? 'Arama kriterlerine uygun randevu bulunamadı'
                : 'Henüz randevu eklenmemiş',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Farklı anahtar kelimeler deneyebilirsiniz'
                : 'İlk randevunuzu eklemek için + butonuna tıklayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'confirmed':
        return 'Onaylı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      default:
        return 'Normal';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEditAppointmentDialog(
        patients: _patients,
        services: _services,
        onSaved: _loadAppointments,
      ),
    );
  }

  void _showEditAppointmentDialog(ClinicAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => _AddEditAppointmentDialog(
        appointment: appointment,
        patients: _patients,
        services: _services,
        onSaved: _loadAppointments,
      ),
    );
  }

  void _showAppointmentDetail(ClinicAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appointment.patientName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hizmet: ${appointment.serviceName}'),
            Text('Tarih: ${_formatDate(appointment.appointmentDate)}'),
            Text('Saat: ${_formatTime(appointment.appointmentDate)}'),
            Text('Süre: ${appointment.duration} dakika'),
            Text('Ücret: ₺${appointment.price.toStringAsFixed(0)}'),
            Text('Durum: ${_getStatusText(appointment.status)}'),
            Text('Öncelik: ${_getPriorityText(appointment.priority)}'),
            if (appointment.notes != null) Text('Not: ${appointment.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAppointmentStatus(
      ClinicAppointment appointment, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.clinicAppointmentsCollection)
          .doc(appointment.id)
          .update({'status': newStatus});

      await _loadAppointments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Randevu durumu güncellendi: ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Model sınıfları
class ClinicAppointment {
  final String id;
  final String userId;
  final String patientId;
  final String patientName;
  final String? serviceId;
  final String serviceName;
  final DateTime appointmentDate;
  final int duration;
  final double price;
  final String status;
  final String priority;
  final String? notes;
  final DateTime createdAt;

  ClinicAppointment({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    this.serviceId,
    required this.serviceName,
    required this.appointmentDate,
    required this.duration,
    required this.price,
    required this.status,
    required this.priority,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'patientId': patientId,
      'patientName': patientName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'duration': duration,
      'price': price,
      'status': status,
      'priority': priority,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ClinicPatient {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final bool isVip;
  final bool isActive;
  final DateTime createdAt;

  ClinicPatient({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    required this.isVip,
    required this.isActive,
    required this.createdAt,
  });
}

class ClinicService {
  final String id;
  final String userId;
  final String name;
  final double price;
  final int duration;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  ClinicService({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.duration,
    this.description,
    required this.isActive,
    required this.createdAt,
  });
}

// Randevu ekleme/düzenleme dialog'u
class _AddEditAppointmentDialog extends StatefulWidget {
  final ClinicAppointment? appointment;
  final List<ClinicPatient> patients;
  final List<ClinicService> services;
  final VoidCallback onSaved;

  const _AddEditAppointmentDialog({
    this.appointment,
    required this.patients,
    required this.services,
    required this.onSaved,
  });

  @override
  State<_AddEditAppointmentDialog> createState() =>
      _AddEditAppointmentDialogState();
}

class _AddEditAppointmentDialogState extends State<_AddEditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedServiceId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPriority = 'normal';
  double _price = 0.0;
  int _duration = 60;
  bool _isLoading = false;

  bool get isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadAppointmentData();
    }
  }

  void _loadAppointmentData() {
    final appointment = widget.appointment!;
    _selectedPatientId = appointment.patientId;
    _selectedServiceId = appointment.serviceId;
    _selectedDate = appointment.appointmentDate;
    _selectedTime = TimeOfDay.fromDateTime(appointment.appointmentDate);
    _selectedPriority = appointment.priority;
    _price = appointment.price;
    _duration = appointment.duration;
    _notesController.text = appointment.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium),
                    ),
                    child:
                        const Icon(Icons.calendar_month, color: Colors.green),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Text(
                      isEditing ? 'Randevu Düzenle' : 'Yeni Randevu',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Hasta seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedPatientId,
                        decoration: const InputDecoration(
                          labelText: 'Hasta *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: widget.patients.map((patient) {
                          return DropdownMenuItem(
                            value: patient.id,
                            child: Row(
                              children: [
                                Expanded(child: Text(patient.name)),
                                if (patient.isVip)
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPatientId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Hasta seçimi gerekli' : null,
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Hizmet seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedServiceId,
                        decoration: const InputDecoration(
                          labelText: 'Hizmet',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services),
                        ),
                        items: widget.services.map((service) {
                          return DropdownMenuItem(
                            value: service.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service.name),
                                Text(
                                  '₺${service.price.toStringAsFixed(0)} - ${service.duration} dk',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServiceId = value;
                            final service = widget.services
                                .firstWhere((s) => s.id == value);
                            _price = service.price;
                            _duration = service.duration;
                          });
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Tarih seçimi
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.grey),
                              const SizedBox(width: AppConstants.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tarih',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(
                                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Saat seçimi
                      InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, color: Colors.grey),
                              const SizedBox(width: AppConstants.paddingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Saat',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(
                                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      Row(
                        children: [
                          // Süre
                          Expanded(
                            child: TextFormField(
                              initialValue: _duration.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Süre (dk)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() =>
                                    _duration = int.tryParse(value) ?? 60);
                              },
                            ),
                          ),

                          const SizedBox(width: AppConstants.paddingMedium),

                          // Ücret
                          Expanded(
                            child: TextFormField(
                              initialValue: _price.toStringAsFixed(0),
                              decoration: const InputDecoration(
                                labelText: 'Ücret (₺)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.money),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() =>
                                    _price = double.tryParse(value) ?? 0.0);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Öncelik
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Öncelik',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: 'normal', child: Text('Normal')),
                          const DropdownMenuItem(
                              value: 'medium', child: Text('Orta')),
                          const DropdownMenuItem(
                              value: 'high', child: Text('Yüksek')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPriority = value!);
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingMedium),

                      // Notlar
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notlar',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(isEditing ? 'Güncelle' : 'Kaydet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hasta seçimi gerekli'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Kullanıcı oturumu bulunamadı';

      final patient =
          widget.patients.firstWhere((p) => p.id == _selectedPatientId);
      final service = _selectedServiceId != null
          ? widget.services.firstWhere((s) => s.id == _selectedServiceId,
              orElse: () => ClinicService(
                  id: '',
                  userId: '',
                  name: 'Özel Hizmet',
                  price: _price,
                  duration: _duration,
                  isActive: true,
                  createdAt: DateTime.now()))
          : ClinicService(
              id: '',
              userId: '',
              name: 'Özel Hizmet',
              price: _price,
              duration: _duration,
              isActive: true,
              createdAt: DateTime.now());

      final appointmentDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointmentData = ClinicAppointment(
        id: isEditing
            ? widget.appointment!.id
            : FirebaseFirestore.instance.collection('temp').doc().id,
        userId: user.uid,
        patientId: patient.id,
        patientName: patient.name,
        serviceId: service.id.isEmpty ? null : service.id,
        serviceName: service.name,
        appointmentDate: appointmentDate,
        duration: _duration,
        price: _price,
        status: isEditing ? widget.appointment!.status : 'pending',
        priority: _selectedPriority,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: isEditing ? widget.appointment!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicAppointmentsCollection)
            .doc(widget.appointment!.id)
            .update(appointmentData.toMap());
      } else {
        await FirebaseFirestore.instance
            .collection(AppConstants.clinicAppointmentsCollection)
            .doc(appointmentData.id)
            .set(appointmentData.toMap());
      }

      Navigator.pop(context);
      widget.onSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Randevu başarıyla güncellendi'
              : 'Randevu başarıyla eklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
