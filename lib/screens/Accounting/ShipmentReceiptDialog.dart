import 'package:good_line_delivery/screens/AddOrder/AddOrderFormOne.dart';

import '../../models/PriceCalculators.dart';
import '../../models/Shipment.dart';

import '../../main.dart';

import '../AddOrder/AddOrderForm.dart';
import '../dashboard/header/showSideDrawerDialog.dart';
import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../../models/DriverDeliveryData.dart';

import 'FinancialSettlementsDialog.dart';

class ShipmentReceiptDialog extends StatefulWidget {
  const ShipmentReceiptDialog({Key? key}) : super(key: key);

  @override
  State<ShipmentReceiptDialog> createState() => _ShipmentReceiptDialogState();
}

class _ShipmentReceiptDialogState extends State<ShipmentReceiptDialog> {
  DriverDeliveryData? selectedDeliveryData;
  List<DriverDeliveryData> deliveryDataList = [];
  Set<String> selectedOrderIds = {};

  // Add filter controllers
  final TextEditingController _dateFilter = TextEditingController();
  final TextEditingController _customerFilter = TextEditingController();
  final TextEditingController _phoneFilter = TextEditingController();
  String _statusFilter = '';

  // Add filtered shipments getter
  List<dynamic> get filteredShipments {
    if (selectedDeliveryData == null) return [];

    return selectedDeliveryData!.shipments.where((shipment) {
      final dateStr = intl.DateFormat('MM/dd')
          .format(shipment.lastUpdated ?? DateTime.now())
          .toLowerCase();
      final customer = (shipment.username ?? '').toLowerCase();
      final phone = (shipment.phoneNumber ?? '').toLowerCase();

      bool matchesDate = _dateFilter.text.isEmpty ||
          dateStr.contains(_dateFilter.text.toLowerCase());
      bool matchesCustomer = _customerFilter.text.isEmpty ||
          customer.contains(_customerFilter.text.toLowerCase());
      bool matchesPhone = _phoneFilter.text.isEmpty ||
          phone.contains(_phoneFilter.text.toLowerCase());
      bool matchesStatus =
          _statusFilter.isEmpty || shipment.status == _statusFilter;

      return matchesDate && matchesCustomer && matchesPhone && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.90,
            height: MediaQuery.of(context).size.height * 0.90,
            child: Row(
              children: [
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: _buildSidebar(appProvider),
                ),
                Expanded(
                  flex: 4,
                  child: _buildMainContent(appProvider),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSidebar(AppProvider appProvider) {
    return StreamBuilder<List<DriverDeliveryData>>(
      stream: FirebaseHelper()
          .getDriverDeliveryData(isReceipt: true, drivers: appProvider.drivers),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        deliveryDataList = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قائمة التسليمات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        deliveryDataList = deliveryDataList
                            .where(
                                (element) => element.driverName.contains(value))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: deliveryDataList.length,
                itemBuilder: (context, index) {
                  return _buildDeliveryDataItem(
                      deliveryDataList[index], appProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryDataItem(
      DriverDeliveryData data, AppProvider appProvider) {
    bool isSelected = selectedDeliveryData?.driverName == data.driverName;
    return ListTile(
      onTap: () {
        setState(() {
          selectedDeliveryData = data;
          appProvider.selectedDriver = appProvider.drivers
              .firstWhere((element) => element.username == data.driverName);
        });
      },
      tileColor: isSelected ? Color(0xFFDC2626).withOpacity(0.1) : null,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Icon(
          Icons.local_shipping_outlined,
          color: Colors.grey.shade600,
        ),
      ),
      title: Text(
        data.driverName,
        style: TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        intl.DateFormat('yyyy-MM-dd').format(data.deliveryDate),
        style: TextStyle(fontSize: 12),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${data.totalCollections.toStringAsFixed(2)} دينار',
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMainContent(AppProvider appProvider) {
    if (selectedDeliveryData == null) {
      return Center(
        child: Text(
          'الرجاء اختيار تسليم من القائمة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Calculate total statistics
    final total = selectedDeliveryData!.shipments.length;
    final totalCod = selectedDeliveryData!.totalCollections;
    final totalPrice = selectedDeliveryData!.price;
    final delivered = selectedDeliveryData!.shipments
        .where((s) => s.status == 'تم توصيلها')
        .length;
    final partlyDelivered = selectedDeliveryData!.shipments
        .where((s) => s.status == "تم توصيلها بشكل جزئي")
        .length;
    final returnedBefore = selectedDeliveryData!.returnedBeforeDelivery;
    final returnedAfter = selectedDeliveryData!.returnedAfterDelivery;

    // Calculate selected statistics
    final selectedShipments = selectedDeliveryData!.shipments
        .where((s) => selectedOrderIds.contains(s.orderId))
        .toList();

    List<UserShippingRoute> driverShippingRoute = appProvider
        .driverShippingRoutes
        .where(
            (element) => element.userId == appProvider.selectedDriver!.userid)
        .toList();
    List<ShippingRoute> selectedDriverShippingRoute =
        driverShippingRoute.isNotEmpty
            ? driverShippingRoute.first.shippingRoute
            : appProvider.driverShippingRoutes
                .where((element) => element.userId == 'main')
                .first
                .shippingRoute;
    DriverDeliveryData selectedIdsDeliveryData =
        DriverDeliveryData.fromShipments(
            '',
            Shipment.getShipmentsWithDriverPrice(
                selectedShipments, selectedDriverShippingRoute));

    final selectedTotal = selectedShipments.length;
    final selectedTotalCod = selectedIdsDeliveryData.totalCollections;
    final selectedPartlyDelivered = selectedShipments
        .where((s) => s.status == "تم توصيلها بشكل جزئي")
        .length;
    final selectedDelivered =
        selectedShipments.where((s) => s.status == 'تم توصيلها').length;
    final selectedReturnedBefore =
        selectedIdsDeliveryData.returnedBeforeDelivery;
    final selectedReturnedAfter = selectedIdsDeliveryData.returnedAfterDelivery;
    final selectedTotalPrice = selectedIdsDeliveryData.price;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Statistics Row
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("عدد الطرود", total.toString(), '-'),
                    _buildStatItem('السعر', totalPrice.toStringAsFixed(2), '-'),
                    _buildStatItem(
                        'مجموع التحصيلات', totalCod.toStringAsFixed(2), '-'),
                    _buildStatItem('تم توصيلها', delivered.toString(), '-'),
                    _buildStatItem('تم توصيلها بشكل جزئي',
                        partlyDelivered.toString(), '-'),
                    _buildStatItem(
                        'مرتجعة قبل التوصيل', returnedBefore.toString(), '-'),
                    _buildStatItem(
                        'مرتجعة بعد التوصيل', returnedAfter.toString(), '-'),
                  ],
                ),
              ),
              // Selected Statistics Row
              if (selectedOrderIds.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('المحدد', selectedTotal.toString(), '-',
                          isSelected: true),
                      _buildStatItem(
                          'السعر', selectedTotalPrice.toStringAsFixed(2), '-',
                          isSelected: true),
                      _buildStatItem('مجموع التحصيلات',
                          selectedTotalCod.toStringAsFixed(2), '-',
                          isSelected: true),
                      _buildStatItem(
                          'تم توصيلها', selectedDelivered.toString(), '-',
                          isSelected: true),
                      _buildStatItem('تم توصيلها بشكل جزئي',
                          selectedPartlyDelivered.toString(), '-',
                          isSelected: true),
                      _buildStatItem('مرتجعة قبل التوصيل',
                          selectedReturnedBefore.toString(), '-',
                          isSelected: true),
                      _buildStatItem('مرتجعة بعد التوصيل',
                          selectedReturnedAfter.toString(), '-',
                          isSelected: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _buildShipmentsTable(),
            ),
          ),
        ),
        _buildBottomBar(appProvider),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String count,
      {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? primary.withOpacity(0.8) : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? primary.withOpacity(0.8) : Colors.black,
              ),
            ),
            if (count != '-') ...[
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? primary.withOpacity(0.8)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildShipmentsTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        //   0: FixedColumnWidth(40),
        //   1: FixedColumnWidth(80),
        6: FixedColumnWidth(120),
        //   3: FixedColumnWidth(80),
        //   4: FixedColumnWidth(80),
        //   5: FixedColumnWidth(80),
        //   6: FixedColumnWidth(80),
        //   7: FixedColumnWidth(120),
      },
      children: [
        // Statistics Row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
          ),
          children: [
            _buildTableCell(''),
            _buildTableCell(
              TextField(
                controller: _dateFilter,
                decoration: InputDecoration(
                  hintText: 'التاريخ',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            _buildTableCell(
              TextField(
                controller: _customerFilter,
                decoration: InputDecoration(
                  hintText: 'الزبون',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            _buildTableCell(
              TextField(
                controller: _phoneFilter,
                decoration: InputDecoration(
                  hintText: 'رقم الهاتف',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            _buildTableCell('التحصيل شامل التوصيل'),
            _buildTableCell('تكلفة التوصيل'),
            _buildTableCell(
              DropdownButtonFormField<String>(
                value: _statusFilter.isEmpty ? null : _statusFilter,
                decoration: InputDecoration(
                  hintText: 'الحالة',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text('الكل')),
                  DropdownMenuItem(
                      value: 'تم توصيلها',
                      child:
                          Text('تم توصيلها', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'تم توصيلها بشكل جزئي',
                      child: Text('جزئي', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'تم إرجاعها',
                      child:
                          Text('تم إرجاعها', overflow: TextOverflow.ellipsis)),
                ],
                isExpanded: true,
                onChanged: (value) =>
                    setState(() => _statusFilter = value ?? ''),
              ),
            ),
            _buildTableCell('إجراءات'),
          ],
        ),
        ...filteredShipments
            .map((shipment) => TableRow(
                  children: [
                    _buildTableCell(
                      Checkbox(
                        value: selectedOrderIds.contains(shipment.orderId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedOrderIds.add(shipment.orderId);
                            } else {
                              selectedOrderIds.remove(shipment.orderId);
                            }
                          });
                        },
                        activeColor: primary,
                      ),
                    ),
                    _buildTableCell(intl.DateFormat('MM/dd')
                        .format(shipment.lastUpdated ?? DateTime.now())),
                    _buildTableCell(shipment.username ?? ''),
                    _buildTableCell(shipment.phoneNumber ?? ''),
                    _buildTableCell('${shipment.codAmount}'),
                    _buildTableCell(shipment.deliveryCost.toString()),
                    _buildTableCell(_buildStatusBadge(shipment.status)),
                    _buildTableCell(Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18),
                          onPressed: () {
                            showSideDrawerDialog(
                              context: context,
                              child: AddOrderFormOne(
                                shipment: shipment,
                                isEditMode: true,
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    )),
                  ],
                ))
            .toList(),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'تم توصيلها':
        bgColor = Color(0xFFDC2626).withOpacity(0.1);
        textColor = Color(0xFFDC2626);
        break;
      case 'تم توصيلها بشكل جزئي':
        bgColor = primary.withOpacity(0.2);
        textColor = primary.withOpacity(0.8);
        break;
      default:
        bgColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTableCell(dynamic content) {
    return Container(
      padding: EdgeInsets.all(8),
      child: content is Widget
          ? Center(child: content)
          : Text(
              content.toString(),
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
    );
  }

  Widget _buildBottomBar(AppProvider appProvider) {
    if (selectedDeliveryData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedDeliveryData = null;
                selectedOrderIds.clear();
              });
            },
            child: Text('إلغاء'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedOrderIds.clear();
              });
            },
            child: Text('إلغاء التحديد'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                selectedOrderIds.addAll(selectedDeliveryData!.shipments
                    .map((shipment) => shipment.orderId));
              });
            },
            child: Text('تحديد الكل'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${selectedOrderIds.length} طرد محدد',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: selectedOrderIds.isEmpty
                ? null
                : () async {
                    List<UserShippingRoute> driverShippingRoute = appProvider
                        .driverShippingRoutes
                        .where((element) =>
                            element.userId ==
                            appProvider.selectedDriver!.userid)
                        .toList();
                    List<ShippingRoute> selectedDriverShippingRoute =
                        driverShippingRoute.isNotEmpty
                            ? driverShippingRoute.first.shippingRoute
                            : appProvider.driverShippingRoutes
                                .where((element) => element.userId == 'main')
                                .first
                                .shippingRoute;
                    if (selectedOrderIds.isNotEmpty) {
                      final selectedShipments = selectedDeliveryData!.shipments
                          .where((shipment) =>
                              selectedOrderIds.contains(shipment.orderId))
                          .toList();

                      var result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return FinancialSettlementsDialog(
                            driverData: DriverDeliveryData.fromShipments(
                              selectedDeliveryData!.driverName,
                              Shipment.getShipmentsWithDriverPrice(
                                  selectedShipments,
                                  selectedDriverShippingRoute),
                            ),
                          );
                        },
                      );

                      Future.delayed(Duration(milliseconds: 100), () {
                        List<DriverDeliveryData> deliveryData = deliveryDataList
                            .where((element) =>
                                element.driverName ==
                                selectedDeliveryData!.driverName)
                            .toList();
                        if (deliveryData.isNotEmpty) {
                          setState(() {
                            selectedDeliveryData = deliveryData.first;
                          });
                        } else {
                          setState(() {
                            selectedDeliveryData = null;
                          });
                        }
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade500,
            ),
            child: Text('إستلام الطرود المحددة'),
          ),
        ],
      ),
    );
  }
}
