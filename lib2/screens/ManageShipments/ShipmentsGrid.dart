import 'package:cloud_firestore/cloud_firestore.dart';
import 'widget/CustomDropdown.dart';
import 'widget/CustomTextField.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ShipmentDataSource extends DataGridSource {
  List<DataGridRow> _shipmentData = [];
  List<DocumentSnapshot<Map<String, dynamic>>> orders = [];

  ShipmentDataSource({required this.orders}) {
    _shipmentData = orders
        .map<DataGridRow>((order) => DataGridRow(cells: [
              DataGridCell<String>(
                  columnName: 'trackingNumber',
                  value: order['trackingNumber']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'weight',
                  value:
                      order['weight'] != "" ? order['weight'].toString() : "0"),
              DataGridCell<String>(
                  columnName: 'deliveryCost',
                  value: "${order['deliveryCost']} JOD"),
              DataGridCell<String>(
                  columnName: 'codAmount',
                  value: order['codAmount']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'userId',
                  value: order['userId']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'phoneNumber',
                  value: order['phoneNumber']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'username',
                  value: order['username']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'recipientName',
                  value: order['recipientName']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'status',
                  value: order['status']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'shipment',
                  value: order['trackingNumber']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'paymentMethod',
                  value: order['paymentMethod']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'collectionMethod',
                  value: order['collectionMethod']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'createdAt',
                  value: order['createdAt']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'deliveryDate',
                  value: order.data()?.containsKey('deliveryDate') == true
                      ? order['deliveryDate'].toString()
                      : ''),
              DataGridCell<String>(
                  columnName: 'expectedDeliveryDate',
                  value:
                      order.data()?.containsKey('expectedDeliveryDate') == true
                          ? order['expectedDeliveryDate'].toString()
                          : ''),
              DataGridCell<String>(
                  columnName: 'lastUpdated',
                  value: order['lastUpdated']?.toString() ?? ''),
              DataGridCell<String>(
                  columnName: 'postponementDate',
                  value: order.data()?.containsKey('postponementDate') == true
                      ? order['postponementDate'].toString()
                      : ''),
              DataGridCell<String>(
                  columnName: 'notes', value: order['notes']?.toString() ?? ''),
            ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _shipmentData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((cell) {
      return Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          cell.value.toString(),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList());
  }
}

class ShipmentsGrid extends StatefulWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> orders;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;

  const ShipmentsGrid({
    Key? key,
    required this.orders,
    required this.verticalScrollController,
    required this.horizontalScrollController,
  }) : super(key: key);

  @override
  State<ShipmentsGrid> createState() => _ShipmentsGridState();
}

class _ShipmentsGridState extends State<ShipmentsGrid> {
  late ShipmentDataSource shipmentDataSource;
  final List<String> statusOptions = []; // Add your status options
  final List<String> paymentMethods = []; // Add your payment methods
  final List<String> collectionMethods = []; // Add your collection methods
  String? selectedCustomer;
  String? selectedStatus;
  String? selectedPaymentMethod;
  String? selectedCollectionMethod;
  List<GridColumn> _buildColumns() {
    final headerStyle = const TextStyle(fontWeight: FontWeight.bold);

    return [
      GridColumn(
        columnName: 'trackingNumber',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: "رقم الطرد",
          hintText: "ادخل رقم الطرد",
          prefixIcon: Icons.numbers,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'weight',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: "الوزن",
          hintText: "ادخل الوزن",
          prefixIcon: Icons.scale,
          controller: TextEditingController(),
        ),
      ),
      // Add remaining columns similarly...
      GridColumn(
        columnName: 'deliveryCost',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: "السعر",
          hintText: "ادخل السعر",
          prefixIcon: Icons.monetization_on_outlined,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'codAmount',
        width: 150,
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Text('COD', style: headerStyle),
        ),
      ),
      GridColumn(
        columnName: 'userId',
        width: 200,
        label: CustomDropdown(
          width: 200,
          labelText: 'الزبون',
          prefixIcon: Icons.person_outline,
          value: selectedCustomer,
          items: statusOptions,
          onChanged: (String? newValue) {},
        ),
      ),
      GridColumn(
        columnName: 'phoneNumber',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'هاتف المستقبل',
          hintText: "ادخل رقم الهاتف",
          prefixIcon: Icons.phone,
          controller: TextEditingController(),
          keyboardType: TextInputType.phone,
        ),
      ),
      GridColumn(
        columnName: 'username',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'المرسل',
          hintText: "ادخل اسم المرسل",
          prefixIcon: Icons.person_outline,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'recipientName',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'المستقبل',
          hintText: "ادخل اسم المستقبل",
          prefixIcon: Icons.person_outline,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'status',
        width: 200,
        label: CustomDropdown(
          width: 200,
          labelText: 'الحالة',
          prefixIcon: Icons.info_outline,
          value: selectedStatus,
          items: statusOptions,
          onChanged: (String? newValue) {},
        ),
      ),
      GridColumn(
        columnName: 'shipment',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'الإرسالية',
          hintText: "ادخل رقم الإرسالية",
          prefixIcon: Icons.local_shipping_outlined,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'paymentMethod',
        width: 200,
        label: CustomDropdown(
          width: 200,
          labelText: 'طريقة الدفع',
          prefixIcon: Icons.payment,
          value: selectedPaymentMethod,
          items: paymentMethods,
          onChanged: (String? newValue) {},
        ),
      ),
      GridColumn(
        columnName: 'collectionMethod',
        width: 200,
        label: CustomDropdown(
          width: 200,
          labelText: 'طريقة التحصيل',
          prefixIcon: Icons.account_balance_wallet,
          value: selectedCollectionMethod,
          items: collectionMethods,
          onChanged: (String? newValue) {
            setState(() {
              selectedCollectionMethod = newValue!;
            });
          },
        ),
      ),
      GridColumn(
        columnName: 'createdAt',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'تاريخ الحجز',
          hintText: "ادخل تاريخ الحجز",
          prefixIcon: Icons.calendar_today,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'deliveryDate',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'تاريخ التوصيل',
          hintText: "ادخل تاريخ التوصيل",
          prefixIcon: Icons.calendar_today,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'expectedDeliveryDate',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'تاريخ التوصيل المتوقع',
          hintText: "ادخل تاريخ التوصيل المتوقع",
          prefixIcon: Icons.calendar_today,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'lastUpdated',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'تاريخ اخر حالة',
          hintText: "ادخل تاريخ اخر حالة",
          prefixIcon: Icons.calendar_today,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'postponementDate',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'تاريخ التأجيل',
          hintText: "ادخل تاريخ التأجيل",
          prefixIcon: Icons.calendar_today,
          controller: TextEditingController(),
        ),
      ),
      GridColumn(
        columnName: 'notes',
        width: 200,
        label: CustomTextField(
          width: 200,
          labelText: 'ملاحظات',
          hintText: "ادخل ملاحظات",
          prefixIcon: Icons.note,
          controller: TextEditingController(),
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    shipmentDataSource = ShipmentDataSource(orders: widget.orders);
  }

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: shipmentDataSource,
      columns: _buildColumns(),
      allowSorting: true,
      allowFiltering: true,
      allowMultiColumnSorting: true,
      allowTriStateSorting: true,
      selectionMode: SelectionMode.single,
      navigationMode: GridNavigationMode.cell,
      verticalScrollController: widget.verticalScrollController,
      horizontalScrollController: widget.horizontalScrollController,
      columnWidthMode: ColumnWidthMode.fill,
      gridLinesVisibility: GridLinesVisibility.both,
      headerGridLinesVisibility: GridLinesVisibility.both,
    );
  }
}
