
import '../../main.dart';
import '../../shared/firebaseHelper.dart';
import '../../utils/file_handler.dart';
import 'package:flutter/material.dart';
import '../../shared/PrintHelper.dart';
import 'package:intl/intl.dart' as intl;

import '../../models/DriverDeliveryData.dart';

class ReceiptedInvoices extends StatefulWidget {
  const ReceiptedInvoices({Key? key}) : super(key: key);

  @override
  State<ReceiptedInvoices> createState() => _ReceiptedInvoicesState();
}

class _ReceiptedInvoicesState extends State<ReceiptedInvoices> {
  List<DriverDeliveryData> deliveryDataList = [];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopActions(),
            _buildTableHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: StreamBuilder<List<DriverDeliveryData>>(
                      stream: FirebaseHelper.receiptedInvoicesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        deliveryDataList = snapshot.data ?? [];

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

  Widget _buildTopActions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
            'فواتير الاستلام من السائقين',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          // Add actions as needed
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, bool isActive,
      {Null Function()? onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? primary : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.black,
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon),
            onPressed: () {},
            color: Colors.grey[700],
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
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
          PopupMenuButton(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Text('مرتبة حسب التاريخ'),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            itemBuilder: (context) => [],
          ),
        ],
      ),
    );
  }

  List<DataColumn> _createColumns() {
    final columns = [
      '',
      'اسم السائق',
      'تاريخ الاستلام',
      'تاريخ الدفع',
      'عدد الطرود',
      'الطرود المسلمة',
      'الطرود المرتجعة',
      'مجموع\nالتحصيلات',
      'مجموع\nالتكاليف',
      'طريقة الدفع',
      'رقم الوثيقة',
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
    return deliveryDataList.map((data) {
      return DataRow(
        cells: [
          DataCell(Checkbox(value: false, onChanged: (bool? value) {})),
          DataCell(Text(data.driverName)),
          DataCell(Text(data.deliveryDate != null
              ? intl.DateFormat('yyyy/MM/dd').format(data.deliveryDate)
              : '')),
          DataCell(Text(data.paymentDate != null
              ? intl.DateFormat('yyyy/MM/dd').format(data.paymentDate!)
              : '')),
          DataCell(Text(data.parcelCount.toString())),
          DataCell(Text(data.delivered.toString())),
          DataCell(Text(
              (data.returnedBeforeDelivery + data.returnedAfterDelivery)
                  .toString())),
          DataCell(Text(data.totalCollections.toStringAsFixed(2))),
          DataCell(Text(data.price.toStringAsFixed(2))),
          DataCell(Text(data.paymentMethod ?? '')),
          DataCell(Text(data.documentNumber ?? '')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.pdfUrl != null)
                IconButton(
                  icon: const Icon(Icons.file_download, size: 20),
                  onPressed: () {
                    FileHandler().openFileFromUrl(data.pdfUrl!);
                  },
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: () {
                  PrintHandler()
                      .printDriverDeliveryDataDocument(data, isDownload: true);
                },
                padding: EdgeInsets.zero,
              ),
              if (data.paymentImageUrl != null)
                IconButton(
                  icon: const Icon(Icons.image, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("صورة سند الاستلام"),
                        content: Image.network(data.paymentImageUrl ?? ''),
                      ),
                    );
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
      child: Row(
        children: [
          Text('إجمالي التحصيلات: JOD ${_calculateTotalCollections()}'),
          const SizedBox(width: 16),
          Text('إجمالي التكاليف: JOD ${_calculateTotalPrice()}'),
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
          Text('عدد السجلات: ${deliveryDataList.length}'),
        ],
      ),
    );
  }

  double _calculateTotalCollections() {
    return deliveryDataList.fold(0, (sum, data) => sum + data.totalCollections);
  }

  double _calculateTotalPrice() {
    return deliveryDataList.fold(0, (sum, data) => sum + data.price);
  }
}
