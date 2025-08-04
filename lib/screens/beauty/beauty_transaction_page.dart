import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/transaction_model.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/modern_forms.dart';

class BeautyTransactionPage extends StatefulWidget {
  const BeautyTransactionPage({super.key});

  @override
  State<BeautyTransactionPage> createState() => _BeautyTransactionPageState();
}

class _BeautyTransactionPageState extends State<BeautyTransactionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterKey = 'all';
  DateTimeRange? _selectedDateRange;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  final List<String> _filterKeys = ['all', 'income', 'expense'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final query = FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _transactions = snapshot.docs
              .map((doc) =>
                  TransactionModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.transactionLoadError),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  String _getTranslatedFilterName(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'all':
        return localizations.all;
      case 'income':
        return localizations.filterIncome;
      case 'expense':
        return localizations.filterExpense;
      default:
        return key;
    }
  }

  List<TransactionModel> get _filteredTransactions {
    final localizations = AppLocalizations.of(context)!;
    return _transactions.where((transaction) {
      final matchesSearch = _searchQuery.isEmpty ||
          transaction.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          transaction.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          transaction
              .getCategoryText(localizations)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilterKey == 'all' ||
          transaction.type.name == _selectedFilterKey;

      final matchesDate = _selectedDateRange == null ||
          (transaction.createdAt.isAfter(_selectedDateRange!.start) &&
              transaction.createdAt.isBefore(
                  _selectedDateRange!.end.add(const Duration(days: 1))));

      return matchesSearch && matchesFilter && matchesDate;
    }).toList();
  }

  double get _totalIncome => _filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (totalAmount, t) => totalAmount + t.amount);

  double get _totalExpense => _filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (totalAmount, t) => totalAmount + t.amount);

  double get _netProfit => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final currencySymbol = localizations.currencySymbol;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          localizations.transactionPageTitle,
          style: const TextStyle(color: AppConstants.textPrimary),
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: _selectDateRange,
            tooltip: localizations.filterDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadTransactions,
            tooltip: localizations.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: AppConstants.surfaceColor,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                CommonInput(
                  controller: _searchController,
                  hintText: localizations.searchTransactionHint,
                  prefixIcon: const Icon(Icons.search_outlined),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterKeys.length,
                    itemBuilder: (context, index) {
                      final key = _filterKeys[index];
                      final isSelected = _selectedFilterKey == key;

                      return Padding(
                        padding: const EdgeInsets.only(
                            right: AppConstants.paddingSmall),
                        child: FilterChip(
                          label: Text(_getTranslatedFilterName(context, key)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _selectedFilterKey = key);
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

                // Stat Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: localizations.totalIncome,
                        value:
                            "$currencySymbol${_totalIncome.toStringAsFixed(0)}",
                        icon: Icons.trending_up_outlined,
                        color: AppConstants.successColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.totalExpense,
                        value:
                            "$currencySymbol${_totalExpense.toStringAsFixed(0)}",
                        icon: Icons.trending_down_outlined,
                        color: AppConstants.errorColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: _StatCard(
                        title: localizations.netProfit,
                        value:
                            "$currencySymbol${_netProfit.toStringAsFixed(0)}",
                        icon: _netProfit >= 0
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_balance_wallet,
                        color: _netProfit >= 0
                            ? AppConstants.successColor
                            : AppConstants.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.receipt_long_outlined,
                              size: 64,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? localizations.noResultsFound
                                  : localizations.noTransactionsYet,
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              ElevatedButton.icon(
                                onPressed: _addNewTransaction,
                                icon: const Icon(Icons.add),
                                label: Text(localizations.addFirstTransaction),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return _TransactionCard(
                              transaction: transaction,
                              onTap: () => _showTransactionDetails(transaction),
                              onEdit: () => _editTransaction(transaction),
                              onDelete: () =>
                                  _deleteTransaction(transaction.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTransaction,
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          localizations.addNewTransaction,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _selectDateRange() async {
    final localizations = AppLocalizations.of(context)!;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      helpText: localizations.filterDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final localizations = AppLocalizations.of(context)!;
    final currencySymbol = localizations.currencySymbol;
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              transaction.type == TransactionType.income
                  ? Icons.trending_up_outlined
                  : Icons.trending_down_outlined,
              color: transaction.type == TransactionType.income
                  ? AppConstants.successColor
                  : AppConstants.errorColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(transaction.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(localizations.transactionType,
                transaction.getTypeText(localizations)),
            _DetailRow(localizations.category,
                transaction.getCategoryText(localizations)),
            _DetailRow(localizations.amount,
                "$currencySymbol${transaction.amount.toStringAsFixed(2)}"),
            _DetailRow(
                localizations.date,
                DateFormat.yMd(languageCode)
                    .add_jm()
                    .format(transaction.createdAt)),
            if (transaction.description.isNotEmpty)
              _DetailRow(localizations.description, transaction.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editTransaction(transaction);
            },
            child: Text(localizations.edit),
          ),
        ],
      ),
    );
  }

  void _addNewTransaction() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => BeautyTransactionForm(
        onSaved: () {
          _loadTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.transactionAddedSuccess),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _editTransaction(TransactionModel transaction) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => BeautyTransactionForm(
        transactionId: transaction.id,
        onSaved: () {
          _loadTransactions();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.transactionUpdatedSuccess),
              backgroundColor: AppConstants.successColor,
            ),
          );
        },
      ),
    );
  }

  void _deleteTransaction(String transactionId) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteTransactionTitle),
        content: Text(localizations.confirmDeleteTransaction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('transactions')
                    .doc(transactionId)
                    .delete();
                _loadTransactions();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.transactionDeletedSuccess),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${localizations.deleteError}: $e"),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimary,
              ),
            ),
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
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final typeColor =
        isIncome ? AppConstants.successColor : AppConstants.errorColor;
    final typeIcon =
        isIncome ? Icons.trending_up_outlined : Icons.trending_down_outlined;
    final localizations = AppLocalizations.of(context)!;
    final currencySymbol = localizations.currencySymbol;
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

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
                  backgroundColor: typeColor.withValues(alpha: 0.1),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        transaction.getCategoryText(localizations),
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIncome ? '+' : '-'}$currencySymbol${transaction.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall),
                        border:
                            Border.all(color: typeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        transaction.getTypeText(localizations),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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
            Row(
              children: [
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: DateFormat.yMd(languageCode)
                      .add_jm()
                      .format(transaction.createdAt),
                  color: AppConstants.textSecondary,
                ),
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.note_outlined,
                      label: transaction.description,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
