import 'dart:typed_data';


import '../../main.dart';
import '../../models/Shipment.dart';
import '../ManageShipments/widget/CustomScrollbar.dart';
import '../../shared/PrintHelper.dart';
import '../../shared/firebaseHelper.dart';
import 'package:flutter/material.dart';
import 'dart:math' show max;
import '../../shared/ExcelImportHandler.dart';
import '../../utils/file_handler.dart';
import '../../models/UserAccount.dart';
import 'PaymentSelectionDialog.dart';
import 'ShipmentReceiptDialog.dart';
import 'ShipmentPreviewDialog.dart';
import '../ManageShipments/ManageShipmentsScreen/BxPaymentDialog.dart';

class Accounting extends StatefulWidget {
  final int selectedIndex;
  const Accounting({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<Accounting> createState() => _AccountingState();
}

class _AccountingState extends State<Accounting> {
  List<UserAccount> userAccounts = [];
  Set<String> selectedUserIds = {};
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  Future<bool> _handleNegativeAccount(UserAccount account) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('رصيد الحساب بالسالب', textAlign: TextAlign.right),
          content: Text('قيمة حساب الزبون ${account.client} بالسالب (${account.getAmountToPay().toStringAsFixed(2)}). ماذا تريد أن تفعل؟', textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('انتظار طرود أخرى'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تحويلها لواصل bx'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return false;
      bool? paymentResult = await showDialog<bool>(
        context: context,
        builder: (context) => BxPaymentDialog(userAccount: account),
      );
      return paymentResult == true;
    }
    return false;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedUserIds =
            userAccounts.map((shipment) => shipment.client).toSet();
      } else {
        selectedUserIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SizedBox(
          width: max(MediaQuery.of(context).size.width, 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopActions(),
              _buildTableHeader(),
              Expanded(
                child: CustomScrollbar(
                  verticalScrollController: _verticalScrollController,
                  horizontalScrollController: _horizontalScrollController,
                  child: Container(
                    width: max(MediaQuery.of(context).size.width, 1200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: StreamBuilder<List<Shipment>>(
                      stream: FirebaseHelper()
                          .getCustomersUserAccount(widget.selectedIndex),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          print(snapshot.error);
                          return Text('Error: ${snapshot.error}');
                        }

                        List<UserAccount> userAccount = [];
                        List<Shipment> shipments = snapshot.data ?? [];

                        // Group shipments by userId using a Map
                        Map<String, List<Shipment>> shipmentsMap = {};

                        for (var shipment in shipments) {
                          if (shipment.userId != null) {
                            if (!shipmentsMap.containsKey(shipment.userId)) {
                              shipmentsMap[shipment.userId!] = [];
                            }
                            shipmentsMap[shipment.userId]!.add(shipment);
                          }
                        }

                        // Convert each group of shipments to UserAccount
                        for (var shipmentsList in shipmentsMap.values) {
                          userAccount
                              .add(UserAccount.fromShipments(shipmentsList));
                        }

                        userAccounts = userAccount;
                        return DataTable(
                          columns: _createColumns(),
                          rows: _createRows(),
                          columnSpacing: 15,
                          horizontalMargin: 10,
                          headingRowHeight: 40,
                          dataRowHeight: 45,
                          border: TableBorder(
                            horizontalInside:
                                BorderSide(color: Colors.grey.shade300),
                            verticalInside:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _buildTableFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: [
          if (selectedUserIds.isNotEmpty)
            Text(
              'تم تحديد ${selectedUserIds.length} عنصر',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (widget.selectedIndex == 6) ...[
            Text(
              'استلام التحصيلات',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildActionButton('إستلام مجموعة طرود من سائق', true,
                onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const ShipmentReceiptDialog();
                },
              );
            }),
 
          ],
          if (widget.selectedIndex == 7)
            Text(
              'التحصيلات المفرزة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (widget.selectedIndex == 8)
            Text(
              'التحصيلات المصدرة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          if (selectedUserIds.isNotEmpty) ...[
            _buildActionButton(
              'تصدير إلى Excel',
              true,
              onPressed: () {
                _exportToExcel();
              },
              color: Color(0xFFDC2626),
            ),
            _buildActionButton(
              'تصدير إلى ${widget.selectedIndex == 6 ? "مفرزه" : widget.selectedIndex == 7 ? "مصدرة" : "مصدرة"}',
              true,
              onPressed: () async {
                final selectedAccounts = userAccounts
                    .where(
                        (account) => selectedUserIds.contains(account.client))
                    .toList();
                
                bool allExported = true;
                for (var account in selectedAccounts) {
                  if (account.getAmountToPay() < 0) {
                    bool shouldExport = await _handleNegativeAccount(account);
                    if (!shouldExport) {
                      allExported = false;
                      continue;
                    }
                  }

                  if (widget.selectedIndex == 6) {
                    FirebaseHelper.updatePaymentStatus(account, "sorted");
                  } else if (widget.selectedIndex == 7) {
                    FirebaseHelper.updatePaymentStatus(account, "exported");
                  } else if (widget.selectedIndex == 8) {
                    FirebaseHelper.updatePaymentStatus(account, "exported");
                  }
                }
                if (mounted && allExported && selectedAccounts.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تصدير البيانات بنجاح'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, bool isActive,
      {void Function()? onPressed, Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? (isActive ? primary : Colors.white),
          foregroundColor: color != null
              ? Colors.white
              : (isActive ? Colors.white : Colors.black),
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: constraints.maxWidth > 600 ? 100 : 80,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('عامل التصفية'),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'بحث...',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<DataColumn> _createColumns() {
    final columns = [
      '', // First column for checkboxes
      'اسم الزبون',
      'عنوان الزبون',
      'مجموع\nالطرود',
      'التحصيل\nشامل التوصيل',
      'عدد الطرود',
      'نوع الدفع',
      'رسوم\nالتوصيل',
      'إجمالي\nالمبلغ',
      'إجراءات',
    ];

    return columns
        .map((String column) => DataColumn(
              label: Expanded(
                child: column.isEmpty
                    ? Checkbox(
                        value: selectedUserIds.length == userAccounts.length &&
                            userAccounts.isNotEmpty,
                        onChanged: _toggleSelectAll,
                      )
                    : Text(
                        column,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ))
        .toList();
  }

  List<DataRow> _createRows() {
    return userAccounts.map((shipment) {
      return DataRow(
        cells: [
          DataCell(
            Checkbox(
              value: selectedUserIds.contains(shipment.client),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    selectedUserIds.add(shipment.client);
                  } else {
                    selectedUserIds.remove(shipment.client);
                  }
                });
              },
            ),
          ),
          DataCell(Text(shipment.client)),
          DataCell(Text(shipment.location ?? '')),
          DataCell(Text(shipment.totalParcels.toStringAsFixed(2))),
          DataCell(Text(shipment.totalAmount.toStringAsFixed(2))),
          DataCell(Text(shipment.assignedOrders.toString())),
          DataCell(Text(shipment.paymentType ?? '')),
          DataCell(Text(shipment.servicesFees.toStringAsFixed(2))),
          DataCell(Text((shipment.totalAmount.toDouble() -
                  shipment.servicesFees.toDouble())
              .toStringAsFixed(2))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.preview, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ShipmentPreviewDialog(
                      selectedStatus: widget.selectedIndex == 6
                          ? "sorted"
                          : widget.selectedIndex == 7
                              ? "exported"
                              : null,
                      userAccount: shipment,
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Refresh the data if needed
                      setState(() {});
                    }
                  });
                },
                padding: EdgeInsets.zero,
                tooltip: 'معاينة الشحنات',
              ),
              if (widget.selectedIndex == 6)
                IconButton(
                  icon: const Icon(Icons.inventory, size: 20),
                  onPressed: () async {
                    if (shipment.getAmountToPay() < 0) {
                      bool shouldExport = await _handleNegativeAccount(shipment);
                      if (!shouldExport) return;
                    }
                    FirebaseHelper.updatePaymentStatus(shipment, "sorted");
                  },
                  padding: EdgeInsets.zero,
                ),
              if (widget.selectedIndex == 7)
                IconButton(
                  icon: const Icon(Icons.send, size: 20),
                  onPressed: () async {
                    if (shipment.getAmountToPay() < 0) {
                      bool shouldExport = await _handleNegativeAccount(shipment);
                      if (!shouldExport) return;
                    }
                    FirebaseHelper.updatePaymentStatus(shipment, "exported");
                  },
                  padding: EdgeInsets.zero,
                ),
              if (widget.selectedIndex == 8)
                IconButton(
                  icon: const Icon(Icons.payment, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PaymentSelectionDialog(
                        userAccount: shipment,
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: () {
                  PrintHandler().printUserAccountDocument(shipment);
                },
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                onPressed: () {
                  PrintHandler()
                      .printUserAccountDocument(shipment, isDownload: true);
                },
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.message, size: 20),
                onPressed: () {
                  PrintHandler().printUserAccountDocument(shipment,
                      isDownload: true, isMessage: true);
                },
                padding: EdgeInsets.zero,
              ),
            ],
          )),
        ],
      );
    }).toList();
  }

  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 16,
            children: [
              Text('إجمالي المبالغ: Jod ${_calculateTotal()}'),
              Text('مجموع رسوم التوصيل: Jod ${_calculateTotalServiceFees()}'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {},
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text('1'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            children: [
              Text('عدد الزبائن: ${calculateTotalCustomers()}'),
              Text('عدد الطرود: ${_calculateTotalParcels()}'),
            ],
          ),
        ],
      ),
    );
  }

  calculateTotalCustomers() {
    final selectedAccounts = userAccounts
        .where((account) => selectedUserIds.contains(account.client))
        .toList();
    return selectedAccounts.length;
  }

  double _calculateTotal() {
    final selectedAccounts = userAccounts
        .where((account) => selectedUserIds.contains(account.client))
        .toList();

    return selectedAccounts.fold(
        0, (sum, shipment) => sum + shipment.totalAmount);
  }

  int _calculateTotalParcels() {
    final selectedAccounts = userAccounts
        .where((account) => selectedUserIds.contains(account.client))
        .toList();
    return selectedAccounts.fold(
        0, (sum, account) => sum + account.totalParcels);
  }

  double _calculateTotalServiceFees() {
    final selectedAccounts = userAccounts
        .where((account) => selectedUserIds.contains(account.client))
        .toList();
    return selectedAccounts.fold(
        0, (sum, account) => sum + account.servicesFees);
  }

  void _exportToExcel() async {
    if (selectedUserIds.isEmpty) return;

    try {
      // Filter userAccounts based on selected IDs
      final selectedAccounts = userAccounts
          .where((account) => selectedUserIds.contains(account.client))
          .toList();

      // Export to Excel
      final excelHandler = ExcelImportHandler();
      final excelData =
          await excelHandler.exportAccountsToExcel(selectedAccounts);

      // Download the Excel file
      _downloadExcel(excelData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير البيانات بنجاح'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
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

  void _downloadExcel(Uint8List excelBytes) async {
    try {
      await FileHandler.downloadFile(excelBytes, 'accounting_report.xlsx');
    } catch (e) {
      // Show error dialog or snackbar
      print('Failed to download file: $e');
    }
  }
}