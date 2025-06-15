import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/customer_model.dart';
import '../../services/appointment_service.dart';
import '../../services/customer_service.dart';

class AddEditAppointmentPage extends StatefulWidget {
  final AppointmentModel? appointment;
  final DateTime? initialDate;

  const AddEditAppointmentPage({
    Key? key,
    this.appointment,
    this.initialDate,
  }) : super(key: key);

  @override
  State<AddEditAppointmentPage> createState() => _AddEditAppointmentPageState();
}

class _AddEditAppointmentPageState extends State<AddEditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentService _appointmentService = AppointmentService();
  final CustomerService _customerService = CustomerService();

  late final TextEditingController _islemController;
  late final TextEditingController _notController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  CustomerModel? _selectedCustomer;
  List<CustomerModel> _customers = [];
  List<AppointmentModel> _conflictingAppointments = [];
  
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  bool get _isEditing => widget.appointment != null;

  // Önceden tanımlı işlem türleri
  final List<String> _predefinedServices = [
    'Saç Kesimi',
    'Saç Boyama',
    'Saç Yıkama',
    'Föhn',
    'Ombre',
    'Balayaj',
    'Perma',
    'Düzleştirme',
    'Makyaj',
    'Kaş Alma',
    'Cilt Bakımı',
    'Masaj',
    'Manikür',
    'Pedikür',
  ];

  @override
  void initState() {
    super.initState();
    
    final appointment = widget.appointment;
    _islemController = TextEditingController(text: appointment?.islemAdi ?? '');
    _notController = TextEditingController(text: appointment?.not ?? '');
    
    if (appointment != null) {
      _selectedDate = appointment.tarih;
      _selectedTime = appointment.timeOfDay;
    } else if (widget.initialDate != null) {
      _selectedDate = widget.initialDate;
    }
    
    _loadCustomers();
  }

  @override
  void dispose() {
    _islemController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerService.getCustomers();
      setState(() {
        _customers = customers;
        _isLoadingCustomers = false;
      });

      // Düzenleme modunda müşteriyi seç
      if (_isEditing && widget.appointment != null) {
        final customerId = widget.appointment!.musteriId;
        final customer = customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => customers.isNotEmpty ? customers.first : CustomerModel(
            id: '',
            ad: '',
            soyad: '',
            telefon: '',
            olusturulmaTarihi: DateTime.now(),
            ekleyenKullaniciId: '',
          ),
        );
        
        if (customer.id.isNotEmpty) {
          setState(() {
            _selectedCustomer = customer;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCustomers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Müşteriler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkConflicts() async {
    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _conflictingAppointments = [];
      });
      return;
    }

    try {
      final timeString = AppointmentModel.timeOfDayToString(_selectedTime!);
      final conflicts = await _appointmentService.getConflictingAppointments(
        _selectedDate!,
        timeString,
        excludeAppointmentId: _isEditing ? widget.appointment!.id : null,
      );
      
      setState(() {
        _conflictingAppointments = conflicts;
      });
    } catch (e) {
      print('Çakışma kontrolü hatası: $e');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _checkConflicts();
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      _checkConflicts();
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tarih seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen saat seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen müşteri seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Çakışma kontrolü
    if (_conflictingAppointments.isNotEmpty) {
      final confirmed = await _showConflictDialog();
      if (!confirmed) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timeString = AppointmentModel.timeOfDayToString(_selectedTime!);

      if (_isEditing) {
        // Güncelleme
        final updatedAppointment = widget.appointment!.copyWith(
          musteriId: _selectedCustomer!.id,
          tarih: _selectedDate!,
          saat: timeString,
          islemAdi: _islemController.text.trim(),
          not: _notController.text.trim().isEmpty ? null : _notController.text.trim(),
        );

        await _appointmentService.updateAppointment(updatedAppointment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Yeni ekleme
        await _appointmentService.addAppointment(
          musteriId: _selectedCustomer!.id,
          tarih: _selectedDate!,
          saat: timeString,
          islemAdi: _islemController.text.trim(),
          not: _notController.text.trim().isEmpty ? null : _notController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu eklendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConflictDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Çakışan Randevu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seçilen saatte çakışan randevular var:'),
            const SizedBox(height: 8),
            ...(_conflictingAppointments.map((appointment) {
              final customer = _customers.firstWhere(
                (c) => c.id == appointment.musteriId,
                orElse: () => CustomerModel(
                  id: '',
                  ad: 'Bilinmeyen',
                  soyad: 'Müşteri',
                  telefon: '',
                  olusturulmaTarihi: DateTime.now(),
                  ekleyenKullaniciId: '',
                ),
              );
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${appointment.formatliSaat} - ${appointment.islemAdi} (${customer.tamAd})',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            })),
            const SizedBox(height: 8),
            const Text('Yine de kaydetmek istiyor musunuz?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Randevu Düzenle' : 'Yeni Randevu'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAppointment,
            child: Text(
              _isEditing ? 'Güncelle' : 'Kaydet',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingCustomers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tarih ve Saat Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarih ve Saat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tarih seçimi
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Tarih'),
                            subtitle: Text(
                              _selectedDate != null
                                  ? DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_selectedDate!)
                                  : 'Tarih seçin',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _selectDate,
                          ),
                          const Divider(),

                          // Saat seçimi
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('Saat'),
                            subtitle: Text(
                              _selectedTime != null
                                  ? AppointmentModel.timeOfDayToString(_selectedTime!)
                                  : 'Saat seçin',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _selectTime,
                          ),

                          // Çakışma uyarısı
                          if (_conflictingAppointments.isNotEmpty) ...[
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[600], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_conflictingAppointments.length} çakışan randevu var',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Müşteri Seçimi Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Müşteri Seçimi',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<CustomerModel>(
                            value: _selectedCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Müşteri *',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            items: _customers.map((customer) {
                              return DropdownMenuItem(
                                value: customer,
                                child: Text('${customer.tamAd} (${customer.formatliTelefon})'),
                              );
                            }).toList(),
                            onChanged: (customer) {
                              setState(() {
                                _selectedCustomer = customer;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Müşteri seçimi gereklidir';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // İşlem Bilgileri Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İşlem Bilgileri',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // İşlem adı
                          TextFormField(
                            controller: _islemController,
                            decoration: InputDecoration(
                              labelText: 'İşlem Adı *',
                              prefixIcon: const Icon(Icons.content_cut),
                              border: const OutlineInputBorder(),
                              suffixIcon: PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (value) {
                                  _islemController.text = value;
                                },
                                itemBuilder: (context) => _predefinedServices
                                    .map((service) => PopupMenuItem(
                                          value: service,
                                          child: Text(service),
                                        ))
                                    .toList(),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'İşlem adı gereklidir';
                              }
                              if (value.trim().length < 2) {
                                return 'İşlem adı en az 2 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Not alanı
                          TextFormField(
                            controller: _notController,
                            decoration: const InputDecoration(
                              labelText: 'Not',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                              hintText: 'Randevu ile ilgili notlar...',
                            ),
                            maxLines: 3,
                            maxLength: 300,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kaydet/Güncelle Butonu
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAppointment,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Randevuyu Güncelle' : 'Randevu Oluştur',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bilgi notu
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '* işaretli alanlar zorunludur',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 