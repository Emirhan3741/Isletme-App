import 'package:flutter/material.dart';

import '../../models/appointment_model.dart';
import '../../models/customer_model.dart';
import '../../services/appointment_service.dart';

class CustomerDetailPage extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailPage({Key? key, required this.customer})
      : super(key: key);

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppointmentModel> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    final appointments = await AppointmentService()
        .getAppointmentsByCustomerId(widget.customer.id);
    setState(() {
      _appointments = appointments;
      _loading = false;
    });
  }

  Color _statusColor(AppointmentStatus status) {
    return status.color;
  }

  IconData _statusIcon(AppointmentStatus status) {
    return status.icon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: AddEditCustomerPage'e navigate et
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Müşteri düzenleme sayfası henüz hazır değil')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                _buildCustomerInfo(),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Randevular'),
                    Tab(text: 'Ödemeler'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList(),
                      _buildPaymentsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.customer.firstName} ${widget.customer.lastName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(widget.customer.phone),
              ],
            ),
            if (widget.customer.email != null &&
                widget.customer.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.customer.email!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) {
      return const Center(
        child: Text('Henüz randevu bulunmuyor'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Card(
          child: ListTile(
            leading: Icon(
              _statusIcon(appointment.status),
              color: _statusColor(appointment.status),
            ),
            title: Text(
              appointment.note ?? 'Randevu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              appointment.date.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    return const Center(
      child: Text('Ödeme geçmişi burada görüntülenecek'),
    );
  }
}
