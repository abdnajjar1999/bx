import 'dart:async';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/Shipment.dart';
import '../../models/customer.dart';
import '../../shared/appProvider.dart';
import '../../shared/PrintHelper.dart';
import '../../shared/ExcelImportHandler.dart';
import '../../utils/file_handler.dart';

class AllReturnedOrders extends StatefulWidget {
  final int sectionIndex;
  const AllReturnedOrders({super.key, this.sectionIndex = 16});

  @override
  State<AllReturnedOrders> createState() => _AllReturnedOrdersState();
}

class _AllReturnedOrdersState extends State<AllReturnedOrders> {
  List<Shipment> returnedShipments = [];
  List<Shipment> filteredShipments = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool isProcessing = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _limit = 50;
  StreamSubscription<QuerySnapshot>? _shipmentSubscription;

  DateTimeRange? _dateRange;
  String? _selectedCity;
  String? _selectedMerchantId;
  Set<Shipment> selectedOrders = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    loadReturnedShipments();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isFetchingMore && returnedShipments.length >= _limit) {
        setState(() {
          isFetchingMore = true;
          _limit += 50;
        });
        loadReturnedShipments();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _shipmentSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AllReturnedOrders oldWidget) {
    if (oldWidget.sectionIndex != widget.sectionIndex) {
      loadReturnedShipments();
    }
    super.didUpdateWidget(oldWidget);
  }

  String get dynamicTitle {
    switch (widget.sectionIndex) {
      case 37:
        return 'مع السائق';
      case 38:
        return 'مسلمة إلى المرسل';
      default:
        return 'مرتجع للعميل';
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
    });
  }

  Future<void> loadReturnedShipments() async {
    try {
      _shipmentSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('orders')
          .where('hasReturn', isEqualTo: true);

      if (widget.sectionIndex == 37) {
        query = query.where('orderPossession', isEqualTo: 'driverReturning');
      } else {
        query = query.where('orderPossession', isEqualTo: 'customer');
      }

      query = query.limit(_limit);

      _shipmentSubscription = query.snapshots().listen((snapshot) {
        if (!mounted) return;
        setState(() {
          returnedShipments = snapshot.docs
              .map(
                  (doc) => Shipment.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          _applyFilters();
          isLoading = false;
          isFetchingMore = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات')),
      );
    }
  }

  Future<void> _handleDeliverToSender() async {
    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('حدد طلبات أولاً')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تحذير',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
            'هل أنت متأكد من تسليم ${selectedOrders.length} طلب إلى المرسل؟',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد وتسليم',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var shipment in selectedOrders) {
        final orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc(shipment.orderId);
        batch.update(orderRef, {'orderPossession': 'customer'});
      }
      await batch.commit();

      final count = selectedOrders.length;
      setState(() => selectedOrders.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تسليم $count طلب إلى المرسل بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء العملية')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
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
                : _buildOrderTable(),
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
            const SizedBox(width: 8),
            if (widget.sectionIndex == 37)
              ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('تسليم إلى المرسل',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECAAA4)),
                onPressed: isProcessing ? null : _handleDeliverToSender,
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
              hintText: 'ابحث برقم الطلب، العميل، أو المتجر...',
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
            controller: _scrollController,
            child: Column(
              children: [
                DataTable(
                  headingRowColor:
                      MaterialStateProperty.all(Colors.grey.shade50),
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('تحديد')),
                    DataColumn(
                        label: Text('باركود الطرد',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('حاله الطلب',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('طريقه الدفع',
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green))),
                          DataCell(Text(shipment.status)),
                          DataCell(Text(shipment.paymentMethod)),
                          DataCell(Text('${shipment.deliveryCost} د.أ')),
                          DataCell(Text('${shipment.codAmount} د.أ')),
                          DataCell(Text(shipment.recipientName)),
                          DataCell(Text(shipment.phoneNumber)),
                          DataCell(Text(intl.DateFormat('yyyy-MM-dd')
                              .format(shipment.createdAt))),
                          DataCell(Text(shipment.returnOrderDate != null
                              ? intl.DateFormat('yyyy-MM-dd')
                                  .format(shipment.returnOrderDate!)
                              : 'غير محدد')),
                        ]);
                  }).toList(),
                ),
                if (isFetchingMore)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: primary),
                  ),
              ],
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
