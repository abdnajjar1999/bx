import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Shipment.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import 'DeliveryReceiveDialog.dart'; // For showBarcodeScannerDialog and helpers
import 'widget/CustomScrollbar.dart';
import 'widget/SearchableDropdown.dart';

class CustomerCollectionDialog extends StatefulWidget {
  const CustomerCollectionDialog({Key? key}) : super(key: key);

  @override
  _CustomerCollectionDialogState createState() =>
      _CustomerCollectionDialogState();
}

void showCustomerCollectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const CustomerCollectionDialog(),
  );
}

class _CustomerCollectionDialogState extends State<CustomerCollectionDialog> {
  Set<Shipment> customerShipments = {};
  Set<String> selectedOrderIds = {};
  bool isLoading = false;
  String? selectedUserId;
  String? selectedUsername;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _driverSearchController = TextEditingController();
  bool isExpanded = true;
  Driver? assignmentDriver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    isExpanded = screenWidth > 768;
  }

  void _loadCustomerOrders(String userId, String username) {
    setState(() {
      selectedUserId = userId;
      selectedUsername = username;
      isLoading = true;
      selectedOrderIds.clear();
    });

    // We fetch today's orders for this customer
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    FirebaseFirestore.instance
        .collection('orders')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'الطلبات الجديدة')
        .get()
        .then((value) {
      List<Shipment> orders =
          value.docs.map((e) => Shipment.fromMap(e.data())).toList();
      setState(() {
        customerShipments = orders.toSet();
        isLoading = false;
      });
    }).catchError((e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في تحميل الطرود: $e')));
    });
  }

  Future<void> _assignOrders() async {
    if (selectedOrderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار طرود أولاً')));
      return;
    }

    if (assignmentDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار سائق للتعيين')));
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    setState(() => isLoading = true);

    try {
      for (String orderId in selectedOrderIds) {
        await appProvider.assignCollectionDriver(orderId, assignmentDriver!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين الطرود للسائق بنجاح')));

      setState(() {
        // Remove locally from the list
        customerShipments
            .removeWhere((s) => selectedOrderIds.contains(s.orderId));
        selectedOrderIds.clear();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ أثناء التعيين: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      bool isDesktop = MediaQuery.of(context).size.width > 768;
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
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
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Sidebar for Customers
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isExpanded ? 300 : 0,
                        decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: isExpanded ? _buildCustomerSidebar() : null,
                      ),
                      // Main Content
                      Expanded(
                        child: _buildMainContent(),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCustomerSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('اختر الزبون',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final data = userDoc.data() as Map<String, dynamic>;
                  final username = data['username'] ?? 'بدون اسم';
                  final userId = userDoc.id;
                  final isSelected = selectedUserId == userId;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue.shade50,
                    onTap: () => _loadCustomerOrders(userId, username),
                    title: Text(username,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(data['phoneNumber'] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.blue : Colors.grey.shade200,
                      child: Icon(Icons.person,
                          color: isSelected ? Colors.white : Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        if (selectedUsername != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'عرض الطرود للزبون: $selectedUsername (${customerShipments.length} طرد)',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: CustomScrollbar(
            verticalScrollController: _verticalScrollController,
            horizontalScrollController: _horizontalScrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedUserId == null
                      ? const Center(
                          child: Text('الرجاء اختيار زبون من القائمة الجانبية'))
                      : _buildShipmentsTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentsTable() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 1000),
      child: Table(
        border: TableBorder.all(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8)),
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(80),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              Checkbox(
                value: selectedOrderIds.length == customerShipments.length &&
                    customerShipments.isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedOrderIds
                          .addAll(customerShipments.map((e) => e.orderId));
                    } else {
                      selectedOrderIds.clear();
                    }
                  });
                },
                activeColor: Colors.blue,
              ),
              _buildTableHeader('عدد الطرود'),
              _buildTableHeader('رقم التتبع'),
              _buildTableHeader('المدينة'),
              _buildTableHeader('المستلم'),
              _buildTableHeader('الحالة'),
              _buildTableHeader('مبلغ التحصيل'),
            ],
          ),
          ...customerShipments.map((s) => _buildShipmentRow(s)).toList(),
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
              if (value == true)
                selectedOrderIds.add(shipment.orderId);
              else
                selectedOrderIds.remove(shipment.orderId);
            });
          },
          activeColor: Colors.green,
        )),
        _buildTableCell(shipment.parcelCount.toString()),
        _buildTableCell(shipment.trackingNumber),
        _buildTableCell(shipment.city),
        _buildTableCell(shipment.recipientName),
        _buildTableCell(shipment.status),
        _buildTableCell(shipment.codAmount.toString()),
      ],
    );
  }

  Widget _buildTableHeader(String text) => Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center));
  Widget _buildTableCell(dynamic content) => Padding(
      padding: const EdgeInsets.all(8),
      child: content is Widget
          ? Center(child: content)
          : Text(content.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center));

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isExpanded ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => setState(() => isExpanded = !isExpanded),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.barcode_reader),
            label: const Text('إقرأ باركود'),
            onPressed: () async {
              final barcode = await showBarcodeScannerDialog(context);
              if (barcode != null) {
                Provider.of<AppProvider>(context, listen: false)
                    .getOrder(barcode)
                    .then((order) {
                  if (order != null) {
                    setState(() => customerShipments.add(order));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('لا يوجد طرد بهذا الباركود')));
                  }
                });
              }
            },
          ),
          const Spacer(),
          if (selectedUserId != null)
            SizedBox(
              width: 250,
              child: SearchableDropdown<Driver>(
                label: 'سائق الجلب',
                value: assignmentDriver,
                items: Provider.of<AppProvider>(context, listen: false).drivers,
                searchController: _driverSearchController,
                isRequired: false,
                onChanged: (driver) {
                  setState(() => assignmentDriver = driver);
                },
                prefixIcon: Icons.local_shipping,
              ),
            ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: Text('${selectedOrderIds.length} طرد'),
            label: const Text('تعيين للجلب'),
            onPressed: selectedOrderIds.isEmpty ? null : _assignOrders,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
