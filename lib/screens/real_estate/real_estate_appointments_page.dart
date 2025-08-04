import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/real_estate_appointment_model.dart';

// TODO: Bu sayfaya Firebase entegrasyonu, randevu CRUD işlemleri eklenecek
class RealEstateAppointmentsPage extends StatefulWidget {
  const RealEstateAppointmentsPage({super.key});

  @override
  State<RealEstateAppointmentsPage> createState() =>
      _RealEstateAppointmentsPageState();
}

class _RealEstateAppointmentsPageState
    extends State<RealEstateAppointmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  String _selectedTypeFilter = 'all';
  bool _isLoading = false;

  // TODO: Firebase servis entegrasyonu eklenecek
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _buildAppointmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Randevu Yönetimi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mülk gösterimleri ve müşteri randevularınızı yönetin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddAppointmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Randevu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Müşteri adı, mülk adı ile ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // TODO: Arama fonksiyonu eklenecek
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusFilter(),
              const SizedBox(width: 12),
              _buildTypeFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getStatusFilterLabel(_selectedStatusFilter)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('Tüm Durumlar')),
        const PopupMenuItem(value: 'planned', child: Text('Planlandı')),
        const PopupMenuItem(value: 'completed', child: Text('Tamamlandı')),
        const PopupMenuItem(value: 'cancelled', child: Text('İptal Edildi')),
        const PopupMenuItem(value: 'rescheduled', child: Text('Ertelendi')),
      ],
      onSelected: (value) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
    );
  }

  Widget _buildTypeFilter() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getTypeFilterLabel(_selectedTypeFilter)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('Tüm Tipler')),
        const PopupMenuItem(value: 'viewing', child: Text('Mülk Gösterimi')),
        const PopupMenuItem(
            value: 'meeting', child: Text('Müşteri Toplantısı')),
        const PopupMenuItem(value: 'consultation', child: Text('Danışmanlık')),
        const PopupMenuItem(value: 'valuation', child: Text('Değerleme')),
      ],
      onSelected: (value) {
        setState(() {
          _selectedTypeFilter = value;
        });
      },
    );
  }

  Widget _buildAppointmentsList() {
    if (currentUserId == null) {
      return const Center(
        child: Text('Giriş yapmanız gerekiyor'),
      );
    }

    // TODO: Firebase Stream veya FutureBuilder ile gerçek veri çekilecek
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9333EA),
            ),
          );
        }

        final appointments = snapshot.data?.docs
                .map((doc) => RealEstateAppointment.fromMap({
                      ...doc.data() as Map<String, dynamic>,
                      'id': doc.id,
                    }))
                .where(_filterAppointment)
                .toList() ??
            [];

        if (appointments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(appointments[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection(AppConstants.realEstateAppointmentsCollection)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('appointmentDate', descending: false)
        .snapshots();
  }

  bool _filterAppointment(RealEstateAppointment appointment) {
    // Durum filtresi
    if (_selectedStatusFilter != 'all' &&
        appointment.status.toString().split('.').last !=
            _selectedStatusFilter) {
      return false;
    }

    // Tip filtresi
    if (_selectedTypeFilter != 'all' &&
        appointment.type.toString().split('.').last != _selectedTypeFilter) {
      return false;
    }

    // Arama filtresi
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      return appointment.customerName.toLowerCase().contains(searchTerm) ||
          appointment.propertyName.toLowerCase().contains(searchTerm) ||
          appointment.propertyAddress.toLowerCase().contains(searchTerm);
    }

    return true;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.schedule,
              size: 48,
              color: Color(0xFF9333EA),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz randevu yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk randevunuzu oluşturarak müşteri takibine başlayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAppointmentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Randevuyu Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(RealEstateAppointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appointment.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  appointment.statusIcon,
                  color: appointment.statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      appointment.typeDisplayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: appointment.statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  appointment.statusDisplayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(
                      value: 'complete', child: Text('Tamamlandı İşaretle')),
                  const PopupMenuItem(value: 'cancel', child: Text('İptal Et')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
                onSelected: (value) =>
                    _handleAppointmentAction(value, appointment),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  appointment.propertyName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.home,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  appointment.propertyAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                appointment.formattedDateTime,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.phone,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                appointment.customerPhone,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AppointmentDialog(
        onSaved: _addAppointment,
      ),
    );
  }

  void _showEditAppointmentDialog(RealEstateAppointment appointment) {
    showDialog(
      context: context,
      builder: (context) => _AppointmentDialog(
        appointment: appointment,
        onSaved: _updateAppointment,
      ),
    );
  }

  void _handleAppointmentAction(
      String action, RealEstateAppointment appointment) {
    switch (action) {
      case 'edit':
        _showEditAppointmentDialog(appointment);
        break;
      case 'complete':
        _updateAppointmentStatus(appointment, AppointmentStatus.completed);
        break;
      case 'cancel':
        _updateAppointmentStatus(appointment, AppointmentStatus.cancelled);
        break;
      case 'delete':
        _deleteAppointment(appointment);
        break;
    }
  }

  // TODO: Firebase CRUD işlemleri tamamlanacak
  Future<void> _addAppointment(RealEstateAppointment appointment) async {
    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection(AppConstants.realEstateAppointmentsCollection)
          .add(appointment.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla eklendi'),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAppointment(RealEstateAppointment appointment) async {
    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection(AppConstants.realEstateAppointmentsCollection)
          .doc(appointment.id)
          .update(appointment.copyWith(updatedAt: DateTime.now()).toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAppointmentStatus(
      RealEstateAppointment appointment, AppointmentStatus status) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.realEstateAppointmentsCollection)
          .doc(appointment.id)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Randevu durumu güncellendi: ${_getStatusDisplayName(status)}'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _deleteAppointment(RealEstateAppointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevuyu Sil'),
        content: Text(
            '${appointment.customerName} ile olan randevuyu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.realEstateAppointmentsCollection)
            .doc(appointment.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
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
      }
    }
  }

  String _getStatusFilterLabel(String status) {
    switch (status) {
      case 'all':
        return 'Tüm Durumlar';
      case 'planned':
        return 'Planlandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'rescheduled':
        return 'Ertelendi';
      default:
        return 'Tüm Durumlar';
    }
  }

  String _getTypeFilterLabel(String type) {
    switch (type) {
      case 'all':
        return 'Tüm Tipler';
      case 'viewing':
        return 'Mülk Gösterimi';
      case 'meeting':
        return 'Müşteri Toplantısı';
      case 'consultation':
        return 'Danışmanlık';
      case 'valuation':
        return 'Değerleme';
      default:
        return 'Tüm Tipler';
    }
  }

  String _getStatusDisplayName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.planned:
        return 'Planlandı';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.rescheduled:
        return 'Ertelendi';
    }
  }
}

// TODO: Form validasyonları ve veri doğrulama eklenecek
class _AppointmentDialog extends StatefulWidget {
  final RealEstateAppointment? appointment;
  final Function(RealEstateAppointment) onSaved;

  const _AppointmentDialog({
    this.appointment,
    required this.onSaved,
  });

  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _propertyNameController = TextEditingController();
  final _propertyAddressController = TextEditingController();
  final _notesController = TextEditingController();

  AppointmentType _selectedType = AppointmentType.viewing;
  AppointmentStatus _selectedStatus = AppointmentStatus.planned;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _loadAppointmentData();
    }
  }

  void _loadAppointmentData() {
    final appointment = widget.appointment!;
    _customerNameController.text = appointment.customerName;
    _customerPhoneController.text = appointment.customerPhone;
    _customerEmailController.text = appointment.customerEmail;
    _propertyNameController.text = appointment.propertyName;
    _propertyAddressController.text = appointment.propertyAddress;
    _notesController.text = appointment.notes ?? '';
    _selectedType = appointment.type;
    _selectedStatus = appointment.status;
    _selectedDate = appointment.appointmentDate;
    _selectedTime = TimeOfDay.fromDateTime(appointment.appointmentDate);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _propertyNameController.dispose();
    _propertyAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: _buildForm(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9333EA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.schedule,
            color: Color(0xFF9333EA),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.appointment == null ? 'Yeni Randevu' : 'Randevuyu Düzenle',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildSection('Müşteri Bilgileri', [
          TextFormField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Müşteri Adı',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Müşteri adı gerekli';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Telefon gerekli';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _customerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('Mülk Bilgileri', [
          TextFormField(
            controller: _propertyNameController,
            decoration: const InputDecoration(
              labelText: 'Mülk Adı',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Mülk adı gerekli';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _propertyAddressController,
            decoration: const InputDecoration(
              labelText: 'Adres',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Adres gerekli';
              return null;
            },
          ),
        ]),
        const SizedBox(height: 24),
        _buildSection('Randevu Detayları', [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AppointmentType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Randevu Tipi',
                    border: OutlineInputBorder(),
                  ),
                  items: AppointmentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<AppointmentStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    border: OutlineInputBorder(),
                  ),
                  items: AppointmentStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusDisplayName(status)),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStatus = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker()),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker()),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notlar (İsteğe bağlı)',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tarih',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Saat',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saveAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9333EA),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.appointment == null ? 'Ekle' : 'Güncelle'),
        ),
      ],
    );
  }

  void _saveAppointment() {
    if (!_formKey.currentState!.validate()) return;

    final appointmentDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = RealEstateAppointment(
      id: widget.appointment?.id ?? '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      propertyName: _propertyNameController.text,
      propertyAddress: _propertyAddressController.text,
      propertyId: '', // TODO: Mülk seçimi eklenecek
      appointmentDate: appointmentDate,
      type: _selectedType,
      status: _selectedStatus,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      updatedAt: widget.appointment != null ? DateTime.now() : null,
    );

    widget.onSaved(appointment);
    Navigator.pop(context);
  }

  String _getTypeDisplayName(AppointmentType type) {
    switch (type) {
      case AppointmentType.viewing:
        return 'Mülk Gösterimi';
      case AppointmentType.meeting:
        return 'Müşteri Toplantısı';
      case AppointmentType.consultation:
        return 'Danışmanlık';
      case AppointmentType.valuation:
        return 'Değerleme';
    }
  }

  String _getStatusDisplayName(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.planned:
        return 'Planlandı';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'İptal Edildi';
      case AppointmentStatus.rescheduled:
        return 'Ertelendi';
    }
  }
}
