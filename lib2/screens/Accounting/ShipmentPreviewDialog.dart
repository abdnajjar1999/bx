import '../../main.dart';
import '../../models/UserAccount.dart';
import '../../shared/firebaseHelper.dart';
import 'package:flutter/material.dart';

class ShipmentPreviewDialog extends StatefulWidget {
  final UserAccount userAccount;
  final String? selectedStatus;

  const ShipmentPreviewDialog({
    Key? key,
    required this.userAccount,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<ShipmentPreviewDialog> createState() => _ShipmentPreviewDialogState();
}

class _ShipmentPreviewDialogState extends State<ShipmentPreviewDialog> {
  Set<String> selectedShipmentIds = {};
  bool _isLoading = false;
  String? selectedStatus;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatusSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildShipmentsList(),
            ),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'شحنات ${widget.userAccount.client}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        const Text(
          'تحديث الحالة إلى:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sorted',
                child: Text('مفرزة'),
              ),
              DropdownMenuItem(
                value: 'exported',
                child: Text('مصدرة'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView(
              children: [
                DataTable(
                  columns: _createColumns(),
                  rows: _createRows(),
                  columnSpacing: 15,
                  horizontalMargin: 10,
                  headingRowHeight: 40,
                  dataRowHeight: 45,
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey.shade300),
                    verticalInside: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
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
          Checkbox(
            value: selectedShipmentIds.length ==
                    widget.userAccount.shipments.length &&
                widget.userAccount.shipments.isNotEmpty,
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  selectedShipmentIds = widget.userAccount.shipments
                      .map((shipment) => shipment.orderId)
                      .toSet();
                } else {
                  selectedShipmentIds.clear();
                }
              });
            },
          ),
          Text(
            'تم تحديد ${selectedShipmentIds.length} من ${widget.userAccount.shipments.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _createColumns() {
    final columns = [
      '', // First column for checkboxes
      'رقم التتبع',
      'المستلم',
      'المدينة',
      'الحالة',
      'قيمة الشحنة',
      'رسوم التوصيل',
    ];

    return columns
        .map((String column) => DataColumn(
              label: Expanded(
                child: Text(
                  column,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ))
        .toList();
  }

  List<DataRow> _createRows() {
    return widget.userAccount.shipments.map((shipment) {
      return DataRow(
        cells: [
          DataCell(
            Checkbox(
              value: selectedShipmentIds.contains(shipment.orderId),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    selectedShipmentIds.add(shipment.orderId);
                  } else {
                    selectedShipmentIds.remove(shipment.orderId);
                  }
                });
              },
            ),
          ),
          DataCell(Text(shipment.trackingNumber)),
          DataCell(Text(shipment.recipientName)),
          DataCell(Text(shipment.city)),
          DataCell(Text(shipment.status)),
          DataCell(Text(shipment.codAmount.toStringAsFixed(2))),
          DataCell(Text(shipment.deliveryCost.toStringAsFixed(2))),
        ],
      );
    }).toList();
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'المجموع: ${_calculateSelectedTotal().toStringAsFixed(2)} JOD',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: selectedShipmentIds.isEmpty || selectedStatus == null
                    ? null
                    : _updateSelectedShipments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('تحديث الحالة'),
              ),
      ],
    );
  }

  double _calculateSelectedTotal() {
    return widget.userAccount.shipments
        .where((shipment) => selectedShipmentIds.contains(shipment.orderId))
        .fold(0, (sum, shipment) => sum + shipment.codAmount);
  }

  Future<void> _updateSelectedShipments() async {
    if (selectedStatus == null || selectedShipmentIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Create a new UserAccount with only the selected shipments
      final selectedShipments = widget.userAccount.shipments
          .where((shipment) => selectedShipmentIds.contains(shipment.orderId))
          .toList();

      final selectedUserAccount = UserAccount.fromShipments(selectedShipments);

      // Update payment status for selected shipments
      await FirebaseHelper.updatePaymentStatus(
          selectedUserAccount, selectedStatus!);

      Navigator.of(context).pop(true); // Return true to indicate success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('تم تحديث حالة ${selectedShipmentIds.length} شحنة بنجاح'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
