import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BeautyReportsPage extends StatefulWidget {
  const BeautyReportsPage({super.key});

  @override
  State<BeautyReportsPage> createState() => _BeautyReportsPageState();
}

class _BeautyReportsPageState extends State<BeautyReportsPage> {
  String _selectedPeriodKey = 'thisMonth';

  final List<String> _periodKeys = [
    'today',
    'thisWeek',
    'thisMonth',
    'thisYear',
    'customDate',
  ];

  // Dummy data
  final Map<String, dynamic> _reportData = {
    'totalRevenue': 12000.0,
    'totalExpenses': 3750.0,
    'netProfit': 8250.0,
    'totalCustomers': 120,
    'newCustomers': 15,
    'totalAppointments': 85,
    'completedAppointments': 78,
    'cancelledAppointments': 7,
    'averageServicePrice': 180.0,
    'topServices': [
      {'name': 'Saç Kesimi', 'count': 25, 'revenue': 6250.0},
      {'name': 'Boya', 'count': 18, 'revenue': 7200.0},
      {'name': 'Fön', 'count': 20, 'revenue': 3000.0},
      {'name': 'Manikür', 'count': 15, 'revenue': 1500.0},
    ],
    'dailyRevenue': [
      {'dayKey': 'mondayShort', 'amount': 1200.0},
      {'dayKey': 'tuesdayShort', 'amount': 1800.0},
      {'dayKey': 'wednesdayShort', 'amount': 2100.0},
      {'dayKey': 'thursdayShort', 'amount': 1600.0},
      {'dayKey': 'fridayShort', 'amount': 2400.0},
      {'dayKey': 'saturdayShort', 'amount': 2900.0},
      {'dayKey': 'sundayShort', 'amount': 0.0},
    ],
  };

  String _getTranslatedPeriod(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'today':
        return localizations.periodToday;
      case 'thisWeek':
        return localizations.periodThisWeek;
      case 'thisMonth':
        return localizations.periodThisMonth;
      case 'thisYear':
        return localizations.periodThisYear;
      case 'customDate':
        return localizations.periodCustomDate;
      default:
        return localizations.periodThisMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currencySymbol = localizations.currencySymbol;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.reportsPageTitle,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showCustomDialog(
              context,
              title: localizations.exportReportDialogTitle,
              content: localizations.exportOptionsPlaceholder,
            ),
            tooltip: localizations.exportReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppConstants.surfaceColor,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Text(
                    "${localizations.reportPeriod}:",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriodKey,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium),
                          borderSide: BorderSide(
                              color: AppConstants.textSecondary
                                  .withValues(alpha: 0.3)),
                        ),
                        filled: true,
                        fillColor: AppConstants.backgroundColor,
                      ),
                      items: _periodKeys.map((key) {
                        return DropdownMenuItem(
                          value: key,
                          child: Text(_getTranslatedPeriod(context, key)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedPeriodKey = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.generalStatus,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.paddingMedium,
                    mainAxisSpacing: AppConstants.paddingMedium,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        title: localizations.totalRevenue,
                        value:
                            "$currencySymbol${_reportData['totalRevenue'].toStringAsFixed(0)}",
                        icon: Icons.trending_up_outlined,
                        color: AppConstants.successColor,
                        trend: "+12%",
                      ),
                      _StatCard(
                        title: localizations.totalExpenses,
                        value:
                            "$currencySymbol${_reportData['totalExpenses'].toStringAsFixed(0)}",
                        icon: Icons.trending_down_outlined,
                        color: AppConstants.errorColor,
                        trend: "+5%",
                      ),
                      _StatCard(
                        title: localizations.netProfit,
                        value:
                            "$currencySymbol${_reportData['netProfit'].toStringAsFixed(0)}",
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppConstants.primaryColor,
                        trend: "+18%",
                      ),
                      _StatCard(
                        title: localizations.customerCount,
                        value: _reportData['totalCustomers'].toString(),
                        icon: Icons.people_outline,
                        color: AppConstants.warningColor,
                        trend: "+8%",
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    localizations.appointmentPerformance,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  CommonCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _MetricItem(
                                      label: localizations.totalAppointments,
                                      value: _reportData['totalAppointments']
                                          .toString(),
                                      icon: Icons.event_outlined,
                                      color: AppConstants.primaryColor)),
                              Expanded(
                                  child: _MetricItem(
                                      label:
                                          localizations.completedAppointments,
                                      value:
                                          _reportData['completedAppointments']
                                              .toString(),
                                      icon: Icons.check_circle_outline,
                                      color: AppConstants.successColor)),
                            ],
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          Row(
                            children: [
                              Expanded(
                                  child: _MetricItem(
                                      label:
                                          localizations.cancelledAppointments,
                                      value:
                                          _reportData['cancelledAppointments']
                                              .toString(),
                                      icon: Icons.cancel_outlined,
                                      color: AppConstants.errorColor)),
                              Expanded(
                                  child: _MetricItem(
                                      label: localizations.successRate,
                                      value:
                                          "${((_reportData['completedAppointments'] / _reportData['totalAppointments']) * 100).toInt()}%",
                                      icon: Icons.trending_up_outlined,
                                      color: AppConstants.successColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    localizations.topServices,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  CommonCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        children: [
                          for (int i = 0;
                              i < _reportData['topServices'].length;
                              i++) ...[
                            _ServiceRankItem(
                                rank: i + 1,
                                service: _reportData['topServices'][i],
                                localizations: localizations),
                            if (i < _reportData['topServices'].length - 1)
                              const Divider(height: AppConstants.paddingLarge),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Text(
                    localizations.weeklyRevenueTrend,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  CommonCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        children: [
                          Text(
                            localizations.dailyRevenueDistribution,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textPrimary),
                          ),
                          const SizedBox(height: AppConstants.paddingLarge),
                          SizedBox(
                            height: 200,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (int i = 0;
                                    i < _reportData['dailyRevenue'].length;
                                    i++) ...[
                                  Expanded(
                                    child: _BarChartItem(
                                      day: _getDayNameByKey(
                                          localizations,
                                          _reportData['dailyRevenue'][i]
                                              ['dayKey']),
                                      amount: _reportData['dailyRevenue'][i]
                                          ['amount'],
                                      maxAmount: _reportData['dailyRevenue']
                                          .map<double>((item) =>
                                              (item['amount'] as num)
                                                  .toDouble())
                                          .reduce((a, b) => a > b ? a : b),
                                      currencySymbol: currencySymbol,
                                    ),
                                  ),
                                  if (i <
                                      _reportData['dailyRevenue'].length - 1)
                                    const SizedBox(
                                        width: AppConstants.paddingSmall),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCustomDialog(
                            context,
                            title: localizations
                                .detailedFinancialReportDialogTitle,
                            content: localizations.financialAnalysisPlaceholder,
                          ),
                          icon: const Icon(Icons.analytics_outlined),
                          label: Text(localizations.detailedFinancialReport),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.paddingMedium)),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCustomDialog(
                            context,
                            title: localizations.customerAnalysisDialogTitle,
                            content: localizations.customerBehaviorPlaceholder,
                          ),
                          icon: const Icon(Icons.people_outlined),
                          label: Text(localizations.customerAnalysis),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.paddingMedium)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayNameByKey(AppLocalizations localizations, String dayKey) {
    switch (dayKey) {
      case 'mondayShort':
        return localizations.mondayShort;
      case 'tuesdayShort':
        return localizations.tuesdayShort;
      case 'wednesdayShort':
        return localizations.wednesdayShort;
      case 'thursdayShort':
        return localizations.thursdayShort;
      case 'fridayShort':
        return localizations.fridayShort;
      case 'saturdayShort':
        return localizations.saturdayShort;
      case 'sundayShort':
        return localizations.sundayShort;
      default:
        return dayKey;
    }
  }

  void _showCustomDialog(BuildContext context,
      {required String title, required String content}) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppConstants.textSecondary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: AppConstants.successColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
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

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ServiceRankItem extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> service;
  final AppLocalizations localizations;

  const _ServiceRankItem({
    required this.rank,
    required this.service,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _getRankColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service[
                    'name'], // Assuming service names are not translated in this dummy data
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              Text(
                '${service['count']} ${localizations.transactionsUnit}',
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          "${localizations.currencySymbol}${service['revenue'].toStringAsFixed(0)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppConstants.textSecondary;
    }
  }
}

class _BarChartItem extends StatelessWidget {
  final String day;
  final double amount;
  final double maxAmount;
  final String currencySymbol;

  const _BarChartItem({
    required this.day,
    required this.amount,
    required this.maxAmount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final height = maxAmount > 0 ? (amount / maxAmount) * 150 : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Text(
            "$currencySymbol${amount.toInt()}",
            style: const TextStyle(
              fontSize: 10,
              color: AppConstants.textSecondary,
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: amount > 0
                ? AppConstants.primaryColor
                : AppConstants.backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.borderRadiusSmall),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }
}
