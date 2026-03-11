import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/appProvider.dart';
import '../../models/Transfer.dart';
import '../../shared/PrintHelper.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  bool showAccounts = true;
  DateTime? _fromDate;
  DateTime? _toDate;
  final PrintHandler _printHandler = PrintHandler();

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: isFromDate ? 'اختر التاريخ من' : 'اختر التاريخ إلى',
        cancelText: 'إلغاء',
        confirmText: 'موافق',
      );
      if (picked != null) {
        setState(() {
          if (isFromDate) {
            _fromDate = picked;
          } else {
            _toDate = picked;
          }
        });
        
        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFromDate 
                ? 'تم تحديد تاريخ البداية: ${DateFormat('yyyy/MM/dd').format(picked)}'
                : 'تم تحديد تاريخ النهاية: ${DateFormat('yyyy/MM/dd').format(picked)}'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار التاريخ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Transfer> _getFilteredTransfers(AppProvider appProvider) {
    List<Transfer> transfers = appProvider.transfers;
    if (_fromDate != null) {
      transfers = transfers.where((transfer) => 
        transfer.date.isAfter(_fromDate!) || 
        transfer.date.isAtSameMomentAs(_fromDate!)
      ).toList();
    }
    if (_toDate != null) {
      transfers = transfers.where((transfer) => 
        transfer.date.isBefore(_toDate!.add(const Duration(days: 1)))
      ).toList();
    }
    return transfers;
  }

  Future<void> _printTransfersReport(AppProvider appProvider) async {
    final filteredTransfers = _getFilteredTransfers(appProvider);
    if (filteredTransfers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد حوالات للطباعة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      await _printHandler.printTransfersReport(
        filteredTransfers,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الطباعة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAccountNameDialog(BuildContext context, AppProvider appProvider) {
    final formKey = GlobalKey<FormState>();
    final accountNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حساب بنكي'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: accountNameController,
            decoration: const InputDecoration(
              labelText: 'اسم الحساب',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                appProvider.addAccountName(accountNameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddTransferDialog(BuildContext context, AppProvider appProvider) {
    final formKey = GlobalKey<FormState>();
    String? selectedAccount;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? transferType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حوالة'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'نوع الحوالة',
                    border: OutlineInputBorder(),
                  ),
                  value: transferType,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'إيداع',
                      child: Text('إيداع'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'سحب',
                      child: Text('سحب'),
                    ),
                  ],
                  onChanged: (String? value) {
                    transferType = value;
                  },
                  validator: (value) => value == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'الحساب',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedAccount,
                  items: appProvider.bankAccounts.map((account) => DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  )).toList(),
                  onChanged: (String? value) {
                    selectedAccount = value;
                  },
                  validator: (value) => value == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (double.tryParse(value!) == null) return 'الرجاء إدخال رقم صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'الملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                appProvider.addTransfer({
                  'type': transferType,
                  'account': selectedAccount,
                  'amount': double.parse(amountController.text),
                  'notes': notesController.text,
                  'date': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showTransferBetweenAccountsDialog(BuildContext context, AppProvider appProvider) {
    final formKey = GlobalKey<FormState>();
    String? fromAccount;
    String? toAccount;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التحويل بين الحسابات'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'من الحساب',
                    border: OutlineInputBorder(),
                  ),
                  value: fromAccount,
                  items: appProvider.bankAccounts.map((account) => DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  )).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      fromAccount = value;
                    });
                  },
                  validator: (value) => value == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'إلى الحساب',
                    border: OutlineInputBorder(),
                  ),
                  value: toAccount,
                  items: appProvider.bankAccounts.map((account) => DropdownMenuItem<String>(
                    value: account,
                    child: Text(account),
                  )).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      toAccount = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'مطلوب';
                    if (value == fromAccount) return 'لا يمكن التحويل إلى نفس الحساب';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (double.tryParse(value!) == null) return 'الرجاء إدخال رقم صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'الملاحظات',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final now = DateTime.now().toIso8601String();
                final amount = double.parse(amountController.text);
                final notes = notesController.text;
                
                // Add withdrawal from source account
                appProvider.addTransfer({
                  'type': 'سحب',
                  'account': fromAccount,
                  'amount': amount,
                  'notes': 'تحويل إلى $toAccount - $notes',
                  'date': now,
                });
                
                // Add deposit to destination account
                appProvider.addTransfer({
                  'type': 'إيداع',
                  'account': toAccount,
                  'amount': amount,
                  'notes': 'تحويل من $fromAccount - $notes',
                  'date': now,
                });
                
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with improved design
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Toggle buttons and main actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Card(
                          elevation: 2,
                          child: ToggleButtons(
                            borderRadius: BorderRadius.circular(8),
                          isSelected: [showAccounts, !showAccounts],
                          onPressed: (index) {
                            setState(() {
                              showAccounts = index == 0;
                                if (!showAccounts) {
                                  // Reset filters when switching to transfers
                                  _fromDate = null;
                                  _toDate = null;
                                }
                            });
                          },
                          children: const [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance),
                                    SizedBox(width: 8),
                                    Text('الحسابات البنكية'),
                                  ],
                                ),
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.sync_alt),
                                    SizedBox(width: 8),
                                    Text('الحوالات'),
                                  ],
                                ),
                            ),
                          ],
                        ),
                    ),
                    Row(
                      children: [
                            if (!showAccounts) ...[
                              // Print button for transfers
                              ElevatedButton.icon(
                                onPressed: () => _printTransfersReport(appProvider),
                                icon: const Icon(Icons.print),
                                label: const Text('طباعة التقرير'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                        FilledButton.icon(
                          onPressed: () => _showTransferBetweenAccountsDialog(context, appProvider),
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('التحويل بين الحسابات'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (showAccounts)
                          FilledButton.icon(
                            onPressed: () => _showAddAccountNameDialog(context, appProvider),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة حساب بنكي'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => _showAddTransferDialog(context, appProvider),
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة حوالة'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                              ),
                          ],
                          ),
                      ],
                    ),
                    
                    // Date filters for transfers view
                    if (!showAccounts) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              const Text(
                                'تصفية بالتاريخ:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _selectDate(context, true),
                                        icon: Icon(
                                          Icons.calendar_today,
                                          color: _fromDate != null ? Color(0xFFDC2626) : Colors.grey,
                                        ),
                                        label: Text(
                                          _fromDate != null
                                              ? 'من: ${DateFormat('yyyy/MM/dd').format(_fromDate!)}'
                                              : 'من تاريخ',
                                          style: TextStyle(
                                            color: _fromDate != null ? Color(0xFFDC2626) : Colors.grey.shade700,
                                            fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _fromDate != null ? Color(0xFFDC2626).withOpacity(0.1) : Colors.grey.shade50,
                                          side: BorderSide(
                                            color: _fromDate != null ? Color(0xFFDC2626) : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _selectDate(context, false),
                                        icon: Icon(
                                          Icons.calendar_today,
                                          color: _toDate != null ? Color(0xFFDC2626) : Colors.grey,
                                        ),
                                        label: Text(
                                          _toDate != null
                                              ? 'إلى: ${DateFormat('yyyy/MM/dd').format(_toDate!)}'
                                              : 'إلى تاريخ',
                                          style: TextStyle(
                                            color: _toDate != null ? Color(0xFFDC2626) : Colors.grey.shade700,
                                            fontWeight: _toDate != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _toDate != null ? Color(0xFFDC2626).withOpacity(0.1) : Colors.grey.shade50,
                                          side: BorderSide(
                                            color: _toDate != null ? Color(0xFFDC2626) : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_fromDate != null || _toDate != null)
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _fromDate = null;
                                            _toDate = null;
                                          });
                                        },
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'مسح التصفية',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Content area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Add scroll indicators
                      if (!showAccounts && _getFilteredTransfers(appProvider).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFDC2626).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Text(
                                'استخدم التمرير الأفقي والعمودي لرؤية جميع البيانات',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'عدد النتائج: ${_getFilteredTransfers(appProvider).length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Table content
              Expanded(
                child: showAccounts
                    ? _buildAccountsTable(appProvider)
                    : _buildTransfersTable(appProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountsTable(AppProvider appProvider) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 32,
              ),
      child: DataTable(
                columnSpacing: 32,
                horizontalMargin: 16,
                headingRowHeight: 56,
                dataRowHeight: 72,
                headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
        columns: const [
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.account_balance, size: 16),
                        SizedBox(width: 4),
                        Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 16),
                        SizedBox(width: 4),
                        Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 4),
                        Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DataColumn(
                    label: Row(
                      children: [
                        Icon(Icons.delete, size: 16),
                        SizedBox(width: 4),
                        Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
        ],
        rows: appProvider.bankAccounts.map((account) {
                  final balance = appProvider.getAccountBalance(account);
          return DataRow(
            cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: 200,
                          child: Text(
                            account,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: balance >= 0 ? Color(0xFFDC2626).withOpacity(0.1) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: balance >= 0 ? Color(0xFFDC2626).withOpacity(0.3) : Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            '${balance.toStringAsFixed(2)} JOD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Color(0xFFDC2626) : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFDC2626)),
                onPressed: () {
                  // TODO: Implement edit functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('سيتم إضافة وظيفة التعديل قريباً')),
                            );
                          },
                          tooltip: 'تعديل الحساب',
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                            // TODO: Implement delete functionality with confirmation
                            _showDeleteConfirmation(context, account, appProvider);
                },
                          tooltip: 'حذف الحساب',
                        ),
                      ),
            ],
          );
        }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String account, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الحساب "$account"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement actual deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم إضافة وظيفة الحذف قريباً')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransfersTable(AppProvider appProvider) {
    final filteredTransfers = _getFilteredTransfers(appProvider);
    
    if (filteredTransfers.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لا توجد حوالات',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'قم بإضافة حوالة جديدة أو تعديل التصفية',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculate totals for filtered transfers
    final totalDeposits = filteredTransfers
        .where((t) => t.type == 'إيداع')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalWithdrawals = filteredTransfers
        .where((t) => t.type == 'سحب')
        .fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalDeposits - totalWithdrawals;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'إجمالي الإيداعات',
                      totalDeposits,
                      Icons.arrow_upward,
                      Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'إجمالي السحوبات',
                      totalWithdrawals,
                      Icons.arrow_downward,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'الصافي',
                      netAmount,
                      Icons.account_balance_wallet,
                      netAmount >= 0 ? Color(0xFFDC2626) : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            
            // Table
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
      child: DataTable(
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        headingRowHeight: 56,
                        dataRowHeight: 72,
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
        columns: const [
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.category, size: 18),
                                SizedBox(width: 6),
                                Text('نوع الحوالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.account_balance, size: 18),
                                SizedBox(width: 6),
                                Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.monetization_on, size: 18),
                                SizedBox(width: 6),
                                Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                SizedBox(width: 6),
                                Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.note, size: 18),
                                SizedBox(width: 6),
                                Text('الملاحظات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 6),
                                Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.delete, size: 18),
                                SizedBox(width: 6),
                                Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
        ],
                        rows: filteredTransfers.map((transfer) {
          return DataRow(
                            color: MaterialStateProperty.resolveWith((states) {
                              return transfer.type == 'إيداع' 
                                  ? Color(0xFFDC2626).withOpacity(0.1) 
                                  : Colors.red.shade50;
                            }),
            cells: [
                              DataCell(
                                Container(
                                  width: 90,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: transfer.type == 'إيداع' ? Color(0xFFDC2626) : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          transfer.type == 'إيداع' ? Icons.arrow_upward : Icons.arrow_downward,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          transfer.type == 'إيداع' ? 'إيداع' : 'سحب',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 120,
                                  child: Text(
                                    transfer.account,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 100,
                                  child: Text(
                                    '${transfer.amount.toStringAsFixed(2)} JOD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: transfer.type == 'إيداع' ? Color(0xFFDC2626) : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('yyyy/MM/dd').format(transfer.date),
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                      Text(
                                        DateFormat('HH:mm').format(transfer.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    transfer.notes.isNotEmpty ? transfer.notes : '-',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: transfer.notes.isNotEmpty ? Colors.black87 : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 60,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFFDC2626), size: 20),
                onPressed: () {
                  // TODO: Implement edit functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('سيتم إضافة وظيفة التعديل قريباً')),
                                      );
                                    },
                                    tooltip: 'تعديل الحوالة',
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 60,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                                      _showDeleteTransferConfirmation(context, transfer, appProvider);
                },
                                    tooltip: 'حذف الحوالة',
                                  ),
                                ),
                              ),
            ],
          );
        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} JOD',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransferConfirmation(BuildContext context, Transfer transfer, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من حذف هذه الحوالة؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('النوع: ${transfer.type}'),
                  Text('الحساب: ${transfer.account}'),
                  Text('المبلغ: ${transfer.amount.toStringAsFixed(2)} JOD'),
                  Text('التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(transfer.date)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement actual deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم إضافة وظيفة الحذف قريباً')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
} 