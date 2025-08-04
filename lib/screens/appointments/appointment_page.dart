import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import 'add_edit_appointment_page.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final TextEditingController _searchController = TextEditingController();
  final AppointmentService _appointmentService = AppointmentService();
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _filterAppointmentModel(AppointmentModel appointment) {
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      if (!(appointment.customerName?.toLowerCase().contains(query) ?? false) &&
          !(appointment.notes?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }

    // Status filtresi
    if (_selectedStatusFilter != 'all') {
      final status = AppointmentStatus.values.firstWhere(
        (e) => e.name == _selectedStatusFilter,
        orElse: () => AppointmentStatus.pending,
      );
      if (appointment.status != status) {
        return false;
      }
    }

    return true;
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Müşteri adı, hizmet ara...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(Icons.clear, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'Tümü', Icons.list, Colors.grey.shade600),
          _buildFilterChip(
              'pending', 'Bekliyor', Icons.schedule, Colors.orange),
          _buildFilterChip('planned', 'Planlandı', Icons.event, Colors.blue),
          _buildFilterChip(
              'confirmed', 'Onaylandı', Icons.check_circle, Colors.green),
          _buildFilterChip(
              'completed', 'Tamamlandı', Icons.done_all, Colors.green.shade700),
          _buildFilterChip('cancelled', 'İptal', Icons.cancel, Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String value, String label, IconData icon, Color color) {
    final isSelected = _selectedStatusFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onSelected: (selected) {
          setState(() => _selectedStatusFilter = value);
        },
        backgroundColor: Colors.white,
        selectedColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditAppointmentPage(
                  appointment: appointment,
                  currentUserId: appointment.userId,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appointment.status.color.withValues(alpha: 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        appointment.status.icon,
                        color: appointment.status.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.customerName ?? 'Müşteri',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.status.text,
                            style: TextStyle(
                              color: appointment.status.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd MMM', 'tr_TR')
                              .format(appointment.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${appointment.time.hour.toString().padLeft(2, '0')}:${appointment.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditAppointmentPage(
                                appointment: appointment,
                                currentUserId: appointment.userId,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(appointment);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF1A73E8)),
                              const SizedBox(width: 8),
                              Text('Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Sil'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (appointment.employeeName != null ||
                    appointment.notes != null ||
                    appointment.price != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (appointment.employeeName != null) ...[
                        Icon(Icons.person,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          appointment.employeeName!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (appointment.price != null) ...[
                        Icon(Icons.money,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${appointment.price!.toStringAsFixed(0)}₺',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                      ],
                      if (appointment.isPaid) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ödendi',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (appointment.status ==
                          AppointmentStatus.completed) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Borçlu',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.notes!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(AppointmentModel appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            Text('Randevuyu Sil'),
          ],
        ),
        content: Text(
          '${appointment.customerName ?? "Bu"} müşterisinin randevusunu silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AppointmentService().deleteAppointment(appointment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Randevu başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme işlemi başarısız: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _filterAppointment(Map<String, dynamic> data) {
    // Durum filtresi
    if (_selectedStatusFilter != 'all') {
      final status = data['status'] ?? 'pending';
      if (status != _selectedStatusFilter) return false;
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final customerName =
          (data['customerName'] ?? '').toString().toLowerCase();
      final notes = (data['notes'] ?? '').toString().toLowerCase();
      final employeeName =
          (data['employeeName'] ?? '').toString().toLowerCase();

      if (!customerName.contains(_searchQuery) &&
          !notes.contains(_searchQuery) &&
          !employeeName.contains(_searchQuery)) {
        return false;
      }
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
              color: const Color(0xFF1A73E8).withValues(alpha: 25),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.event_busy,
              size: 48,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz randevu bulunmuyor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter != 'all'
                ? 'Arama kriterlerinize uygun randevu bulunamadı'
                : 'İlk randevunuzu oluşturmak için + butonuna tıklayın',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty && _selectedStatusFilter == 'all')
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditAppointmentPage(
                      currentUserId:
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
                if (result == true) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Yeni Randevu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Kullanıcı oturumu bulunamadı.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text(
          'Randevular 📅',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: _appointmentService.getAppointmentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final appointments = snapshot.data ?? [];
                final filteredAppointments = appointments.where((appointment) {
                  return _filterAppointmentModel(appointment);
                }).toList();

                if (filteredAppointments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    return _buildAppointmentCard(appointment);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditAppointmentPage(
                currentUserId: userId,
              ),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Randevu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
