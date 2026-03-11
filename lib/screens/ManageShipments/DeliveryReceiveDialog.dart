import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard/header/showSideDrawerDialog.dart';
import '../../main.dart';
import '../../models/Shipment.dart';
import '../AddOrder/AddOrderFormOne.dart';
import 'widget/CustomScrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/BarcodeScannerDialog.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';

class DeliveryReceiveDialog extends StatefulWidget {
  final int index;
  final String? driverId;
  const DeliveryReceiveDialog({Key? key, required this.index, this.driverId})
      : super(key: key);

  @override
  _DeliveryReceiveDialogState createState() => _DeliveryReceiveDialogState();
}

void showDeliveryDialog(BuildContext context, int index, {String? driverId}) {
  showDialog(
    context: context,
    builder: (context) =>
        DeliveryReceiveDialog(index: index, driverId: driverId),
  );
}

class _DeliveryReceiveDialogState extends State<DeliveryReceiveDialog> {
  List<Shipment> shipments = [];

  Set<Shipment> selectedShipments = {};
  Set<String> selectedOrderIds = {};
  bool isLoading = false;

  ordersByDriver(String driverId) {
    setState(() {
      selectedDriverId = driverId;

      isLoading = true;
    });
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('driverId', isEqualTo: driverId);
    // .where('status',
    //     whereNotIn: ["تم توصيلها", "في الفرع", "بانتظار موافقة السائق"]);

    if (widget.index == 1) {
      query = query.where('orderPossession', whereIn: [
        'driverFetching',
        'driverShipping',
        'driverReturning'
      ]).where('status', isEqualTo: 'تم إرجاعها');
    } else {
      query = query.where('orderPossession',
          whereIn: ['driverFetching', 'driverShipping', 'driverReturning']);

      // query = query.where('status',
      //     whereNotIn: ["تم توصيلها", "في الفرع", "بانتظار موافقة السائق"]);
    }

    query.get().then((value) {
      List<Shipment> orders =
          value.docs.map((e) => Shipment.fromMap(e.data())).toList();

      if (widget.index == 0) {
        orders = orders
            .where((order) => ![
                  "تم توصيلها",
                  "في الفرع",
                  "بانتظار موافقة السائق",
                  "تم إرجاعها" // Exclude returned orders as they have their own index
                ].contains(order.status))
            .toList();
      }

      setState(() {
        selectedShipments = orders.toSet();
        isLoading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.driverId != null) {
      ordersByDriver(widget.driverId!);
    }
  }

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  String? selectedBranch;

  late bool isExpanded;
  String? selectedDriverId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize isExpanded based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    isExpanded = screenWidth > 768; // false for mobile (768px and below)
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      bool isDesktop = MediaQuery.of(context).size.width > 768;
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: isDesktop
                ? MediaQuery.of(context).size.width * 0.90
                : double.infinity,
            height: isDesktop
                ? MediaQuery.of(context).size.height * 0.90
                : double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar section
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: isExpanded ? 300 : 0,
                        child: Stack(
                          children: [
                            if (isExpanded)
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
                          ],
                        ),
                      ),
                      // Toggle button and main content
                      Expanded(
                        child: _buildMainContent(appProvider),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(appProvider),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDeliveryTable() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 1000,
      ),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        columnWidths: const {
          0: FixedColumnWidth(40), // Checkbox column
          1: FixedColumnWidth(80), // Parcel count column
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            children: [
              //cheak all
              Checkbox(
                value: selectedOrderIds.length == selectedShipments.length,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedOrderIds
                          .addAll(selectedShipments.map((e) => e.orderId));
                    } else {
                      selectedOrderIds.clear();
                    }
                  });
                },
                activeColor: Color(0xFFDC2626),
              ),
              _buildTableHeader('عدد\nالطرود'),
              _buildTableHeader('الملاحظات'),
              _buildTableHeader('تاريخ\nالتحديث'),
              _buildTableHeader('رقم\nالتتبع'),
              _buildTableHeader('طريقة\nالدفع'),
              _buildTableHeader('المدينة'),
              _buildTableHeader('الحالة'),
              _buildTableHeader('مبلغ\nالتحصيل'),
              _buildTableHeader('تكلفة\nالتوصيل'),
              _buildTableHeader('المستلم'),
              _buildTableHeader('المرسل'),
              _buildTableHeader('حيازة الشحنة'),
              _buildTableHeader('اجراءات'),
            ],
          ),
          ...selectedShipments
              .map((shipment) => _buildShipmentRow(shipment))
              .toList(),
        ],
      ),
    );
  }

  TableRow _buildShipmentRow(Shipment shipment) {
    bool isSelected = selectedOrderIds.contains(shipment.orderId);

    return TableRow(
      children: [
        _buildTableCell(Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedOrderIds.add(shipment.orderId);
              } else {
                selectedOrderIds.remove(shipment.orderId);
              }
            });
          },
          activeColor: Colors.green,
        )),
        _buildTableCell(shipment.parcelCount.toString()),
        _buildTableCell(shipment.notes),
        _buildTableCell(shipment.lastUpdated.toString().split(' ')[0]),
        _buildTableCell(shipment.trackingNumber),
        _buildTableCell(shipment.paymentMethod),
        _buildTableCell(shipment.city),
        _buildTableCell(_buildStatusBadge(shipment.status)),
        _buildTableCell(shipment.codAmount.toString()),
        _buildTableCell(shipment.deliveryCost.toString()),
        _buildTableCell(shipment.recipientName),
        _buildTableCell(shipment.username ?? ''),
        _buildTableCell(_translatePossession(
            shipment.orderPossession.toString().split('.').last)),
        IconButton(
            onPressed: () {
              showSideDrawerDialog(
                  context: context,
                  child: AddOrderFormOne(
                    shipment: shipment,
                    isEditMode: true,
                  ));
            },
            icon: Icon(Icons.edit))
      ],
    );
  }

  String _translatePossession(String possession) {
    switch (possession) {
      case 'driverShipping':
        return 'مع السائق (توصيل)';
      case 'driverFetching':
        return 'مع السائق (جلب)';
      case 'driverReturning':
        return 'مع السائق (إرجاع)';
      case 'branch':
        return 'في الفرع';
      case 'customer':
        return 'مع العميل';
      default:
        return 'غير معروف';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'تم توصيلها':
        bgColor = Color(0xFFDC2626).withOpacity(0.1);
        textColor = Color(0xFFDC2626);
        break;
      case 'في المركبة':
        bgColor = Color(0xFFDC2626).withOpacity(0.1);
        textColor = Color(0xFFDC2626);
        break;
      case 'تم إرجاعها':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
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

  Widget _buildTableHeader(String text) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
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

  Widget _buildMainContent(AppProvider appProvider) {
    return CustomScrollbar(
      verticalScrollController: _verticalScrollController,
      horizontalScrollController: _horizontalScrollController,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildDeliveryTable(),
      ),
    );
  }

  Widget _buildSidebar(AppProvider appProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBranchSection(),
          SizedBox(height: 24),
          _buildDriverSection(appProvider),
        ],
      ),
    );
  }

  Widget _buildBranchSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفرع المراد استلام الطرود فيه',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          TextField(
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
          SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildBranchItem(KcompanyName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchItem(String name) {
    bool isSelected = selectedBranch == name;
    return InkWell(
      onTap: () {
        setState(() {
          selectedBranch = name;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFDC2626).withOpacity(0.1) : null,
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Color(0xFFDC2626) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSection(AppProvider appProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر السائق',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: appProvider.drivers.length,
              itemBuilder: (context, index) {
                return _buildDriverItem(appProvider.drivers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverItem(Driver driver) {
    List<Shipment> driverShipments = shipments
        .where((shipment) => shipment.driverId == driver.userid)
        .toList();
    return ListTile(
      selected: selectedDriverId == driver.userid,
      onTap: () {
        ordersByDriver(driver.userid ?? '');
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Icon(
          Icons.person_outline,
          color: Colors.grey.shade600,
        ),
      ),
      title: Text(
        driver.username ?? '',
        style: TextStyle(fontSize: 13),
      ),
      // trailing: Container(
      //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //   decoration: BoxDecoration(
      //     color: Colors.grey.shade100,
      //     borderRadius: BorderRadius.circular(12),
      //   ),
      //   child: Text(
      //     //todo
      //     '${driverShipments.length} طرد',
      //     style: TextStyle(fontSize: 12),
      //   ),
      // ),
    );
  }

  Widget _buildBottomBar(AppProvider appProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 50,
            width: 50,
            child: Row(
              children: [
                IconButton(
                  icon:
                      Icon(isExpanded ? Icons.arrow_forward : Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  tooltip: isExpanded
                      ? 'إخفاء الشريط الجانبي'
                      : 'إظهار الشريط الجانبي',
                ),
                Expanded(child: Container()), // Spacer
              ],
            ),
          ),
          OutlinedButton.icon(
            icon: Icon(Icons.barcode_reader),
            label: Text('إدخال بالباركود'),
            onPressed: () async {
              final barcode = await showBarcodeScannerDialog(context);
              if (barcode != null) {
                // Handle the barcode number here
                print('Scanned barcode: $barcode');
                appProvider.getOrder(barcode).then((order) {
                  if (order != null) {
                    if (widget.index == 0 && order.driverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('لا يوجد سائق يحمل هذه الشحنه'),
                      ));
                      return;
                    }
                    setState(() {
                      selectedShipments.add(order);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('لا يوجد طرد بهذا الباركود'),
                    ));
                  }
                });
              }
            },
          ),
          Spacer(),
          SizedBox(width: 16),
          ElevatedButton.icon(
            icon: Text('${selectedOrderIds.length} طرد'),
            label: Text('استلام'),
            onPressed: () {
              String status = widget.index == 0 ? "في الفرع" : "تم إرجاعها";
              for (String orderId in selectedOrderIds) {
                if (widget.index == 0) {
                  appProvider.updateOrderStatus(orderId, status, null, null,
                      returnedAfterDelivery: false,
                      orderPossession: OrderPossession.branch);
                } else {
                  appProvider.reciveReturnOrder(orderId);
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showBarcodeScannerDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return BarcodeScannerDialog(
        onScan: (String code) {
          Navigator.of(context).pop(code);
        },
      );
    },
  );
}
