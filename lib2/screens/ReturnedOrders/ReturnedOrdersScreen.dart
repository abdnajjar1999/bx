import 'dart:math';
import 'package:intl/intl.dart' as intl;
import 'package:sadrad/shared/PrintHelper.dart';
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

class ReturnedOrdersScreen extends StatefulWidget {
  const ReturnedOrdersScreen({super.key});

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

      // Clear selected orders if they are no longer in filtered list
      selectedOrders.removeWhere((s) => !filteredShipments.contains(s));
    });
  }

  Future<void> loadReturnedShipments() async {
    try {
      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'تم إرجاعها')
          .where('cashPossession', isEqualTo: 'customer')
          .where('orderPossession', isEqualTo: 'branch')
          .snapshots()
          .listen((snapshot) {
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
        title: const Text('مرتجع في الفرع',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primary,
        elevation: 0,
        actions: [
          if (filteredShipments.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (selectedOrders.length == filteredShipments.length) {
                    selectedOrders.clear();
                  } else {
                    selectedOrders = filteredShipments.toSet();
                  }
                });
              },
              child: Text(
                selectedOrders.length == filteredShipments.length
                    ? 'إلغاء الكل'
                    : 'تحديد الكل',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTopStats(),
          _buildFilterBar(appProvider),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _buildOrderList(),
          ),
          if (selectedOrders.isNotEmpty) _buildSelectionActionFrame(),
        ],
      ),
    );
  }

  Widget _buildTopStats() {
    double totalCost =
        filteredShipments.fold(0, (sum, item) => sum + item.deliveryCost);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('إجمالي الطلبات', '${filteredShipments.length}',
              Icons.inventory_2),
          _buildStatCard(
              'مجموع تكاليف الإرجاع',
              '${totalCost.toStringAsFixed(1)} د.أ',
              Icons.account_balance_wallet),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: secprimary, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'ابحث برقم الطلب، العميل، التاجر، أو الهاتف...',
              prefixIcon: const Icon(Icons.search, color: primary),
              filled: true,
              fillColor: background.withOpacity(0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
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
                          .firstWhere((c) => c.userid == _selectedMerchantId)
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primary : background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : primary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    if (filteredShipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('لا يوجد طلبات تطابق الفلتر',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredShipments.length,
      itemBuilder: (context, index) {
        final shipment = filteredShipments[index];
        final isSelected = selectedOrders.contains(shipment);

        return _buildShipmentCard(shipment, isSelected);
      },
    );
  }

  Widget _buildShipmentCard(Shipment shipment, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isSelected ? primary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected)
              selectedOrders.remove(shipment);
            else
              selectedOrders.add(shipment);
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(shipment.orderId,
                        style: const TextStyle(
                            color: primary, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: shipment.paymentMethod == 'تحصيل'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shipment.paymentMethod,
                          style: TextStyle(
                            fontSize: 10,
                            color: shipment.paymentMethod == 'تحصيل'
                                ? Colors.green
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.person, 'المستلم', shipment.recipientName),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.phone, 'الهاتف', shipment.phoneNumber),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on, 'العنوان',
                            '${shipment.city} - ${shipment.addressDescription}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.store, 'المتجر',
                            shipment.username ?? 'غير معروف'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.payments, 'تكلفة المرتجع',
                            '${shipment.deliveryCost} د.أ',
                            textColor: Colors.red),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.money_off, 'COD المرتجع',
                            '${shipment.codAmount} د.أ'),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.calendar_today,
                            'تاريخ الإرجاع',
                            shipment.returnOrderDate != null
                                ? intl.DateFormat('yyyy-MM-dd')
                                    .format(shipment.returnOrderDate!)
                                : 'غير محدد'),
                      ],
                    ),
                  ),
                ],
              ),
              if (shipment.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(shipment.notes,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Colors.black, fontSize: 13, fontFamily: 'Almarai'),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                TextSpan(
                    text: value,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionActionFrame() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primary,
                radius: 20,
                child: Text('${selectedOrders.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              const Text('طلبات محددة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
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
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => setState(() => selectedOrders.clear()),
                tooltip: 'إلغاء التحديد',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_shipping, color: Colors.white),
              label: const Text('تعيين للسائق',
                  style: TextStyle(color: Colors.white)),
              onPressed: isProcessing ? null : handleAssignToDriver,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
          _SimpleSelectionDialog(title: 'اختر المدينة', items: cities),
    );
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
        labelBuilder: (c) => c.username,
      ),
    );
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
              title: Text(label),
              onTap: () => Navigator.pop(context, item),
            );
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: primary.withOpacity(0.1),
                              backgroundImage: (driver.profileImage != null &&
                                      driver.profileImage!.isNotEmpty)
                                  ? NetworkImage(driver.profileImage!)
                                  : null,
                              child: (driver.profileImage == null ||
                                      driver.profileImage!.isEmpty)
                                  ? const Icon(Icons.person, color: primary)
                                  : null,
                            ),
                            title: Text(driver.username ?? 'غير معروف',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(driver.phone ?? '',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.chevron_left, color: primary),
                            onTap: () => Navigator.pop(context, driver),
                          ),
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
