import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../widgets/enhanced_forms.dart';
import '../../services/beauty_employee_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyEmployeePage extends StatefulWidget {
  const BeautyEmployeePage({super.key});

  @override
  State<BeautyEmployeePage> createState() => _BeautyEmployeePageState();
}

class _BeautyEmployeePageState extends State<BeautyEmployeePage> {
  final BeautyEmployeeService _employeeService = BeautyEmployeeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _selectedFilter;
  bool _isLoading = false;
  List<Map<String, dynamic>> _employees = [];

  late List<String> _filters;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context)!;
    _filters = [
      localizations.filterAll,
      localizations.filterActive,
      localizations.filterOnLeave,
      localizations.filterInactive,
    ];
    _selectedFilter = _filters[0];
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    final allEmployees = _employees;
    final localizations = AppLocalizations.of(context)!;
    return allEmployees.where((employee) {
      final matchesSearch = _searchQuery.isEmpty ||
          employee['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          employee['position']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (employee['skills'] as List).any((skill) => skill
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()));

      final statusText = _getStatusText(employee['status']);
      final matchesFilter = _selectedFilter == localizations.filterAll ||
          statusText == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // _filters will be initialized in didChangeDependencies
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final employees = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _employees = employees;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Ã‡alÄ±ÅŸanlar yÃ¼klenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ã‡alÄ±ÅŸanlar yÃ¼klenirken hata oluÅŸtu: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.employeeManagement,
          style: TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showPerformanceReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtreler
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Arama Ã‡ubuÄŸu
                CommonInput(
                  controller: _searchController,
                  hintText: localizations.searchEmployeeHint,
                  prefixIcon: const Icon(Icons.search_outlined),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Durum Filtreleri
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(
                            right: AppConstants.paddingSmall),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: AppConstants.backgroundColor,
                          selectedColor:
                              AppConstants.primaryColor.withValues(alpha: 0.1),
                          checkmarkColor: AppConstants.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                // Ä°statistik KartlarÄ±
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: localizations.totalEmployee,
                        value: _filteredEmployees.length.toString(),
                        icon: Icons.people_outline,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.activeEmployee,
                        value: _filteredEmployees
                            .where((e) => e['status'] == 'active')
                            .length
                            .toString(),
                        icon: Icons.check_circle_outline,
                        color: AppConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.averageRating,
                        value: _filteredEmployees.isNotEmpty
                            ? (_filteredEmployees
                                        .map((e) => e['rating'] ?? 0.0)
                                        .reduce((a, b) => a + b) /
                                    _filteredEmployees.length)
                                .toStringAsFixed(1)
                            : "0.0",
                        icon: Icons.star_outline,
                        color: AppConstants.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ã‡alÄ±ÅŸan Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              localizations.noEmployeeFound,
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = _filteredEmployees[index];
                          return _EmployeeCard(
                            employee: employee,
                            onTap: () => _showEmployeeDetails(employee),
                            onEdit: () => _editEmployee(employee),
                            onDelete: () => _deleteEmployee(employee['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewEmployee,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          localizations.addNewEmployee,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showPerformanceReport() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.performanceReport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.performanceReportPlaceholder),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${localizations.position}: ${employee['position']}"),
              Text("${localizations.phone}: ${employee['phone']}"),
              Text("${localizations.email}: ${employee['email']}"),
              Text("${localizations.salary}: â‚º${employee['salary']}"),
              Text(
                  "${localizations.startDate}: ${_formatDate(employee['startDate'].toDate())}"),
              Text(
                  "${localizations.experience}: ${employee['experience']} ${localizations.years}"),
              Text("${localizations.rating}: ${employee['rating']}/5.0"),
              Text(
                  "${localizations.totalServices}: ${employee['totalServices']}"),
              Text(
                  "${localizations.monthlyTarget}: ${employee['monthlyTarget']}"),
              Text(
                  "${localizations.completedTarget}: ${employee['completedTarget']}"),
              Text("${localizations.commission}: %${employee['commission']}"),
              Text(
                  "${localizations.workingHours}: ${employee['workingHours']}"),
              Text(
                  "${localizations.skills}: ${(employee['skills'] as List).join(', ')}"),
              Text(
                  "${localizations.workingDays}: ${(employee['workingDays'] as List).join(', ')}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editEmployee(employee);
            },
            child: Text(localizations.edit),
          ),
        ],
      ),
    );
  }

  void _addNewEmployee() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => EnhancedBeautyEmployeeForm(
        onSaved: () {
          _loadEmployees();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.employeeAddedSuccess),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _editEmployee(Map<String, dynamic> employee) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => EnhancedBeautyEmployeeForm(
        employeeId: employee['id'],
        onSaved: () {
          _loadEmployees();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.employeeUpdatedSuccess),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _deleteEmployee(String employeeId) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteEmployee),
        content: Text(localizations.deleteEmployeeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('employees')
                    .doc(employeeId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  _loadEmployees();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.employeeDeletedSuccess),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text("${localizations.errorDeletingEmployee}: $e"),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'active':
        return localizations.active;
      case 'leave':
        return localizations.onLeave;
      case 'inactive':
        return localizations.inactive;
      default:
        return localizations.unknown;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppConstants.successColor;
      case 'leave':
        return AppConstants.warningColor;
      case 'inactive':
        return AppConstants.errorColor;
      default:
        return AppConstants.textSecondary;
    }
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
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _getStatusText(BuildContext context, String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'active':
        return localizations.active;
      case 'on_leave':
        return localizations.onLeave;
      case 'inactive':
        return localizations.inactive;
      default:
        return localizations.unknown;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppConstants.successColor;
      case 'on_leave':
        return AppConstants.warningColor;
      case 'inactive':
        return AppConstants.errorColor;
      default:
        return AppConstants.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final status = employee['status'];
    final targetCompletion = (employee['monthlyTarget'] != null &&
            employee['monthlyTarget'] > 0)
        ? ((employee['completedTarget'] ?? 0) / employee['monthlyTarget'] * 100)
            .round()
        : 0;

    return CommonCard(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      AppConstants.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    employee['name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Text(
                        employee['position'],
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppConstants.warningColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${employee['rating']}/5.0",
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall),
                        border: Border.all(
                            color:
                                _getStatusColor(status).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _getStatusText(context, status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "â‚º${employee['salary'].toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppConstants.textSecondary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 16),
                          const SizedBox(width: 8),
                          Text(localizations.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline,
                              size: 16, color: AppConstants.errorColor),
                          const SizedBox(width: 8),
                          Text(localizations.delete,
                              style: const TextStyle(
                                  color: AppConstants.errorColor)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Yetenekler
            Wrap(
              spacing: AppConstants.paddingSmall,
              runSpacing: 4,
              children: (employee['skills'] as List).map<Widget>((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                    border: Border.all(
                        color:
                            AppConstants.textSecondary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Performans GÃ¶stergesi
            if (status == 'active') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.monthlyTarget,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            Text(
                              "$targetCompletion%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: targetCompletion >= 80
                                    ? AppConstants.successColor
                                    : targetCompletion >= 50
                                        ? AppConstants.warningColor
                                        : AppConstants.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: targetCompletion / 100,
                          backgroundColor: AppConstants.backgroundColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            targetCompletion >= 80
                                ? AppConstants.successColor
                                : targetCompletion >= 50
                                    ? AppConstants.warningColor
                                    : AppConstants.errorColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${employee['completedTarget']} / ${employee['monthlyTarget']} ${localizations.services}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppConstants.paddingMedium),

            Row(
              children: [
                _InfoChip(
                  icon: Icons.work_outline,
                  label:
                      "${localizations.experience}: ${employee['experience']} ${localizations.years}",
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: employee['workingHours'],
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                _InfoChip(
                  icon: Icons.percent_outlined,
                  label:
                      "%${employee['commission']} ${localizations.commission}",
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
