import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../widgets/enhanced_forms.dart';
import '../../services/beauty_service_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyServicePage extends StatefulWidget {
  const BeautyServicePage({super.key});

  @override
  State<BeautyServicePage> createState() => _BeautyServicePageState();
}

class _BeautyServicePageState extends State<BeautyServicePage> {
  final ServiceService _serviceService = ServiceService();
  final BeautyServiceService _beautyServiceService = BeautyServiceService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  BeautyServiceCategory? _selectedCategory;
  bool _showOnlyActive = false;

  // İstatistik verileri
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _serviceService.getServiceStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (kDebugMode) print('Hizmet istatistikleri yüklenirken hata: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  List<ServiceModel> get _filteredServices {
    List<ServiceModel> services = _stats['services'] ?? [];

    if (_searchQuery.isNotEmpty) {
      services = services.where((service) {
        return service.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            service.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != null) {
      services = services
          .where((service) => service.category == _selectedCategory)
          .toList();
    }

    if (_showOnlyActive) {
      services = services.where((service) => service.isActive).toList();
    }

    return services;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.services,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: Column(
          children: [
            // Arama ve Filtreler
            Container(
              color: AppConstants.surfaceColor,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  // Arama çubuğu
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '${localizations.search}...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppConstants.backgroundColor,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Kategori filtreleri
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryChip(localizations.all, null),
                        ...BeautyServiceCategory.values.map(
                          (category) => _buildCategoryChip(
                            _getCategoryName(category),
                            category,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // İstatistik kartları
            if (!_isLoadingStats) _buildStatsSection(),

            // Hizmet listesi
            Expanded(
              child: _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredServices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            return _ServiceCard(
                              service: service,
                              onEdit: () => _editService(service),
                              onDelete: () => _deleteService(service),
                              onToggleStatus: () =>
                                  _toggleServiceStatus(service),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewService,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          localizations.addService,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, BeautyServiceCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: AppConstants.backgroundColor,
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: AppConstants.surfaceColor,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Toplam Hizmet',
              value: '${_stats['totalServices'] ?? 0}',
              icon: Icons.design_services,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Aktif Hizmet',
              value: '${_stats['activeServices'] ?? 0}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Ortalama Fiyat',
              value: '₺${_stats['averagePrice']?.toStringAsFixed(0) ?? '0'}',
              icon: Icons.attach_money,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 80,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz hizmet eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk hizmetinizi eklemek için + butonuna basın',
            style: TextStyle(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewService,
            icon: const Icon(Icons.add),
            label: Text(localizations.addService),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtreler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Sadece aktif hizmetler'),
              value: _showOnlyActive,
              onChanged: (value) {
                setState(() => _showOnlyActive = value);
                Navigator.pop(context);
              },
            ),
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

  void _addNewService() {
    showDialog(
      context: context,
      builder: (context) => EnhancedBeautyServiceForm(
        onSaved: () {
          _loadStats();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hizmet başarıyla eklendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _editService(ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => EnhancedBeautyServiceForm(
        serviceId: service.id,
        onSaved: () {
          _loadStats();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hizmet başarıyla güncellendi'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hizmeti Sil'),
        content: Text(
            '${service.name} hizmetini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _serviceService.deleteService(service.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hizmet başarıyla silindi'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        _loadStats();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hizmet silinirken hata oluştu: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleServiceStatus(ServiceModel service) async {
    try {
      final updatedService = service.copyWith(isActive: !service.isActive);
      await _serviceService.updateService(updatedService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.isActive
              ? 'Hizmet pasif yapıldı'
              : 'Hizmet aktif yapıldı'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hizmet durumu değiştirilirken hata oluştu: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  String _getCategoryName(BeautyServiceCategory category) {
    return category.displayName;
  }
}

// Widget sınıfları
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
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
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

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      if (service.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.isActive
                        ? AppConstants.successColor.withValues(alpha: 0.1)
                        : AppConstants.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? 'Aktif' : 'Pasif',
                    style: TextStyle(
                      fontSize: 12,
                      color: service.isActive
                          ? AppConstants.successColor
                          : AppConstants.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _DetailChip(
                  icon: Icons.attach_money,
                  label: '₺${service.price.toStringAsFixed(0)}',
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.access_time,
                  label: '${service.durationMinutes} dk',
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.category,
                  label: _getCategoryName(service.category),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Düzenle',
                ),
                IconButton(
                  icon: Icon(
                    service.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: onToggleStatus,
                  tooltip: service.isActive ? 'Pasif Yap' : 'Aktif Yap',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Sil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(BeautyServiceCategory category) {
    return category.displayName;
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
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
