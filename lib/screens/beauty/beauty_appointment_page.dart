import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/modern_forms.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyAppointmentPage extends StatefulWidget {
  const BeautyAppointmentPage({super.key});

  @override
  State<BeautyAppointmentPage> createState() => _BeautyAppointmentPageState();
}

class _BeautyAppointmentPageState extends State<BeautyAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedStatusFilter;
  DateTime? _selectedDateFilter;
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final query = FirebaseFirestore.instance
          .collection('appointments')
          .where('userId', isEqualTo: user.uid);

      final snapshot = await query.get();

      setState(() {
        _appointments = snapshot.docs
            .map((doc) =>
                AppointmentModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
        _appointments.sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar('${l10n.appointmentsLoadError}: $e', isError: true);
      }
    }
  }

  List<AppointmentModel> _getFilteredAppointments(
      AppLocalizations localizations) {
    return _appointments.where((appointment) {
      // Metin arama
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final customerName = appointment.customerName?.toLowerCase() ?? '';
        final serviceName = appointment.serviceName?.toLowerCase() ?? '';
        if (!customerName.contains(query) && !serviceName.contains(query)) {
          return false;
        }
      }

      // Durum filtresi
      if (_selectedStatusFilter != null) {
        final statusMap = {
          localizations.pending: AppointmentStatus.pending,
          localizations.scheduled: AppointmentStatus.planned,
          localizations.confirmed: AppointmentStatus.confirmed,
          localizations.inProgress: AppointmentStatus.inProgress,
          localizations.completed: AppointmentStatus.completed,
          localizations.cancelled: AppointmentStatus.cancelled,
          localizations.noShow: AppointmentStatus.noShow,
        };
        if (appointment.status != statusMap[_selectedStatusFilter]) {
          return false;
        }
      }

      // Tarih filtresi
      if (_selectedDateFilter != null) {
        final appointmentDate = DateTime(
          appointment.date.year,
          appointment.date.month,
          appointment.date.day,
        );
        final filterDate = DateTime(
          _selectedDateFilter!.year,
          _selectedDateFilter!.month,
          _selectedDateFilter!.day,
        );
        if (!appointmentDate.isAtSameMomentAs(filterDate)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // İlk kez çalıştırıldığında varsayılan değeri set et
    _selectedStatusFilter ??= localizations.all;

    // Dinamik status filtreleri
    final List<String> _statusFilters = [
      localizations.all,
      localizations.pending,
      localizations.scheduled,
      localizations.confirmed,
      localizations.inProgress,
      localizations.completed,
      localizations.cancelled,
      localizations.noShow,
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.appointments,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.pushNamed(context, '/beauty-calendar'),
            tooltip: localizations.calendarView,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadAppointments,
            tooltip: localizations.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // İstatistik Kartları
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: localizations.total,
                    value: _appointments.length.toString(),
                    icon: Icons.event_outlined,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _StatCard(
                    title: localizations.today,
                    value: _getTodayAppointmentCount().toString(),
                    icon: Icons.today_outlined,
                    color: AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: _StatCard(
                    title: localizations.pending,
                    value: _getPendingAppointmentCount().toString(),
                    icon: Icons.access_time_outlined,
                    color: AppConstants.warningColor,
                  ),
                ),
              ],
            ),
          ),

          // Arama ve Filtreler
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Arama Çubuğu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        "${localizations.customerName} ${localizations.search.toLowerCase()}...",
                    prefixIcon: const Icon(Icons.search_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppConstants.primaryColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Filtreler
                Row(
                  children: [
                    // Durum Filtresi
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilters.contains(_selectedStatusFilter)
                            ? _selectedStatusFilter
                            : _statusFilters.first,
                        decoration: InputDecoration(
                          labelText: localizations.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _statusFilters.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: AppConstants.paddingMedium),

                    // Tarih Filtresi
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDateFilter(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDateFilter != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_selectedDateFilter!)
                                      : 'Tarih Seç',
                                  style: TextStyle(
                                    color: _selectedDateFilter != null
                                        ? AppConstants.textPrimary
                                        : AppConstants.textSecondary,
                                  ),
                                ),
                              ),
                              if (_selectedDateFilter != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDateFilter = null;
                                    });
                                  },
                                  child: const Icon(Icons.clear, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Randevu Tablosu
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                : _getFilteredAppointments(localizations).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy_outlined,
                              size: 64,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              localizations.noDataAvailable,
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          margin:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DataTable(
                            columnSpacing: 24,
                            horizontalMargin: 16,
                            headingRowColor: WidgetStateProperty.all(
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                            ),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                            dataTextStyle: const TextStyle(
                              color: AppConstants.textPrimary,
                            ),
                            columns: [
                              DataColumn(label: Text(localizations.customer)),
                              DataColumn(label: Text(localizations.service)),
                              DataColumn(label: Text(localizations.date)),
                              DataColumn(label: Text(localizations.time)),
                              DataColumn(label: Text(localizations.duration)),
                              DataColumn(label: Text(localizations.price)),
                              DataColumn(label: Text(localizations.status)),
                              DataColumn(label: Text(localizations.actions)),
                            ],
                            rows: _getFilteredAppointments(localizations)
                                .map((appointment) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      appointment.customerName ??
                                          localizations.unknown,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  DataCell(
                                    Text(appointment.serviceName ??
                                        localizations.unknown),
                                  ),
                                  DataCell(
                                    Text(DateFormat('dd/MM/yyyy')
                                        .format(appointment.date)),
                                  ),
                                  DataCell(
                                    Text(
                                        '${appointment.time.hour.toString().padLeft(2, '0')}:${appointment.time.minute.toString().padLeft(2, '0')}'),
                                  ),
                                  DataCell(
                                    Text('60 dk'), // Default duration
                                  ),
                                  DataCell(
                                    Text(
                                        '₺${appointment.price?.toStringAsFixed(2) ?? '0.00'}'),
                                  ),
                                  DataCell(
                                    _buildStatusBadge(
                                        appointment.status, localizations),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18),
                                          onPressed: () =>
                                              _editAppointment(appointment),
                                          tooltip: AppLocalizations.of(context)!
                                              .edit,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 18),
                                          onPressed: () =>
                                              _deleteAppointment(appointment),
                                          tooltip: AppLocalizations.of(context)!
                                              .delete,
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert,
                                              size: 18),
                                          onSelected: (value) =>
                                              _handleMenuAction(
                                                  value, appointment),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'confirm',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Onayla'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'complete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.done_all,
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('Tamamla'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'cancel',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.cancel_outlined,
                                                      size: 16),
                                                  const SizedBox(width: 8),
                                                  Text('İptal Et'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewAppointment(),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(localizations.newAppointment),
      ),
    );
  }

  int _getTodayAppointmentCount() {
    final today = DateTime.now();
    return _appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.date.year,
        appointment.date.month,
        appointment.date.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return appointmentDate.isAtSameMomentAs(todayDate);
    }).length;
  }

  int _getPendingAppointmentCount() {
    return _appointments
        .where((appointment) => appointment.status == AppointmentStatus.pending)
        .length;
  }

  int _getCompletedAppointmentCount() {
    return _appointments
        .where(
            (appointment) => appointment.status == AppointmentStatus.completed)
        .length;
  }

  Future<void> _selectDateFilter() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _selectedDateFilter = date;
      });
    }
  }

  void _addNewAppointment() {
    showDialog(
      context: context,
      builder: (context) => BeautyAppointmentForm(
        onSaved: () {
          _loadAppointments();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => BeautyAppointmentForm(
        appointmentId: appointment.id,
        onSaved: () {
          _loadAppointments();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteAppointmentTitle),
        content: Text(
            '${appointment.customerName} ${localizations.deleteAppointmentConfirm}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appointmentService.deleteAppointment(appointment.id);
        _showSnackBar(localizations.appointmentDeletedSuccess);
        _loadAppointments();
      } catch (e) {
        _showSnackBar('${localizations.appointmentDeleteError}: $e',
            isError: true);
      }
    }
  }

  Future<void> _handleMenuAction(
      String action, AppointmentModel appointment) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      AppointmentStatus newStatus;
      String message;

      switch (action) {
        case 'confirm':
          newStatus = AppointmentStatus.confirmed;
          message = localizations.appointmentConfirmed;
          break;
        case 'complete':
          newStatus = AppointmentStatus.completed;
          message = localizations.appointmentCompleted;
          break;
        case 'cancel':
          newStatus = AppointmentStatus.cancelled;
          message = localizations.appointmentCancelled;
          break;
        default:
          return;
      }

      final updatedAppointment = appointment.copyWith(status: newStatus);
      await _appointmentService.updateAppointment(updatedAppointment);
      _showSnackBar(message);
      _loadAppointments();
    } catch (e) {
      _showSnackBar('${localizations.operationError}: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppConstants.errorColor : AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      AppointmentStatus status, AppLocalizations localizations) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        color = AppConstants.warningColor;
        text = localizations.pending;
        break;
      case AppointmentStatus.planned:
        color = AppConstants.primaryColor;
        text = localizations.scheduled;
        break;
      case AppointmentStatus.confirmed:
        color = AppConstants.primaryColor;
        text = localizations.confirmed;
        break;
      case AppointmentStatus.inProgress:
        color = AppConstants.warningColor;
        text = localizations.inProgress;
        break;
      case AppointmentStatus.completed:
        color = AppConstants.successColor;
        text = localizations.completed;
        break;
      case AppointmentStatus.cancelled:
        color = AppConstants.errorColor;
        text = localizations.cancelled;
        break;
      case AppointmentStatus.noShow:
        color = AppConstants.textSecondary;
        text = localizations.noShow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        color = AppConstants.warningColor;
        text = 'Beklemede';
        break;
      case AppointmentStatus.planned:
        color = AppConstants.primaryColor;
        text = 'Planlandı';
        break;
      case AppointmentStatus.confirmed:
        color = AppConstants.primaryColor;
        text = 'Onaylandı';
        break;
      case AppointmentStatus.inProgress:
        color = AppConstants.warningColor;
        text = 'Devam Ediyor';
        break;
      case AppointmentStatus.completed:
        color = AppConstants.successColor;
        text = 'Tamamlandı';
        break;
      case AppointmentStatus.cancelled:
        color = AppConstants.errorColor;
        text = 'İptal Edildi';
        break;
      case AppointmentStatus.noShow:
        color = AppConstants.textSecondary;
        text = 'Gelmedi';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
