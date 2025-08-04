import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/calendar_event_model.dart';
import '../../services/unified_calendar_service.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Tüm modüller için birleşik takvim sayfası
class UnifiedCalendarPage extends StatefulWidget {
  /// Sadece belirli modülleri göstermek için
  final List<String>? allowedModules;
  
  /// Sayfa başlığı
  final String? title;
  
  /// Başlangıç tarih aralığı
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const UnifiedCalendarPage({
    super.key,
    this.allowedModules,
    this.title,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<UnifiedCalendarPage> createState() => _UnifiedCalendarPageState();
}

class _UnifiedCalendarPageState extends State<UnifiedCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  List<String> _selectedModules = [];
  List<String> _selectedEventTypes = [];
  bool _isLoading = true;
  
  // Mevcut modüller
  final List<String> _allModules = [
    'beauty',
    'psychology', 
    'lawyer',
    'veterinary',
    'real_estate',
    'sports',
    'education',
    'clinic',
    'custom',
  ];

  // Mevcut etkinlik türleri
  final List<String> _allEventTypes = [
    'appointment',
    'session',
    'case',
    'court_date',
    'hearing',
    'treatment',
    'vaccination',
    'exam',
    'note',
    'reminder',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
    // İzin verilen modülleri ayarla
    if (widget.allowedModules != null) {
      _selectedModules = widget.allowedModules!.toList();
    } else {
      _selectedModules = _allModules.toList();
    }
    
    // Tüm etkinlik türlerini seç
    _selectedEventTypes = _allEventTypes.toList();
    
    _loadCalendarEvents();
  }

  Future<void> _loadCalendarEvents() async {
    setState(() => _isLoading = true);

    try {
      // Tarih aralığını hesapla
      final startDate = widget.initialStartDate ?? 
          DateTime.now().subtract(const Duration(days: 90));
      final endDate = widget.initialEndDate ?? 
          DateTime.now().add(const Duration(days: 180));

      // Stream'i dinle
      UnifiedCalendarService.getCalendarEvents(
        startDate: startDate,
        endDate: endDate,
        modules: _selectedModules.isEmpty ? null : _selectedModules,
        eventTypes: _selectedEventTypes.isEmpty ? null : _selectedEventTypes,
      ).listen((events) {
        if (mounted) {
          setState(() {
            _events = _groupEventsByDate(events);
            _isLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Takvim verileri yüklenirken hata: $error'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Etkinlikleri tarihlere göre grupla
  Map<DateTime, List<CalendarEvent>> _groupEventsByDate(List<CalendarEvent> events) {
    final Map<DateTime, List<CalendarEvent>> groupedEvents = {};
    
    for (final event in events) {
      final normalizedDate = DateTime(event.date.year, event.date.month, event.date.day);
      (groupedEvents[normalizedDate] ??= []).add(event);
    }
    
    // Her tarihteki etkinlikleri saate göre sırala
    for (final dateEvents in groupedEvents.values) {
      dateEvents.sort((a, b) {
        if (a.time.isNotEmpty && b.time.isNotEmpty) {
          return a.time.compareTo(b.time);
        }
        return a.date.compareTo(b.date);
      });
    }
    
    return groupedEvents;
  }

  /// Belirli gün için etkinlikleri getir
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  /// Modül filtresi değiştirildiğinde
  void _onModuleFilterChanged() {
    _loadCalendarEvents();
  }

  /// Etkinlik türü filtresi değiştirildiğinde
  void _onEventTypeFilterChanged() {
    _loadCalendarEvents();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? localizations.calendar),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Filtre butonu
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Bugün butonu
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Takvim widget'ı
                CommonCard(
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    locale: locale.languageCode,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
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
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markersMaxCount: 3,
                      markerDecoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppConstants.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        
                        return Positioned(
                          right: 1,
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(3).map((event) {
                              return Container(
                                margin: const EdgeInsets.only(left: 1),
                                height: 6,
                                width: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: event.color,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                // Seçilen günün etkinlikleri
                Expanded(
                  child: _buildEventsList(localizations),
                ),
              ],
            ),
    );
  }

  /// Etkinlikler listesi
  Widget _buildEventsList(AppLocalizations localizations) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? DateTime.now());
    
    if (selectedEvents.isEmpty) {
      return CommonCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note,
                size: 64,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Bu tarih için etkinlik bulunamadı',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              '${DateFormat.yMMMMd(context.watch<LocaleProvider>().locale.languageCode).format(_selectedDay ?? DateTime.now())} - ${selectedEvents.length} etkinlik',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          
          // Etkinlikler listesi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              itemCount: selectedEvents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return _buildEventTile(event, localizations);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tek etkinlik tile'ı
  Widget _buildEventTile(CalendarEvent event, AppLocalizations localizations) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 4,
        height: 50,
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        event.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zaman ve modül bilgisi
          Row(
            children: [
              if (event.time.isNotEmpty) ...[
                Icon(Icons.access_time, size: 14, color: AppConstants.textSecondary),
                const SizedBox(width: 4),
                Text(
                  event.time,
                  style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: event.color.withOpacity(0.3)),
                ),
                child: Text(
                  UnifiedCalendarService.getModuleName(event.sourceModule, localizations),
                  style: TextStyle(
                    color: event.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          // Müşteri ve personel bilgisi
          if (event.customerName.isNotEmpty || event.employeeName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (event.customerName.isNotEmpty) ...[
                  Icon(Icons.person, size: 14, color: AppConstants.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    event.customerName,
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                  ),
                ],
                if (event.customerName.isNotEmpty && event.employeeName.isNotEmpty)
                  const SizedBox(width: 12),
                if (event.employeeName.isNotEmpty) ...[
                  Icon(Icons.work, size: 14, color: AppConstants.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    event.employeeName,
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
          
          // Açıklama
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description,
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: event.amount > 0
          ? Text(
              '₺${event.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.successColor,
              ),
            )
          : null,
    );
  }

  /// Filtre dialog'unu göster
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtreler'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modül filtreleri
              const Text(
                'Modüller',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: _allModules.where((module) {
                  // İzin verilen modülleri kontrol et
                  return widget.allowedModules?.contains(module) ?? true;
                }).map((module) {
                  final isSelected = _selectedModules.contains(module);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: FilterChip(
                      label: Text(
                        UnifiedCalendarService.getModuleName(
                          module, 
                          AppLocalizations.of(context)!,
                        ),
                      ),
                      selected: isSelected,
                      backgroundColor: UnifiedCalendarService.getModuleColor(module).withOpacity(0.1),
                      selectedColor: UnifiedCalendarService.getModuleColor(module).withOpacity(0.3),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedModules.add(module);
                          } else {
                            _selectedModules.remove(module);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onModuleFilterChanged();
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }
}