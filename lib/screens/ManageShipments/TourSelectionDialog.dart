import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PriceCalculators.dart';
import '../../models/Shipment.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import 'DeliveryReceiveDialog.dart'; // For showBarcodeScannerDialog and helpers
import 'widget/CustomScrollbar.dart';
import 'widget/SearchableDropdown.dart';

class TourSelectionDialog extends StatefulWidget {
  const TourSelectionDialog({Key? key}) : super(key: key);

  @override
  _TourSelectionDialogState createState() => _TourSelectionDialogState();
}

void showTourDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TourSelectionDialog(),
  );
}

class _TourSelectionDialogState extends State<TourSelectionDialog> {
  Set<Shipment> tourShipments = {};
  Set<String> selectedOrderIds = {};
  bool isLoading = false;
  String? selectedTourId;
  Map<String, dynamic>? selectedTourData;

  // Per-order driverPrice override controllers: orderId -> TextEditingController
  final Map<String, TextEditingController> _driverPriceControllers = {};

  // Bulk edit
  final TextEditingController _bulkPriceController = TextEditingController();
  bool _bulkApplyToSelected = false; // false = all displayed, true = selected only

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _driverSearchController = TextEditingController();
  bool isExpanded = true;
  Driver? assignmentDriver;

  // تابات الفلترة حسب الحالة
  int _selectedTabIndex = 0;
  final List<Map<String, dynamic>> _filterTabs = [
    {'label': 'الكل', 'icon': Icons.all_inbox},
    {'label': 'في الفرع', 'icon': Icons.store},
    {'label': 'مؤجلة لوقت آخر', 'icon': Icons.schedule},
    {'label': 'مرجعة عند الفرع', 'icon': Icons.assignment_return},
  ];

  List<Shipment> get _filteredByTab {
    switch (_selectedTabIndex) {
      case 1: // في الفرع
        return tourShipments
            .where((o) => o.status == 'في الفرع')
            .toList();
      case 2: // مؤجلة لوقت آخر
        return tourShipments
            .where((o) => o.status == 'مؤجلة لوقت آخر')
            .toList();
      case 3: // مرجعة عند الفرع
        return tourShipments
            .where((o) =>
                o.status == 'تم إرجاعها' &&
                o.orderPossession == OrderPossession.branch)
            .toList();
      default:
        return tourShipments.toList();
    }
  }

  /// Returns the effective driverPrice for a shipment (controller value or shipment.driverPrice).
  double _effectiveDriverPrice(Shipment s) {
    final ctrl = _driverPriceControllers[s.orderId];
    if (ctrl != null) {
      return double.tryParse(ctrl.text) ?? s.driverPrice ?? 0.0;
    }
    return s.driverPrice ?? 0.0;
  }

  /// Totals across SELECTED orders only.
  double get _selectedTotalDriverPrice {
    return _filteredByTab
        .where((s) => selectedOrderIds.contains(s.orderId))
        .fold(0.0, (sum, s) => sum + _effectiveDriverPrice(s));
  }

  double get _selectedTotalCod {
    return _filteredByTab
        .where((s) => selectedOrderIds.contains(s.orderId))
        .fold(0.0, (sum, s) => sum + s.codAmount);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    isExpanded = screenWidth > 768;
  }

  /// Applies [price] to all displayed shipments, or only selected ones.
  void _applyBulkPrice(double price) {
    final targets = _bulkApplyToSelected
        ? _filteredByTab
            .where((s) => selectedOrderIds.contains(s.orderId))
            .toList()
        : _filteredByTab;
    setState(() {
      for (final s in targets) {
        _driverPriceControllers[s.orderId]?.text =
            price.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    for (var ctrl in _driverPriceControllers.values) {
      ctrl.dispose();
    }
    _bulkPriceController.dispose();
    _driverSearchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _loadTourOrders(DocumentSnapshot tourDoc) {
    setState(() {
      selectedTourId = tourDoc.id;
      selectedTourData = tourDoc.data() as Map<String, dynamic>;
      isLoading = true;
      selectedOrderIds.clear();

      // Pre-select tour driver for assignment
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final tourDriverId = selectedTourData?['driverId'];
      if (tourDriverId != null) {
        assignmentDriver = appProvider.drivers
            .where((d) => d.userid == tourDriverId)
            .firstOrNull;
      } else {
        assignmentDriver = null;
      }
    });

    final List<String> areas =
        List<String>.from(selectedTourData?['areas'] ?? []);

    // Firestore 'whereIn' supports max 30 elements — split into chunks
    final List<List<String>> areaChunks = [];
    if (areas.isEmpty) {
      areaChunks.add(['']);
    } else {
      for (var i = 0; i < areas.length; i += 30) {
        areaChunks.add(
            areas.sublist(i, i + 30 > areas.length ? areas.length : i + 30));
      }
    }

    List<Future<QuerySnapshot>> queryFutures = areaChunks.map((chunk) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('city', whereIn: chunk)
          .get();
    }).toList();

    Future.wait(queryFutures).then((queryResults) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      List<Shipment> allOrders = [];
      for (var snapshot in queryResults) {
        allOrders.addAll(snapshot.docs
            .map((e) => Shipment.fromMap(e.data() as Map<String, dynamic>)));
      }

      // Filter to: في الفرع | مؤجلة لوقت آخر | تم إرجاعها + branch
      List<Shipment> filtered = allOrders
          .where((order) =>
              (order.status == "في الفرع" ||
                  order.status == "مؤجلة لوقت آخر" ||
                  (order.status == "تم إرجاعها" &&
                      order.orderPossession == OrderPossession.branch)))
          .toList();

      // Apply getShipmentsWithDriverPrice using driver shipping routes
      List<ShippingRoute> driverRoutes = [];
      if (appProvider.driverShippingRoutes.isNotEmpty) {
        driverRoutes = appProvider.driverShippingRoutes.first.shippingRoute;
      }
      List<Shipment> withPrices =
          Shipment.getShipmentsWithDriverPrice(filtered, driverRoutes);

      // Dispose old controllers and build new ones
      for (var ctrl in _driverPriceControllers.values) {
        ctrl.dispose();
      }
      _driverPriceControllers.clear();
      for (var s in withPrices) {
        _driverPriceControllers[s.orderId] = TextEditingController(
          text: (s.driverPrice ?? 0.0).toStringAsFixed(0),
        );
      }

      setState(() {
        tourShipments = withPrices.toSet();
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
        // Resolve the effective driverPrice for this order
        final ctrl = _driverPriceControllers[orderId];
        double? overridePrice;
        if (ctrl != null) {
          overridePrice = double.tryParse(ctrl.text);
        }

        await appProvider.assignDriver(
          orderId,
          assignmentDriver!,
          driverPrice: overridePrice,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين الطرود للسائق بنجاح')));

      setState(() {
        tourShipments.removeWhere((s) => selectedOrderIds.contains(s.orderId));
        // Clean up disposed controllers
        for (var id in selectedOrderIds) {
          _driverPriceControllers[id]?.dispose();
          _driverPriceControllers.remove(id);
        }
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
                      // Sidebar for Tours
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isExpanded ? 300 : 0,
                        decoration: BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: isExpanded ? _buildTourSidebar() : null,
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

  Widget _buildTourSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('اختر الجولة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tours').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final tours = snapshot.data!.docs;
              return ListView.builder(
                itemCount: tours.length,
                itemBuilder: (context, index) {
                  final tour = tours[index];
                  final data = tour.data() as Map<String, dynamic>;
                  final isSelected = selectedTourId == tour.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.red.shade50,
                    onTap: () => _loadTourOrders(tour),
                    title: Text(data['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'السائق: ${data['driverName'] ?? 'غير معين'}',
                        style: const TextStyle(fontSize: 12)),
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.red : Colors.grey.shade200,
                      child: Icon(Icons.route,
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
        if (selectedTourData != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'عرض الطرود في مناطق: ${List<String>.from(selectedTourData!["areas"] ?? []).join(", ")} (${_filteredByTab.length} / ${tourShipments.length} طرد)',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        // تابات الفلترة حسب الحالة
        if (selectedTourId != null)
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filterTabs.length, (index) {
                  final tab = _filterTabs[index];
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedTabIndex = index;
                      selectedOrderIds.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFDC2626)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFDC2626)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        // ── Bulk-edit bar ──────────────────────────────────────────────
        if (selectedTourId != null && !isLoading && tourShipments.isNotEmpty)
          _buildBulkEditBar(),
        Expanded(
          child: CustomScrollbar(
            verticalScrollController: _verticalScrollController,
            horizontalScrollController: _horizontalScrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedTourId == null
                      ? const Center(
                          child: Text('الرجاء اختيار جولة من القائمة الجانبية'))
                      : _buildShipmentsTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkEditBar() {
    final displayedCount = _filteredByTab.length;
    final selectedCount = selectedOrderIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade200),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('تعديل سعر السائق بالجملة:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _bulkPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'السعر',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 7),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: Colors.orange, width: 1.5)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Scope toggle
          GestureDetector(
            onTap: () => setState(
                () => _bulkApplyToSelected = !_bulkApplyToSelected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _bulkApplyToSelected
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _bulkApplyToSelected
                      ? Colors.blue
                      : Colors.grey.shade400,
                ),
              ),
              child: Text(
                _bulkApplyToSelected
                    ? 'المحدد فقط ($selectedCount)'
                    : 'الكل ($displayedCount)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _bulkApplyToSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {
              final value =
                  double.tryParse(_bulkPriceController.text);
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('الرجاء إدخال سعر صحيح')));
                return;
              }
              _applyBulkPrice(value);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('تطبيق', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentsTable() {
    final displayedShipments = _filteredByTab;
    if (displayedShipments.isEmpty) {
      return const Center(
        child: Text('لا توجد طرود في هذه الفئة',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 1100),
      child: Table(
        border: TableBorder.all(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8)),
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FixedColumnWidth(60),
          // other columns flex
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              Checkbox(
                value: selectedOrderIds.length == displayedShipments.length &&
                    displayedShipments.isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedOrderIds
                          .addAll(displayedShipments.map((e) => e.orderId));
                    } else {
                      selectedOrderIds.clear();
                    }
                  });
                },
                activeColor: const Color(0xFFDC2626),
              ),
              _buildTableHeader('عدد الطرود'),
              _buildTableHeader('رقم التتبع'),
              _buildTableHeader('المدينة'),
              _buildTableHeader('المستلم'),
              _buildTableHeader('المرسل'),
              _buildTableHeader('الحالة'),
              _buildTableHeader('مبلغ التحصيل'),
              _buildTableHeader('سعر السائق'),
            ],
          ),
          ...displayedShipments.map((s) => _buildShipmentRow(s)).toList(),
        ],
      ),
    );
  }

  TableRow _buildShipmentRow(Shipment shipment) {
    bool isSelected = selectedOrderIds.contains(shipment.orderId);
    final ctrl = _driverPriceControllers[shipment.orderId];

    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
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
        _buildTableCell(shipment.username ?? ''),
        _buildTableCell(shipment.status),
        _buildTableCell(shipment.codAmount.toStringAsFixed(0)),
        // Driver price editable cell
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: ctrl != null
              ? SizedBox(
                  width: 90,
                  child: TextField(
                    controller: ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFFDC2626), width: 1.5)),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                    ),
                    onChanged: (_) => setState(() {}), // refresh totals
                  ),
                )
              : const Text('-',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12)),
        ),
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
    final selectedCount = selectedOrderIds.length;
    final totalDriverPrice = _selectedTotalDriverPrice;
    final totalCod = _selectedTotalCod;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Totals row (visible when something is selected)
          if (selectedCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalChip(
                    icon: Icons.check_box,
                    label: 'المحدد',
                    value: '$selectedCount طرد',
                    color: Colors.blue,
                  ),
                  _buildTotalChip(
                    icon: Icons.monetization_on_outlined,
                    label: 'إجمالي التحصيل',
                    value: '${totalCod.toStringAsFixed(0)} د.أ',
                    color: Colors.green,
                  ),
                  _buildTotalChip(
                    icon: Icons.directions_car_outlined,
                    label: 'إجمالي سعر السائق',
                    value: '${totalDriverPrice.toStringAsFixed(0)} د.أ',
                    color: const Color(0xFFDC2626),
                  ),
                  _buildTotalChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'صافي العميل',
                    value:
                        '${(totalCod - totalDriverPrice).toStringAsFixed(0)} د.أ',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(isExpanded
                    ? Icons.arrow_forward
                    : Icons.arrow_back),
                onPressed: () =>
                    setState(() => isExpanded = !isExpanded),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.barcode_reader),
                label: const Text('إقرأ باركود'),
                onPressed: () async {
                  final barcode =
                      await showBarcodeScannerDialog(context);
                  if (barcode != null) {
                    Provider.of<AppProvider>(context, listen: false)
                        .getOrder(barcode)
                        .then((order) {
                      if (order != null) {
                        setState(() {
                          tourShipments.add(order);
                          _driverPriceControllers[order.orderId] =
                              TextEditingController(
                            text: (order.driverPrice ?? 0.0)
                                .toStringAsFixed(0),
                          );
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('لا يوجد طرد بهذا الباركود')));
                      }
                    });
                  }
                },
              ),
              const Spacer(),
              if (selectedTourId != null)
                SizedBox(
                  width: 250,
                  child: SearchableDropdown<Driver>(
                    label: 'سائق',
                    value: assignmentDriver,
                    items: Provider.of<AppProvider>(context, listen: false)
                        .drivers,
                    searchController: _driverSearchController,
                    isRequired: false,
                    onChanged: (driver) {
                      setState(() => assignmentDriver = driver);
                    },
                    prefixIcon: Icons.person,
                  ),
                ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Text('$selectedCount طرد'),
                label: const Text('تعيين'),
                onPressed:
                    selectedOrderIds.isEmpty ? null : _assignOrders,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ],
    );
  }
}
