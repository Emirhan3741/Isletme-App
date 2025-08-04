import 'package:flutter/material.dart';
import '../../core/widgets/paginated_list_view.dart';
import '../../models/service_model.dart';
import '../../controllers/services_controller.dart';
import '../../utils/feedback_utils.dart';
import 'add_edit_service_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({Key? key}) : super(key: key);

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  late final ServicesController _controller;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Tümü',
    'Saç Bakımı',
    'Cilt Bakımı',
    'Makyaj',
    'Masaj',
    'Estetik',
    'Tedavi',
    'Konsültasyon',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _controller = ServicesController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.updateSearch(_searchController.text);
  }

  void _showAddServiceDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditServicePage(),
      ),
    );
    if (result == true) {
      _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: PaginatedListView<ServiceModel>(
              controller: _controller,
              emptyTitle: 'Henüz hizmet yok',
              emptySubtitle: 'İlk hizmetinizi ekleyerek başlayın',
              emptyIcon: Icons.room_service,
              emptyActionLabel: 'İlk Hizmeti Ekle',
              onEmptyAction: _showAddServiceDialog,
              color: const Color(0xFFFFA726),
              itemSpacing: 16,
              itemBuilder: (context, service, index) {
                return _buildServiceCard(service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
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
                    hintText: 'Hizmet ara...',
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
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAddServiceDialog,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Hizmet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
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
          const SizedBox(height: 16),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'Kategori',
                _controller.selectedCategoryFilter,
                _categories,
                (value) {
                  if (value != null) {
                    _controller.updateCategoryFilter(value);
                  }
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Sadece Aktifler'),
                selected: _controller.showActiveOnly,
                onSelected: (value) => _controller.updateActiveFilter(value),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _controller.clearFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                tooltip: 'Filtreleri Temizle',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: $currentValue'),
        backgroundColor: currentValue != 'Tümü'
            ? const Color(0xFFFFA726).withValues(alpha: 25)
            : Colors.grey[100],
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onSelected: (String? value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 12),
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
                  color: const Color(0xFFFFA726).withValues(alpha: 25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.room_service,
                  color: const Color(0xFFFFA726),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                '₺${service.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${service.durationMinutes} dk',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.category,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                service.category.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (service.description != null &&
              service.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              service.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service.isActive
                      ? Colors.green.withValues(alpha: 25)
                      : Colors.grey.withValues(alpha: 25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.isActive ? 'Aktif' : 'Pasif',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        service.isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showEditServiceDialog(service),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Düzenle',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(service),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(ServiceModel service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditServicePage(
          service: service,
        ),
      ),
    );
    if (result == true) {
      _controller.refresh();
    }
  }

  void _showDeleteConfirmation(ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hizmeti Sil'),
        content: Text(
            '${service.name} hizmetini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _controller.deleteService(service.id);
                if (mounted) {
                  FeedbackUtils.showSuccess(context, 'Hizmet silindi');
                }
              } catch (e) {
                if (mounted) {
                  FeedbackUtils.showError(context, 'Silme hatası: $e');
                }
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
