import 'dart:math';
import 'package:intl/intl.dart' as intl;
import 'package:good_line_delivery/shared/PrintHelper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/Shipment.dart';
import '../../models/Driver.dart';
import '../../models/customer.dart';
import '../../shared/appProvider.dart';
import '../../shared/ExcelImportHandler.dart';
import '../../utils/file_handler.dart';
import '../ManageShipments/DeliveryReceiveDialog.dart';

class ReturnedOrdersScreen extends StatefulWidget {
  final int sectionIndex;
  const ReturnedOrdersScreen({super.key, this.sectionIndex = 17});

  @override
  State<ReturnedOrdersScreen> createState() => _ReturnedOrdersScreenState();
}

class _ReturnedOrdersScreenState extends State<ReturnedOrdersScreen> {
  List<Shipment> returnedShipments = [];
  List<Shipment> filteredShipments = [];
  bool isLoading = true;
  Set<Shipment> selectedOrders = {};
  bool isProcessing = false;

  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  String? _selectedCity;
  String? _selectedMerchantId;

  @override
  void initState() {
    super.initState();
    loadReturnedShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReturnedOrdersScreen oldWidget) {
    if (oldWidget.sectionIndex != widget.sectionIndex) {
      loadReturnedShipments();
    }
    super.didUpdateWidget(oldWidget);
  }

  String get dynamicTitle {
    switch (widget.sectionIndex) {
      case 32:
        return 'شاشة استلام الطرود';
      case 33:
        return 'الرواجع';
      case 34:
        return 'رواجع التبديل';
      case 35:
        return 'رواجع التوصيل الجزئي';
      case 36:
        return 'طرود الاحضار';
      default:
        return 'مرتجع في الفرع';
    }
  }

  void _applyFilters() {
    setState(() {
      filteredShipments = returnedShipments.where((shipment) {
        // Search Filter
        final query = _searchController.text.toLowerCase();
        final matchesSearch = query.isEmpty ||
            shipment.orderId.toLowerCase().contains(query) ||
            shipment.recipientName.toLowerCase().contains(query) ||
            shipment.phoneNumber.contains(query) ||
            (shipment.username?.toLowerCase() ?? '').contains(query);

        // City Filter
        final matchesCity =
            _selectedCity == null || shipment.city == _selectedCity;

        // Merchant Filter
        final matchesMerchant = _selectedMerchantId == null ||
            shipment.userId == _selectedMerchantId;

        // Date Filter
        bool matchesDate = true;
        if (_dateRange != null) {
          if (shipment.returnOrderDate == null) {
            matchesDate = false;
          } else {
            matchesDate =
                shipment.returnOrderDate!.isAfter(_dateRange!.start) &&
                    shipment.returnOrderDate!
                        .isBefore(_dateRange!.end.add(const Duration(days: 1)));
          }
        }

        return matchesSearch && matchesCity && matchesMerchant && matchesDate;
      }).toList();

      selectedOrders.removeWhere((s) => !filteredShipments.contains(s));
    });
  }

  Future<void> loadReturnedShipments() async {
    try {
      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection('orders');

      if (widget.sectionIndex == 35) {
        query = query
            .where('status', isEqualTo: 'تم توصيلها بشكل جزئي')
            .where('orderPossession', isEqualTo: 'branch');
      } else if (widget.sectionIndex == 34 || widget.sectionIndex == 36) {
        query = query
            .where('status', isEqualTo: 'تم توصيلها')
            .where('orderPossession', isEqualTo: 'branch');
        if (widget.sectionIndex == 34) {
          query = query.where('paymentMethod', isEqualTo: 'تبديل');
        } else if (widget.sectionIndex == 36) {
          query = query.where('paymentMethod', isEqualTo: 'إحضار');
        }
      } else {
        query = query
            .where('status', isEqualTo: 'تم إرجاعها')
            .where('orderPossession', isEqualTo: 'branch');
      }

      if (widget.sectionIndex != 35 && widget.sectionIndex != 32) {
        query = query.where('cashPossession', isEqualTo: 'customer');
      }

      query.snapshots().listen((snapshot) {
        if (!mounted) return;
        setState(() {
          returnedShipments = snapshot.docs
              .map(
                  (doc) => Shipment.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          returnedShipments.removeWhere((e) => e.receivedMoneyFromCustomer);
          _applyFilters();
          isLoading = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات')),
      );
    }
  }

  Future<void> handleAssignToDriver() async {
    if (selectedOrders.isEmpty) return;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selectedDriver = await showDialog<Driver>(
      context: context,
      builder: (context) =>
          _DriverSelectionDialog(drivers: appProvider.drivers),
    );
    if (selectedDriver == null) return;
    setState(() => isProcessing = true);
    PrintHandler().printShipmentsDocument(selectedOrders.toList(),
        driverName: selectedDriver.username);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var shipment in selectedOrders) {
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(shipment.orderId);
        batch.update(orderRef, {
          'orderPossession': 'driverReturning',
          'driverId': selectedDriver.userid,
          'driverName': selectedDriver.username,
          'otp': Random().nextInt(9000) + 1000,
        });
      }
      await batch.commit();
      final orderCount = selectedOrders.length;
      setState(() => selectedOrders.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم تعيين $orderCount طلب للسائق ${selectedDriver.username}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تعيين السائق')),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(dynamicTitle,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopActionButtons(),
          _buildFilterBar(appProvider),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _buildOrderTable(), // Changed from List to Table
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (widget.sectionIndex == 32)
              ElevatedButton.icon(
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('استلام الطرود المرجعة',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF24645)),
                onPressed: () {
                  showDeliveryDialog(context, 1);
                },
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('تسليم إلى المرسل',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECAAA4)),
              onPressed: () {
                if (selectedOrders.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حدد طلبات أولاً')));
                  return;
                }
                // Future feature logic
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('قيد التطوير')));
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping, color: Colors.white),
              label: const Text('تحميل مع السائق',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0B880)),
              onPressed: isProcessing ? null : handleAssignToDriver,
            ),
            const SizedBox(width: 16),
            if (selectedOrders.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.print, color: primary),
                onPressed: () => PrintHandler()
                    .printShipmentsDocument(selectedOrders.toList()),
                tooltip: 'طباعة المحدد',
              ),
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.green),
                onPressed: () async {
                  final excel = await ExcelImportHandler()
                      .exportShipmentsToExcel(selectedOrders.toList());
                  await FileHandler.downloadFile(
                      excel, 'returned_orders_selection.xlsx');
                },
                tooltip: 'تصدير المحدد',
              ),
            ],
            TextButton(
              onPressed: () {
                setState(() {
                  if (selectedOrders.length == filteredShipments.length &&
                      filteredShipments.isNotEmpty) {
                    selectedOrders.clear();
                  } else {
                    selectedOrders = filteredShipments.toSet();
                  }
                });
              },
              child: Text(
                selectedOrders.length == filteredShipments.length &&
                        filteredShipments.isNotEmpty
                    ? 'إلغاء الكل'
                    : 'تحديد الكل',
                style: const TextStyle(
                    color: primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ]),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الطلب، العميل، التاجر، أو الهاتف...',
              prefixIcon: const Icon(Icons.search, color: primary),
              filled: true,
              fillColor: background,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: _dateRange == null
                      ? 'التاريخ'
                      : '${intl.DateFormat('MM/dd').format(_dateRange!.start)} - ${intl.DateFormat('MM/dd').format(_dateRange!.end)}',
                  icon: Icons.date_range,
                  onTap: _selectDateRange,
                  isActive: _dateRange != null,
                ),
                _buildFilterChip(
                  label: _selectedCity ?? 'المدينة',
                  icon: Icons.location_city,
                  onTap: () => _selectCity(provider),
                  isActive: _selectedCity != null,
                ),
                _buildFilterChip(
                  label: _selectedMerchantId == null
                      ? 'التاجر'
                      : provider.customers
                          .firstWhere(
                            (c) => c.userid == _selectedMerchantId,
                          )
                          .username,
                  icon: Icons.person,
                  onTap: () => _selectMerchant(provider),
                  isActive: _selectedMerchantId != null,
                ),
                if (_dateRange != null ||
                    _selectedCity != null ||
                    _selectedMerchantId != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _dateRange = null;
                        _selectedCity = null;
                        _selectedMerchantId = null;
                        _searchController.clear();
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: isActive ? primary : background,
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : primary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : primary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTable() {
    if (filteredShipments.isEmpty) {
      return const Center(
          child: Text('لا يوجد طلبات تطابق الفلتر',
              style: TextStyle(color: Colors.grey, fontSize: 16)));
    }
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(label: Text('تحديد')),
                DataColumn(
                    label: Text('باركود الطرد',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('السعر',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('COD',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('الزبون',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('الهاتف',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('تخصيص',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('تاريخ الحجز',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('تاريخ استلام الرواجع',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredShipments.map((shipment) {
                final isSelected = selectedOrders.contains(shipment);
                return DataRow(
                    selected: isSelected,
                    onSelectChanged: (val) {
                      setState(() {
                        if (val == true)
                          selectedOrders.add(shipment);
                        else
                          selectedOrders.remove(shipment);
                      });
                    },
                    cells: [
                      DataCell(Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true)
                              selectedOrders.add(shipment);
                            else
                              selectedOrders.remove(shipment);
                          });
                        },
                        activeColor: primary,
                      )),
                      DataCell(Text(shipment.orderId,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: primary))),
                      DataCell(Text('${shipment.deliveryCost} د.أ')),
                      DataCell(Text('${shipment.codAmount} د.أ')),
                      DataCell(Text(shipment.recipientName)),
                      DataCell(Text(shipment.phoneNumber)),
                      DataCell(IconButton(
                        icon: const Icon(Icons.edit,
                            size: 18, color: Colors.blueGrey),
                        onPressed: () {
                          setState(() {
                            selectedOrders = {shipment};
                          });
                          handleAssignToDriver();
                        },
                      )),
                      DataCell(Text(intl.DateFormat('yyyy-MM-dd')
                          .format(shipment.createdAt))),
                      DataCell(Text(shipment.returnOrderDate != null
                          ? intl.DateFormat('yyyy-MM-dd')
                              .format(shipment.returnOrderDate!)
                          : 'غير محدد')),
                    ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
                primary: primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _applyFilters();
      });
    }
  }

  void _selectCity(AppProvider provider) async {
    final cities = provider.cities;
    final city = await showDialog<String>(
        context: context,
        builder: (context) =>
            _SimpleSelectionDialog(title: 'اختر المدينة', items: cities));
    if (city != null) {
      setState(() {
        _selectedCity = city;
        _applyFilters();
      });
    }
  }

  void _selectMerchant(AppProvider provider) async {
    final merchants = provider.customers;
    final merchant = await showDialog<Customer>(
        context: context,
        builder: (context) => _SimpleSelectionDialog<Customer>(
            title: 'اختر التاجر',
            items: merchants,
            labelBuilder: (c) => c.username));
    if (merchant != null) {
      setState(() {
        _selectedMerchantId = merchant.userid;
        _applyFilters();
      });
    }
  }
}

class _SimpleSelectionDialog<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T)? labelBuilder;

  const _SimpleSelectionDialog(
      {required this.title, required this.items, this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final label =
                labelBuilder != null ? labelBuilder!(item) : item.toString();
            return ListTile(
                title: Text(label), onTap: () => Navigator.pop(context, item));
          },
        ),
      ),
    );
  }
}

class _DriverSelectionDialog extends StatefulWidget {
  final List<Driver> drivers;
  const _DriverSelectionDialog({required this.drivers});

  @override
  State<_DriverSelectionDialog> createState() => _DriverSelectionDialogState();
}

class _DriverSelectionDialogState extends State<_DriverSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Driver> filteredDrivers = [];

  @override
  void initState() {
    super.initState();
    filteredDrivers = widget.drivers;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('اختر السائق',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  filteredDrivers = widget.drivers
                      .where((d) =>
                          (d.username?.toLowerCase() ?? '')
                              .contains(val.toLowerCase()) ||
                          (d.phone ?? '').contains(val))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن سائق...',
                prefixIcon: const Icon(Icons.search, color: primary),
                filled: true,
                fillColor: background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredDrivers.isEmpty
                  ? const Center(child: Text('لا يوجد سائقين مطابقين'))
                  : ListView.builder(
                      itemCount: filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = filteredDrivers[index];
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundColor: secprimary,
                              child: const Icon(Icons.person,
                                  color: Colors.white)),
                          title: Text(driver.username ?? 'بدون اسم'),
                          subtitle: Text(driver.phone ?? ''),
                          onTap: () => Navigator.pop(context, driver),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
