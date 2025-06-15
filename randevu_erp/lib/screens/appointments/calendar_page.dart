import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/customer_model.dart';
import '../../services/appointment_service.dart';
import '../../services/customer_service.dart';
import 'add_edit_appointment_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final CustomerService _customerService = CustomerService();
  
  late final ValueNotifier<List<AppointmentModel>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<AppointmentModel>> _events = {};
  Map<String, CustomerModel> _customers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAppointments(),
      _loadCustomers(),
    ]);
    
    setState(() {
      _isLoading = false;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  Future<void> _loadAppointments() async {
    try {
      // Geçen ay, bu ay ve gelecek ay randevularını yükle
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 1, 1);
      final endDate = DateTime(now.year, now.month + 2, 0);
      
      final appointments = await _appointmentService.getAppointmentsByDateRange(
        startDate, 
        endDate
      );

      final events = <DateTime, List<AppointmentModel>>{};
      
      for (final appointment in appointments) {
        final date = DateTime(
          appointment.tarih.year,
          appointment.tarih.month,
          appointment.tarih.day,
        );
        
        if (events[date] != null) {
          events[date]!.add(appointment);
        } else {
          events[date] = [appointment];
        }
      }
      
      // Saate göre sırala
      events.forEach((date, appointmentList) {
        appointmentList.sort((a, b) => a.tamTarih.compareTo(b.tamTarih));
      });

      setState(() {
        _events = events;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevular yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _customerService.getCustomers();
      final customerMap = <String, CustomerModel>{};
      
      for (final customer in customers) {
        customerMap[customer.id] = customer;
      }
      
      setState(() {
        _customers = customerMap;
      });
    } catch (e) {
      print('Müşteriler yüklenirken hata: $e');
    }
  }

  List<AppointmentModel> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _navigateToAddAppointment([DateTime? selectedDate]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAppointmentPage(
          initialDate: selectedDate ?? _selectedDay,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _navigateToEditAppointment(AppointmentModel appointment) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAppointmentPage(
          appointment: appointment,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevuyu Sil'),
        content: Text('${appointment.islemAdi} randevusunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appointmentService.deleteAppointment(appointment.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${appointment.islemAdi} randevusu silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Takvimi'),
        actions: [
          IconButton(
            onPressed: () => _loadData(),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<CalendarFormat>(
            icon: const Icon(Icons.view_module),
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Aylık Görünüm'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 Haftalık Görünüm'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Haftalık Görünüm'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Takvim
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: TableCalendar<AppointmentModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    locale: 'tr_TR',
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                      holidayTextStyle: TextStyle(color: Colors.red[800]),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(Icons.chevron_left),
                      rightChevronIcon: Icon(Icons.chevron_right),
                    ),
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),

                // Seçili günün randevuları
                Expanded(
                  child: ValueListenableBuilder<List<AppointmentModel>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      return Column(
                        children: [
                          // Başlık
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDay != null
                                      ? DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(_selectedDay!)
                                      : '',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${value.length} Randevu',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Randevu listesi
                          Expanded(
                            child: value.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: value.length,
                                    itemBuilder: (context, index) {
                                      final appointment = value[index];
                                      final customer = _customers[appointment.musteriId];
                                      
                                      return AppointmentCard(
                                        appointment: appointment,
                                        customer: customer,
                                        onTap: () => _navigateToEditAppointment(appointment),
                                        onDelete: () => _deleteAppointment(appointment),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAppointment(_selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bu gün için randevu yok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni randevu eklemek için + butonuna basın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddAppointment(_selectedDay),
            icon: const Icon(Icons.add),
            label: const Text('Randevu Ekle'),
          ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final CustomerModel? customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.customer,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Saat göstergesi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: appointment.durumRengi.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appointment.durumRengi.withOpacity(0.3)),
                ),
                child: Text(
                  appointment.formatliSaat,
                  style: TextStyle(
                    color: appointment.durumRengi,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Randevu bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.islemAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer!.tamAd,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (appointment.not != null && appointment.not!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment.not!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Durum ve işlemler
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: appointment.durumRengi.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.durum,
                      style: TextStyle(
                        color: appointment.durumRengi,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onTap();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Düzenle'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Sil', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
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
} 