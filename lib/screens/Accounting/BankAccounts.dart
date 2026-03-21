import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../shared/appProvider.dart';
import '../../models/Transfer.dart';
import '../../shared/PrintHelper.dart';
import '../../models/customer.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  int _selectedTabIndex = 0; // 0: اليومية, 1: الحسابات النقديه, 2: قائمة الدخل
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedAccountFilter;
  final PrintHandler _printHandler = PrintHandler();
  final TextEditingController _accountSearchController =
      TextEditingController();

  @override
  void dispose() {
    _accountSearchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

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
            content: Text(isFromDate
                ? 'تم تحديد تاريخ البداية: ${DateFormat('yyyy/MM/dd').format(picked)}'
                : 'تم تحديد تاريخ النهاية: ${DateFormat('yyyy/MM/dd').format(picked)}'),
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
      transfers = transfers
          .where((transfer) =>
              transfer.date.isAfter(_fromDate!) ||
              transfer.date.isAtSameMomentAs(_fromDate!))
          .toList();
    }
    if (_toDate != null) {
      transfers = transfers
          .where((transfer) =>
              transfer.date.isBefore(_toDate!.add(const Duration(days: 1))))
          .toList();
    }
    if (_selectedAccountFilter != null) {
      transfers = transfers
          .where((transfer) =>
              transfer.account == _selectedAccountFilter ||
              transfer.otherAccount == _selectedAccountFilter)
          .toList();
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

  void _showAddAccountNameDialog(
      BuildContext context, AppProvider appProvider) {
    final formKey = GlobalKey<FormState>();
    final accountNameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حساب بنكي'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: accountNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحساب',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'رصيد أول المدة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    if (double.tryParse(value!) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                  }
                  return null;
                },
              ),
            ],
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
                
                final balanceText = balanceController.text;
                if (balanceText.isNotEmpty) {
                  final balance = double.tryParse(balanceText);
                  if (balance != null && balance != 0) {
                    appProvider.addTransfer({
                      'type': balance >= 0 ? 'إيداع' : 'سحب',
                      'account': accountNameController.text,
                      'otherAccount': 'رأس المال',
                      'otherAccountCategory': 'أخرى',
                      'amount': balance.abs(),
                      'notes': 'رصيد افتتاحي',
                      'date': DateTime.now().toIso8601String(),
                    });
                  }
                }

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
    final otherAccountController = TextEditingController();
    String? transferType;
    String? selectedCustomer;
    String? selectedOtherBankAccount;
    AccountCategory? selectedOtherAccountCategory;

    final otherAccountFocusNode1 = FocusNode();
    final otherAccountFocusNode2 = FocusNode();
    final layerLink1 = LayerLink();
    final layerLink2 = LayerLink();

    final Set<String> accountsSet = {};
    for (var transfer in appProvider.transfers) {
      if (transfer.account.trim().isNotEmpty) accountsSet.add(transfer.account);
      if (transfer.otherAccount.trim().isNotEmpty) {
        accountsSet.add(transfer.otherAccount);
      }
    }
    for (var account in appProvider.bankAccounts) {
      if (account.trim().isNotEmpty) accountsSet.add(account);
    }
    final List<String> uniqueAccounts = accountsSet.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة قيد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'نوع العملية',
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
                      DropdownMenuItem<String>(
                        value: 'مبيعات',
                        child: Text('مبيعات'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'مصروفات',
                        child: Text('مصروفات'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'تحصيلات من السائق',
                        child: Text('تحصيلات من السائق'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'سداد للزبون',
                        child: Text('سداد للزبون'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'تحويل',
                        child: Text('تحويل بين الحسابات'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setDialogState(() {
                        transferType = value;
                        selectedCustomer = null;
                        selectedOtherBankAccount = null;
                        selectedOtherAccountCategory = null;
                        otherAccountController.clear();
                      });
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
                    items: appProvider.bankAccounts
                        .map((account) => DropdownMenuItem<String>(
                              value: account,
                              child: Text(account),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedAccount = value;
                      });
                    },
                    validator: (value) => value == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  // الحساب المقابل - يتغير حسب نوع العملية
                  if (transferType == 'مصروفات')
                    TextFormField(
                      controller: otherAccountController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المصروف',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    )
                  else if (transferType == 'مبيعات')
                    TextFormField(
                      controller: otherAccountController,
                      decoration: const InputDecoration(
                        labelText: 'مصدر المبيعات',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'مطلوب' : null,
                    )
                  else if (transferType == 'تحصيلات من السائق' ||
                      transferType == 'سداد للزبون')
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: transferType == 'تحصيلات من السائق'
                            ? 'الزبون'
                            : 'الزبون (الحساب المقابل)',
                        border: const OutlineInputBorder(),
                      ),
                      value: selectedCustomer,
                      items: appProvider.customers
                          .map((customer) => DropdownMenuItem<String>(
                                value: customer.username,
                                child: Text(customer.username),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedCustomer = value;
                        });
                      },
                      validator: (value) => value == null ? 'مطلوب' : null,
                    )
                  else if (transferType == 'تحويل')
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'إلى حساب',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedOtherBankAccount,
                      items: appProvider.bankAccounts
                          .where((a) => a != selectedAccount)
                          .map((account) => DropdownMenuItem<String>(
                                value: account,
                                child: Text(account),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedOtherBankAccount = value;
                        });
                      },
                      validator: (value) => value == null ? 'مطلوب' : null,
                    )
                  else if (transferType == 'إيداع' || transferType == 'سحب')
                    Column(
                      children: [
                        CompositedTransformTarget(
                          link: layerLink1,
                          child: RawAutocomplete<String>(
                            textEditingController: otherAccountController,
                            focusNode: otherAccountFocusNode1,
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return uniqueAccounts;
                              }
                              return uniqueAccounts.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            fieldViewBuilder: (BuildContext context,
                                TextEditingController textEditingController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'الحساب المقابل',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'مطلوب' : null,
                                onFieldSubmitted: (String value) {
                                  onFieldSubmitted();
                                },
                              );
                            },
                            optionsViewBuilder: (BuildContext context,
                                AutocompleteOnSelected<String> onSelected,
                                Iterable<String> options) {
                              return CompositedTransformFollower(
                                link: layerLink1,
                                showWhenUnlinked: false,
                                targetAnchor: Alignment.bottomLeft,
                                followerAnchor: Alignment.topLeft,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    borderRadius: BorderRadius.circular(8),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 200,
                                        maxWidth: 400, // Fixed width or match field
                                      ),
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final String option = options.elementAt(index);
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text(option),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<AccountCategory>(
                          decoration: const InputDecoration(
                            labelText: 'تصنيف الحساب المقابل',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedOtherAccountCategory,
                          items: AccountCategory.values
                              .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category.label),
                                  ))
                              .toList(),
                          onChanged: (AccountCategory? value) {
                            setDialogState(() {
                              selectedOtherAccountCategory = value;
                            });
                          },
                          validator: (value) => value == null ? 'مطلوب' : null,
                        ),
                      ],
                    )
                  else
                    CompositedTransformTarget(
                      link: layerLink2,
                      child: RawAutocomplete<String>(
                        textEditingController: otherAccountController,
                        focusNode: otherAccountFocusNode2,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return uniqueAccounts;
                          }
                          return uniqueAccounts.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'الحساب المقابل',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (String value) {
                              onFieldSubmitted();
                            },
                          );
                        },
                        optionsViewBuilder: (BuildContext context,
                            AutocompleteOnSelected<String> onSelected,
                            Iterable<String> options) {
                          return CompositedTransformFollower(
                            link: layerLink2,
                            showWhenUnlinked: false,
                            targetAnchor: Alignment.bottomLeft,
                            followerAnchor: Alignment.topLeft,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 200,
                                    maxWidth: 400,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(option),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
                      if (double.tryParse(value!) == null)
                        return 'الرجاء إدخال رقم صحيح';
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

                  // Determine the effective type and otherAccount
                  String effectiveType = transferType!;
                  String otherAccount = '';
                  String otherAccountCategory = 'أخرى';

                  if (transferType == 'مصروفات') {
                    effectiveType = 'سحب';
                    otherAccount = otherAccountController.text;
                    otherAccountCategory = 'المصروفات';
                  } else if (transferType == 'مبيعات') {
                    effectiveType = 'إيداع';
                    otherAccount = otherAccountController.text;
                    otherAccountCategory = 'ايرادات';
                  } else if (transferType == 'إيداع' || transferType == 'سحب') {
                    otherAccount = otherAccountController.text;
                    otherAccountCategory = selectedOtherAccountCategory!.label;
                  } else if (transferType == 'تحصيلات من السائق') {
                    // This will be handled as إيداع to the bank account
                    effectiveType = 'إيداع';
                    otherAccount = selectedCustomer ?? '';
                    otherAccountCategory = 'جاري العملاء';
                  } else if (transferType == 'سداد للزبون') {
                    effectiveType = 'سحب';
                    otherAccount = selectedCustomer ?? '';
                    otherAccountCategory = 'جاري العملاء';
                  } else if (transferType == 'تحويل') {
                    // Two entries: سحب from source, إيداع to dest
                    appProvider.addTransfer({
                      'type': 'سحب',
                      'account': selectedAccount,
                      'otherAccount': selectedOtherBankAccount,
                      'otherAccountCategory': 'النقديه',
                      'amount': amount,
                      'notes': 'تحويل إلى $selectedOtherBankAccount - $notes',
                      'date': now,
                    });
                    appProvider.addTransfer({
                      'type': 'إيداع',
                      'account': selectedOtherBankAccount,
                      'otherAccount': selectedAccount,
                      'otherAccountCategory': 'النقديه',
                      'amount': amount,
                      'notes': 'تحويل من $selectedAccount - $notes',
                      'date': now,
                    });
                    Navigator.pop(context);
                    return;
                  } else {
                    otherAccount = otherAccountController.text;
                  }

                  appProvider.addTransfer({
                    'type': effectiveType,
                    'account': selectedAccount,
                    'otherAccount': otherAccount,
                    'otherAccountCategory': otherAccountCategory,
                    'amount': amount,
                    'notes': notes,
                    'date': now,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferBetweenAccountsDialog(
      BuildContext context, AppProvider appProvider) {
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
                  items: appProvider.bankAccounts
                      .map((account) => DropdownMenuItem<String>(
                            value: account,
                            child: Text(account),
                          ))
                      .toList(),
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
                  items: appProvider.bankAccounts
                      .map((account) => DropdownMenuItem<String>(
                            value: account,
                            child: Text(account),
                          ))
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      toAccount = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'مطلوب';
                    if (value == fromAccount)
                      return 'لا يمكن التحويل إلى نفس الحساب';
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
                    if (double.tryParse(value!) == null)
                      return 'الرجاء إدخال رقم صحيح';
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
                  'otherAccount': toAccount,
                  'otherAccountCategory': 'النقديه',
                  'amount': amount,
                  'notes': 'تحويل إلى $toAccount - $notes',
                  'date': now,
                });

                // Add deposit to destination account
                appProvider.addTransfer({
                  'type': 'إيداع',
                  'account': toAccount,
                  'otherAccount': fromAccount,
                  'otherAccountCategory': 'النقديه',
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
                            isSelected: [
                              _selectedTabIndex == 0,
                              _selectedTabIndex == 1,
                              _selectedTabIndex == 2,
                            ],
                            onPressed: (index) {
                              setState(() {
                                _selectedTabIndex = index;
                                if (_selectedTabIndex == 1) {
                                  // Reset filters when switching to cash accounts
                                  _fromDate = null;
                                  _toDate = null;
                                  _selectedAccountFilter = null;
                                }
                              });
                            },
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.book),
                                    SizedBox(width: 8),
                                    Text('اليومية'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance),
                                    SizedBox(width: 8),
                                    Text('الحسابات النقديه'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics),
                                    SizedBox(width: 8),
                                    Text('قائمة الدخل'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (_selectedTabIndex == 0) ...[
                              // Print button for transfers
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _printTransfersReport(appProvider),
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
                              onPressed: () =>
                                  _showTransferBetweenAccountsDialog(
                                      context, appProvider),
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('التحويل بين الحسابات'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_selectedTabIndex == 1)
                              FilledButton.icon(
                                onPressed: () => _showAddAccountNameDialog(
                                    context, appProvider),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'إضافة حساب نقدي',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else
                              FilledButton.icon(
                                onPressed: () => _showAddTransferDialog(
                                    context, appProvider),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'إضافة قيد',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Date and account filters for journal view
                    if (_selectedTabIndex == 0 || _selectedTabIndex == 2) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.filter_list,
                                      color: Color(0xFFDC2626)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'تصفية:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _selectDate(context, true),
                                            icon: Icon(
                                              Icons.calendar_today,
                                              color: _fromDate != null
                                                  ? Color(0xFFDC2626)
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              _fromDate != null
                                                  ? 'من: ${DateFormat('yyyy/MM/dd').format(_fromDate!)}'
                                                  : 'من تاريخ',
                                              style: TextStyle(
                                                color: _fromDate != null
                                                    ? Color(0xFFDC2626)
                                                    : Colors.grey.shade700,
                                                fontWeight: _fromDate != null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _fromDate != null
                                                  ? Color(0xFFDC2626)
                                                      .withOpacity(0.1)
                                                  : Colors.grey.shade50,
                                              side: BorderSide(
                                                color: _fromDate != null
                                                    ? Color(0xFFDC2626)
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _selectDate(context, false),
                                            icon: Icon(
                                              Icons.calendar_today,
                                              color: _toDate != null
                                                  ? Color(0xFFDC2626)
                                                  : Colors.grey,
                                            ),
                                            label: Text(
                                              _toDate != null
                                                  ? 'إلى: ${DateFormat('yyyy/MM/dd').format(_toDate!)}'
                                                  : 'إلى تاريخ',
                                              style: TextStyle(
                                                color: _toDate != null
                                                    ? Color(0xFFDC2626)
                                                    : Colors.grey.shade700,
                                                fontWeight: _toDate != null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _toDate != null
                                                  ? Color(0xFFDC2626)
                                                      .withOpacity(0.1)
                                                  : Colors.grey.shade50,
                                              side: BorderSide(
                                                color: _toDate != null
                                                    ? Color(0xFFDC2626)
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Quick date filters: This Month, This Year
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              final now = DateTime.now();
                                              _fromDate = DateTime(now.year, now.month, 1);
                                              // We need to account for next month's 1st day - 1 day
                                              _toDate = DateTime(now.year, now.month + 1, 0); 
                                            });
                                          },
                                          child: const Text('هذا الشهر'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey.shade100,
                                            foregroundColor: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              final now = DateTime.now();
                                              _fromDate = DateTime(now.year, 1, 1);
                                              _toDate = DateTime(now.year, 12, 31);
                                            });
                                          },
                                          child: const Text('هذا العام'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey.shade100,
                                            foregroundColor: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Account filter dropdown
                                        Builder(builder: (context) {
                                          // Get all unique accounts from transfers (from and to)
                                          final Set<String> accountsSet = {};
                                          for (var transfer
                                              in appProvider.transfers) {
                                            if (transfer.account
                                                .trim()
                                                .isNotEmpty) {
                                              accountsSet.add(transfer.account);
                                            }
                                            if (transfer.otherAccount
                                                .trim()
                                                .isNotEmpty) {
                                              accountsSet
                                                  .add(transfer.otherAccount);
                                            }
                                          }

                                          // Fallback to bank Accounts
                                          for (var account
                                              in appProvider.bankAccounts) {
                                            if (account.trim().isNotEmpty)
                                              accountsSet.add(account);
                                          }

                                          final List<String> uniqueAccounts =
                                              accountsSet.toList()..sort();
                                          // Ensure current selection is valid
                                          if (_selectedAccountFilter != null &&
                                              !uniqueAccounts.contains(
                                                  _selectedAccountFilter)) {
                                            // We don't change state during build, but we bypass the invalid value on UI and reset async
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {
                                                  _selectedAccountFilter = null;
                                                });
                                              }
                                            });
                                          }

                                          // To avoid building with invalid value in the meantime
                                          final currentValue =
                                              uniqueAccounts.contains(
                                                      _selectedAccountFilter)
                                                  ? _selectedAccountFilter
                                                  : null;

                                          return SizedBox(
                                            width: 250,
                                            child: DropdownButtonFormField2<
                                                String>(
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                labelText: 'اختر حساب',
                                                border:
                                                    const OutlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                                suffixIcon: currentValue != null
                                                    ? IconButton(
                                                        icon: const Icon(
                                                            Icons.clear,
                                                            size: 18),
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedAccountFilter =
                                                                null;
                                                          });
                                                        },
                                                      )
                                                    : null,
                                              ),
                                              value: currentValue,
                                              items: uniqueAccounts
                                                  .map((account) =>
                                                      DropdownMenuItem<String>(
                                                        value: account,
                                                        child: Text(account,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis),
                                                      ))
                                                  .toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedAccountFilter =
                                                      value;
                                                });
                                              },
                                              dropdownSearchData:
                                                  DropdownSearchData(
                                                searchController:
                                                    _accountSearchController,
                                                searchInnerWidgetHeight: 50,
                                                searchInnerWidget: Container(
                                                  height: 50,
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 8,
                                                    bottom: 4,
                                                    right: 8,
                                                    left: 8,
                                                  ),
                                                  child: TextFormField(
                                                    expands: true,
                                                    maxLines: null,
                                                    controller:
                                                        _accountSearchController,
                                                    decoration: InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                      hintText:
                                                          'البحث عن حساب...',
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                searchMatchFn:
                                                    (item, searchValue) {
                                                  return item.value
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(searchValue
                                                          .toLowerCase());
                                                },
                                              ),
                                              onMenuStateChange: (isOpen) {
                                                if (!isOpen) {
                                                  _accountSearchController
                                                      .clear();
                                                }
                                              },
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        if (_fromDate != null ||
                                            _toDate != null ||
                                            _selectedAccountFilter != null)
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _fromDate = null;
                                                _toDate = null;
                                                _selectedAccountFilter = null;
                                              });
                                            },
                                            icon: const Icon(Icons.clear_all),
                                            tooltip: 'مسح جميع التصفيات',
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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
                  child: _selectedTabIndex == 1
                      ? _buildAccountsTable(appProvider)
                      : (_selectedTabIndex == 2
                          ? _buildIncomeStatement(appProvider)
                          : _buildTransfersTable(appProvider)),
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
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowHeight: 56,
            dataRowHeight: 72,
            headingRowColor: MaterialStateColor.resolveWith(
              (states) =>
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
              columns: const [
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.account_balance, size: 16),
                      SizedBox(width: 4),
                      Text('اسم الحساب',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16),
                      SizedBox(width: 4),
                      Text('الرصيد',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 4),
                      Text('تعديل',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      Icon(Icons.delete, size: 16),
                      SizedBox(width: 4),
                      Text('حذف',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: Text(
                          account,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: balance >= 0
                              ? Color(0xFFDC2626).withOpacity(0.1)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: balance >= 0
                                ? Color(0xFFDC2626).withOpacity(0.3)
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          '${balance.toStringAsFixed(2)} JOD',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balance >= 0
                                ? Color(0xFFDC2626)
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Color(0xFFDC2626)),
                        onPressed: () {
                          // TODO: Implement edit functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('سيتم إضافة وظيفة التعديل قريباً')),
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
                          _showDeleteConfirmation(
                              context, account, appProvider);
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
      );
  }

  void _showDeleteConfirmation(
      BuildContext context, String account, AppProvider appProvider) {
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

  Widget _buildIncomeStatement(AppProvider appProvider) {
    final transfers = _getFilteredTransfers(appProvider);
    
    Map<String, double> revenues = {};
    double totalRevenues = 0;
    
    Map<String, double> expenses = {};
    double totalExpenses = 0;
    
    for (var t in transfers) {
      if (t.otherAccountCategory == AccountCategory.revenues) {
        double amount = t.type == 'إيداع' ? t.amount : -t.amount;
        revenues[t.otherAccount] = (revenues[t.otherAccount] ?? 0) + amount;
        totalRevenues += amount;
      } else if (t.otherAccountCategory == AccountCategory.expenses) {
        double amount = t.type == 'سحب' ? t.amount : -t.amount;
        expenses[t.otherAccount] = (expenses[t.otherAccount] ?? 0) + amount;
        totalExpenses += amount;
      }
    }

    double netIncome = totalRevenues - totalExpenses;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قائمة الدخل',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_fromDate != null && _toDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'عن الفترة من ${DateFormat('yyyy/MM/dd').format(_fromDate!)} إلى ${DateFormat('yyyy/MM/dd').format(_toDate!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              
              // Revenues Section
              Text(
                'الإيرادات:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (revenues.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('لا توجد إيرادات مسجلة', style: TextStyle(color: Colors.grey)),
                )
              else
                ...revenues.entries.map((e) => _buildIncomeRow(e.key, e.value)),
              const Divider(),
              _buildIncomeRow('إجمالي الإيرادات', totalRevenues, isTotal: true),
              
              const SizedBox(height: 32),
              
              // Expenses Section
              Text(
                'يخصم منه: المصروفات:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('لا توجد مصروفات مسجلة', style: TextStyle(color: Colors.grey)),
                )
              else
                ...expenses.entries.map((e) => _buildIncomeRow(e.key, e.value)),
              const Divider(),
              _buildIncomeRow('إجمالي المصروفات', totalExpenses, isTotal: true),
              
              const SizedBox(height: 48),
              const Divider(thickness: 2),
              
              // Net Income Section
              Container(
                decoration: BoxDecoration(
                  color: netIncome >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: netIncome >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: _buildIncomeRow(
                  netIncome >= 0 ? 'صافي الدخل (الربح)' : 'صافي الدخل (الخسارة)',
                  netIncome,
                  isTotal: true,
                  isNet: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeRow(String label, double amount, {bool isTotal = false, bool isNet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 12.0 : 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isNet ? 20 : (isTotal ? 16 : 15),
              fontWeight: (isTotal || isNet) ? FontWeight.bold : FontWeight.normal,
              color: isNet 
                  ? (amount >= 0 ? Colors.green.shade800 : Colors.red.shade800) 
                  : Colors.black87,
            ),
          ),
          Text(
            '${amount.abs().toStringAsFixed(2)} JOD',
            style: TextStyle(
              fontSize: isNet ? 20 : (isTotal ? 16 : 15),
              fontWeight: (isTotal || isNet) ? FontWeight.bold : FontWeight.normal,
              color: isNet 
                  ? (amount >= 0 ? Colors.green.shade800 : Colors.red.shade800) 
                  : (isTotal ? Colors.black87 : Colors.black54),
            ),
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
                  'لا توجد قيود',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'قم بإضافة قيد جديد أو تعديل التصفية',
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
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
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
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      headingRowHeight: 56,
                      dataRowHeight: 72,
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.tag, size: 18),
                                SizedBox(width: 6),
                                Text('رقم القيد',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.category, size: 18),
                                SizedBox(width: 6),
                                Text('نوع العملية',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.arrow_back, size: 18),
                                SizedBox(width: 6),
                                Text('من حساب',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.arrow_forward, size: 18),
                                SizedBox(width: 6),
                                Text('إلى حساب',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.monetization_on, size: 18),
                                SizedBox(width: 6),
                                Text('المبلغ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                SizedBox(width: 6),
                                Text('التاريخ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.note, size: 18),
                                SizedBox(width: 6),
                                Text('الملاحظات',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 6),
                                Text('تعديل',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.delete, size: 18),
                                SizedBox(width: 6),
                                Text('حذف',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
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
                                  width: 80,
                                  child: Tooltip(
                                    message: transfer.id,
                                    child: Text(
                                      transfer.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 90,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: transfer.type == 'إيداع'
                                          ? Color(0xFFDC2626)
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          transfer.type == 'إيداع'
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          transfer.type == 'إيداع'
                                              ? 'إيداع'
                                              : 'سحب',
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
                                    transfer.fromAccountDisplay,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 120,
                                  child: Text(
                                    transfer.toAccountDisplay,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
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
                                      color: transfer.type == 'إيداع'
                                          ? Color(0xFFDC2626)
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 120,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('yyyy/MM/dd')
                                            .format(transfer.date),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        DateFormat('HH:mm')
                                            .format(transfer.date),
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
                                  constraints:
                                      const BoxConstraints(maxWidth: 180),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transfer.notes.isNotEmpty
                                            ? transfer.notes
                                            : '-',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: transfer.notes.isNotEmpty
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      if (transfer.relatedTo != null && transfer.relatedTo!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'متعلق بـ: ${transfer.relatedTo}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 60,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Color(0xFFDC2626), size: 20),
                                    onPressed: () {
                                      // TODO: Implement edit functionality
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'سيتم إضافة وظيفة التعديل قريباً')),
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      _showDeleteTransferConfirmation(
                                          context, transfer, appProvider);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, IconData icon, Color color) {
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

  void _showDeleteTransferConfirmation(
      BuildContext context, Transfer transfer, AppProvider appProvider) {
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
                  Text(
                      'التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(transfer.date)}'),
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
