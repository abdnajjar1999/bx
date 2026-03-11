import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/firebaseHelper.dart';
import '../../utils/file_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../shared/PrintHelper.dart';
import '../../main.dart';

import '../../models/customer.dart';
import '../../models/UserAccount.dart';
import '../dashboard/header/header.dart';

class ExportedInvoices extends StatefulWidget {
  const ExportedInvoices({Key? key}) : super(key: key);

  @override
  State<ExportedInvoices> createState() => _ExportedInvoicesState();
}

class _ExportedInvoicesState extends State<ExportedInvoices> {
  List<UserAccount> userAccounts = [];
  List<UserAccount> filteredUserAccounts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUserAccounts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUserAccounts() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredUserAccounts = userAccounts;
      } else {
        filteredUserAccounts = userAccounts.where((account) {
          return account.client.toLowerCase().contains(query) ||
              (account.location?.toLowerCase().contains(query) ?? false) ||
              (account.branch?.toLowerCase().contains(query) ?? false) ||
              (account.userType?.toLowerCase().contains(query) ?? false) ||
              (account.paymentType?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTableHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: StreamBuilder<List<UserAccount>>(
                      stream: FirebaseHelper.exportedInvoicesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        userAccounts = snapshot.data ?? [];
                        
                        // Sort by paymentDate in descending order (newest first)
                        userAccounts.sort((a, b) {
                          if (a.paymentDate == null && b.paymentDate == null) return 0;
                          if (a.paymentDate == null) return 1;
                          if (b.paymentDate == null) return -1;
                          return b.paymentDate!.compareTo(a.paymentDate!);
                        });
                        
                        // Apply search filter
                        final query = _searchController.text.toLowerCase();
                        if (query.isEmpty) {
                          filteredUserAccounts = userAccounts;
                        } else {
                          filteredUserAccounts = userAccounts.where((account) {
                            return account.client.toLowerCase().contains(query) ||
                                (account.location?.toLowerCase().contains(query) ?? false) ||
                                (account.branch?.toLowerCase().contains(query) ?? false) ||
                                (account.userType?.toLowerCase().contains(query) ?? false) ||
                                (account.paymentType?.toLowerCase().contains(query) ?? false);
                          }).toList();
                        }

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
                      }),
                ),
              ),
            ),
            _buildTableFooter(),
          ],
        ),
      ),
    );
  }




  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
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
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Center(child: Text('عامل التصفية')),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _searchController,
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
  
        ],
      ),
    );
  }

  List<DataColumn> _createColumns() {
    final columns = [
      '',
      'اسم الزبون',
      'عنوان الزبون',
      'فرع الزبون',
      'تاريخ الدفع',
      'مجموع\nالتكاليف',
      'مجموع\nالتحصيلات',
      'عدد الطرود\nالمدورة',
      'تصنيف\nالمواطن',
      'نوع الدفع',
      'رسوم\nالخدمات',
      'إجمالي\nالمبلغ',
      'إجراءات',
    ];

    return columns
        .map((String column) => DataColumn(
              label: column.isEmpty
                  ? Checkbox(value: false, onChanged: (bool? value) {})
                  : Text(column, textAlign: TextAlign.center),
            ))
        .toList();
  }

  List<DataRow> _createRows() {
    return filteredUserAccounts.map((shipment) {
      return DataRow(
        cells: [
          DataCell(Checkbox(value: false, onChanged: (bool? value) {})),
          DataCell(Text(shipment.client)),
          DataCell(Text(shipment.location ?? '')),
          DataCell(Text(shipment.branch ?? '')),
          DataCell(Text(shipment.paymentDate != null
              ? '${shipment.paymentDate!.day}/${shipment.paymentDate!.month}/${shipment.paymentDate!.year}'
              : '')),
          DataCell(Text(shipment.totalParcels.toString())),
          DataCell(Text(shipment.totalAmount.toString())),
          DataCell(Text(shipment.assignedOrders.toString())),
          DataCell(Text(shipment.userType ?? '')),
          DataCell(Text(shipment.paymentType ?? '')),
          DataCell(Text(shipment.servicesFees.toString())),
          DataCell(Text(shipment.totalAmount.toString())),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shipment.pdfUrl != null)
                IconButton(
                  icon: const Icon(Icons.file_download, size: 20),
                  onPressed: () {
                    FileHandler().openFileFromUrl(shipment.pdfUrl!);
                  },
                  padding: EdgeInsets.zero,
                ),

              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: () {
                  // PrintHandler().printUserAccountDocument(shipment);
                  PrintHandler()
                      .printUserAccountDocument(shipment, isDownload: true);
                },
                padding: EdgeInsets.zero,
              ),
              if (shipment.paymentImageUrl != null)
                IconButton(
                  icon: const Icon(Icons.image, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("صورة الفاتورة"),
                        content: Image.network(shipment.paymentImageUrl ?? ''),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                ),
              // IconButton(
              //   icon: const Icon(Icons.file_download, size: 20),
              //   onPressed: () {},
              //   padding: EdgeInsets.zero,
              // ),
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
      child: Row(
        children: [
          Text('إجمالي المبالغ: JOD ${_calculateTotal()}'),
          const Spacer(),
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
          const SizedBox(width: 16),
          Text('عدد السجلات: ${filteredUserAccounts.length}'),
        ],
      ),
    );
  }

  double _calculateTotal() {
    return filteredUserAccounts.fold(0, (sum, shipment) => sum + shipment.totalAmount);
  }
}
