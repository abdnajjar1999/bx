import '../../main.dart';
import '../../models/Driver.dart';
import '../ManageShipments/widget/CustomScrollbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/Expense.dart';
import '../../shared/appProvider.dart';
import '../../shared/ExcelImportHandler.dart';
import '../../shared/PrintHelper.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  void _showAddExpenseDialog(BuildContext context, AppProvider appProvider) {
    if (appProvider.expenseTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أنواع مصروفات. الرجاء إضافة نوع مصروف أولاً.'),
          backgroundColor: primary,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? selectedType;
    String? selectedAccount;
    String? selectedBeneficiary;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    Driver? selectedDriver;

    // Get unique drivers with non-null usernames
    final validDrivers = appProvider.drivers
        .where(
            (driver) => driver.username != null && driver.username!.isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة مصروف'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'نوع المستفيد',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedBeneficiary,
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'الموظفين',
                        child: Text('الموظفين'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'الشركاء',
                        child: Text('الشركاء'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedBeneficiary = value;
                        selectedDriver = null;
                      });
                    },
                    validator: (value) => value == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  if (selectedBeneficiary == 'الموظفين' &&
                      validDrivers.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'المستفيد',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDriver?.username,
                      items: validDrivers
                          .map((driver) => DropdownMenuItem<String>(
                                value: driver.username,
                                child: Text(driver.username ?? ''),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedDriver = validDrivers.firstWhere(
                            (driver) => driver.username == value,
                            orElse: () => validDrivers.first,
                          );
                        });
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'نوع المصروف',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedType,
                    items: appProvider.expenseTypes
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
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
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'القيمة',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
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
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  String expenseId = await appProvider.addExpense({
                    'type': selectedType,
                    'beneficiary':
                        selectedDriver?.username ?? selectedBeneficiary ?? '',
                    'amount': double.parse(amountController.text),
                    'notes': notesController.text,
                    'branch': KcompanyName,
                  });
                  appProvider.addTransfer({
                    'type': "سحب",
                    'account': selectedAccount,
                    'otherAccount': selectedType ?? 'مصروف غير معروف',
                    'otherAccountCategory': 'المصروفات',
                    'amount': double.parse(amountController.text),
                    'notes': "مصروف $selectedType",
                    'date': DateTime.now().toIso8601String(),
                    'relatedTo': expenseId,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseTypeDialog(
      BuildContext context, AppProvider appProvider) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نوع مصروف'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'الاسم'),
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
                appProvider.addExpenseType(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _exportToExcel(List<Expense> expenses) async {
    try {
      // Export to Excel
      final excelHandler = ExcelImportHandler();
      final excelData = await excelHandler.exportExpensesToExcel(expenses);

      // Show file picker to select save location
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ تقرير المصروفات',
        fileName:
            'expenses_report_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        // Save the file
        File(outputFile).writeAsBytesSync(excelData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تصدير البيانات بنجاح'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditExpenseDialog(
      BuildContext context, AppProvider appProvider, Expense expense) {
    if (appProvider.expenseTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أنواع مصروفات. الرجاء إضافة نوع مصروف أولاً.'),
          backgroundColor: primary,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String? selectedType = expense.type;
    String? selectedBeneficiary =
        expense.beneficiary.contains('الموظفين') ? 'الموظفين' : 'الشركاء';
    final amountController =
        TextEditingController(text: expense.amount.toString());
    final notesController = TextEditingController(text: expense.notes);

    // Get unique drivers with non-null usernames
    final validDrivers = appProvider.drivers
        .where(
            (driver) => driver.username != null && driver.username!.isNotEmpty)
        .toList();

    // Find the matching driver or set to null if not found
    Driver? selectedDriver;
    try {
      selectedDriver = validDrivers.firstWhere(
        (driver) => driver.username == expense.beneficiary,
      );
    } catch (e) {
      selectedDriver = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل مصروف'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'نوع المستفيد',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedBeneficiary,
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'الموظفين',
                        child: Text('الموظفين'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'الشركاء',
                        child: Text('الشركاء'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedBeneficiary = value;
                        selectedDriver = null;
                      });
                    },
                    validator: (value) => value == null ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  if (selectedBeneficiary == 'الموظفين' &&
                      validDrivers.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'المستفيد',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDriver?.username,
                      items: validDrivers
                          .map((driver) => DropdownMenuItem<String>(
                                value: driver.username,
                                child: Text(driver.username ?? ''),
                              ))
                          .toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedDriver = validDrivers.firstWhere(
                            (driver) => driver.username == value,
                            orElse: () => validDrivers.first,
                          );
                        });
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'نوع المصروف',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedType,
                    items: appProvider.expenseTypes
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'القيمة',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'مطلوب' : null,
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
                  appProvider.updateExpense(
                    expense.id,
                    {
                      'type': selectedType,
                      'beneficiary':
                          selectedDriver?.username ?? selectedBeneficiary ?? '',
                      'amount': double.parse(amountController.text),
                      'notes': notesController.text,
                      'branch': KcompanyName,
                      'modificationDate': DateTime.now().toIso8601String(),
                    },
                  );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        double totalExpenses = appProvider.expenses
            .fold(0, (sum, expense) => sum + expense.amount);

        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المصروفات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            final printHandler = PrintHandler();
                            printHandler
                                .printExpensesReport(appProvider.expenses);
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('تصدير إلى PDF'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _exportToExcel(appProvider.expenses),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('تصدير إلى Excel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () =>
                              _showAddExpenseDialog(context, appProvider),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('إضافة مصروف',
                              style: TextStyle(color: Colors.white)),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () =>
                              _showAddExpenseTypeDialog(context, appProvider),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('نوع مصروف',
                              style: TextStyle(color: Colors.white)),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollbar(
                  verticalScrollController: _verticalScrollController,
                  horizontalScrollController: _horizontalScrollController,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('نوع المصروف')),
                      DataColumn(label: Text('اسم المستخدم')),
                      DataColumn(label: Text('المستفيد')),
                      DataColumn(label: Text('المستفيد (شريك)')),
                      DataColumn(label: Text('الفرع')),
                      DataColumn(label: Text('القيمة')),
                      DataColumn(label: Text('تاريخ الإنشاء')),
                      DataColumn(label: Text('تاريخ اخر تعديل')),
                      DataColumn(label: Text('ملاحظات')),
                      DataColumn(label: Text('المرفقات')),
                      DataColumn(label: Text('طباعة')),
                      DataColumn(label: Text('الحركات')),
                      DataColumn(label: Text('تعديل')),
                    ],
                    rows: appProvider.expenses.map((expense) {
                      return DataRow(
                        cells: [
                          DataCell(Text(expense.id)),
                          DataCell(Text(expense.type)),
                          DataCell(Text(expense.userName)),
                          DataCell(Text(expense.beneficiary)),
                          DataCell(Text(expense.partner ?? '')),
                          DataCell(Text(expense.branch)),
                          DataCell(Text(NumberFormat('#,##0.0', 'ar')
                              .format(expense.amount))),
                          DataCell(Text(DateFormat('yyyy/MM/dd')
                              .format(expense.creationDate))),
                          DataCell(Text(DateFormat('yyyy/MM/dd')
                              .format(expense.modificationDate))),
                          DataCell(Text(expense.notes)),
                          DataCell(IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {},
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.print),
                            onPressed: () {},
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.history),
                            onPressed: () {},
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditExpenseDialog(
                                context, appProvider, expense),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'مجموع المصروفات: ${NumberFormat('#,##0.0', 'ar').format(totalExpenses)} دينار',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
