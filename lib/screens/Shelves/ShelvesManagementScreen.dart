import '../../main.dart';
import '../../models/Shelf.dart';
import '../../models/Shipment.dart';
import '../../shared/appProvider.dart';
import 'package:good_line_delivery/screens/ManageShipments/ShipmentDetails.dart';
import '../dashboard/header/showSideDrawerDialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShelvesManagementScreen extends StatefulWidget {
  const ShelvesManagementScreen({super.key});

  @override
  State<ShelvesManagementScreen> createState() =>
      _ShelvesManagementScreenState();
}

class _ShelvesManagementScreenState extends State<ShelvesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Shelf? selectedShelf;
  List<Shipment> selectedShipments = [];
  String _sortColumn = 'orderId';
  bool _sortAscending = true;

  // Get status color for shipments
  Color _getStatusColor(String status) {
    switch (status) {
      case 'تم التسليم':
        return Colors.green;
      case 'قيد التوصيل':
        return Colors.blue;
      case 'في المخزن':
        return Colors.orange;
      case 'ملغاة':
        return Colors.red;
      default:
        return Colors.red;
    }
  }

  TableRow _buildTableRow(String label, String value, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? primary.withOpacity(0.1) : null,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: isHeader ? primary : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: isHeader ? primary : Colors.black87,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final shelves = appProvider.shelves;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate grid columns based on screen width
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
            ? 3
            : 2;

    // Filter shelves based on search query
    final filteredShelves = searchQuery.isEmpty
        ? shelves
        : shelves
            .where((shelf) =>
                shelf.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                shelf.location
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.warehouse, size: 28, color: primary),
                  const SizedBox(width: 12),
                  const Text(
                    'إدارة الرفوف',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'إجمالي الرفوف: ${shelves.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Add new shelf button
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  _showAddShelfDialog(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'إضافة رف جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search field
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن رف...',
                  prefixIcon: Icon(Icons.search, color: primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),

            // Shelves list
            Expanded(
              child: Row(
                children: [
                  // Left side - Shelves list
                  Expanded(
                    flex: selectedShelf == null ? 1 : 1,
                    child: filteredShelves.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warehouse_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'لا يوجد رفوف',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'اضغط على "إضافة رف جديد" لبدء إنشاء الرفوف',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: filteredShelves.length,
                            itemBuilder: (context, index) {
                              final shelf = filteredShelves[index];
                              final isSelected = selectedShelf?.id == shelf.id;

                              // Count shipments by status

                              return FutureBuilder<List<Shipment>>(
                                  future:
                                      appProvider.getShipmentsOnShelf(shelf),
                                  builder: (context, asyncSnapshot) {
                                    final shipmentCount =
                                        asyncSnapshot.data?.length ?? 0;
                                    final shipments = asyncSnapshot.data ?? [];
                                    final statusCounts = <String, int>{};
                                    for (var shipment in shipments) {
                                      statusCounts[shipment.status] =
                                          statusCounts[shipment.status] ??
                                              0 + 1;
                                    }
                                    return Card(
                                      elevation: 4,
                                      shadowColor: primary.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: isSelected
                                            ? BorderSide(
                                                color: primary, width: 2)
                                            : BorderSide.none,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  colors: [
                                                    primary.withOpacity(0.1),
                                                    Colors.white
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    Colors.grey.shade50
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: () {
                                              setState(() {
                                                selectedShelf = shelf;
                                                selectedShipments = shipments;
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header with name and menu
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              shelf.name,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .location_on,
                                                                    size: 14,
                                                                    color: Colors
                                                                        .grey),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Expanded(
                                                                  child: Text(
                                                                    shelf
                                                                        .location,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .grey
                                                                          .shade600,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuButton<String>(
                                                        icon: Icon(
                                                            Icons.more_vert,
                                                            color: Colors.grey),
                                                        onSelected: (value) {
                                                          if (value == 'edit') {
                                                            _showEditShelfDialog(
                                                                context, shelf);
                                                          } else if (value ==
                                                              'delete') {
                                                            _confirmDeleteShelf(
                                                                context,
                                                                shelf.id!);
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (context) => [
                                                          const PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.edit,
                                                                    size: 18,
                                                                    color:
                                                                        primary),
                                                                SizedBox(
                                                                    width: 8),
                                                                Text('تعديل'),
                                                              ],
                                                            ),
                                                          ),
                                                          const PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .delete,
                                                                    size: 18,
                                                                    color: Colors
                                                                        .red),
                                                                SizedBox(
                                                                    width: 8),
                                                                Text('حذف'),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),

                                                  // Shelf info
                                                  Row(
                                                    children: [
                                                      if (shelf.capacity !=
                                                          null) ...[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .inventory_2,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                'سعة: ${shelf.capacity}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .blue,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                      ],
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: shipmentCount >
                                                                  0
                                                              ? Colors.green
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors.orange
                                                                  .withOpacity(
                                                                      0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              shipmentCount > 0
                                                                  ? Icons
                                                                      .local_shipping
                                                                  : Icons.inbox,
                                                              size: 14,
                                                              color:
                                                                  shipmentCount >
                                                                          0
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .orange,
                                                            ),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                              '$shipmentCount طرد',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: shipmentCount > 0
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .orange,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                            },
                          ),
                  ),

                  // Right side - Shelf details (if selected)
                  if (selectedShelf != null)
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'تفاصيل الرف: ${selectedShelf!.name}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      selectedShelf = null;
                                      selectedShipments = [];
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Shelf details table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                children: [
                                  _buildTableRow(
                                      'اسم الرف', selectedShelf!.name,
                                      isHeader: true),
                                  _buildTableRow(
                                      'الموقع', selectedShelf!.location),
                                  _buildTableRow(
                                      'السعة',
                                      selectedShelf!.capacity != null
                                          ? '${selectedShelf!.capacity}'
                                          : 'غير محدد'),
                                  _buildTableRow('عدد الطردات',
                                      '${selectedShipments.length} طرد'),
                                  if (selectedShelf!.description != null &&
                                      selectedShelf!.description!.isNotEmpty)
                                    _buildTableRow(
                                        'الوصف', selectedShelf!.description!),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'الشحنات على هذا الرف: ${selectedShipments.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: selectedShipments.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox,
                                              size: 48, color: Colors.grey),
                                          SizedBox(height: 16),
                                          Text(
                                            'لا توجد شحنات على هذا الرف',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SingleChildScrollView(
                                          child: DataTable(
                                            headingRowColor:
                                                MaterialStateProperty.all(
                                                    primary.withOpacity(0.1)),
                                            dataRowHeight: 60,
                                            columnSpacing: 20,
                                            columns: [
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'orderId',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.local_shipping,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'رقم الطرد',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn == 'orderId'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'username',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.person,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'العميل',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn ==
                                                                'username'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'status',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.flag,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'الحالة',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn == 'status'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'city', !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.location_city,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'المدينة',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn == 'city'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'weight',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.scale,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'الوزن',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn == 'weight'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'deliveryCost',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.attach_money,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'السعر',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn ==
                                                                'deliveryCost'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: InkWell(
                                                  onTap: () => _onSortColumn(
                                                      'driverName',
                                                      !_sortAscending),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.drive_eta,
                                                          size: 16,
                                                          color: primary),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'السائق',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      Icon(
                                                        _sortColumn == 'driverName'
                                                            ? (_sortAscending
                                                                ? Icons
                                                                    .arrow_upward
                                                                : Icons
                                                                    .arrow_downward)
                                                            : Icons.sort,
                                                        size: 16,
                                                        color: primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataColumn(
                                                label: Row(
                                                  children: [
                                                    Icon(Icons.info,
                                                        size: 16,
                                                        color: primary),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'تفاصيل',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            rows: _getSortedShipments(
                                                    selectedShipments)
                                                .map((shipment) {
                                              int index = _getSortedShipments(
                                                      selectedShipments)
                                                  .indexOf(shipment);
                                              return DataRow(
                                                color: WidgetStateProperty.all(
                                                  index % 2 == 0
                                                      ? Colors.white
                                                      : Colors.grey.shade50,
                                                ),
                                                cells: [
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        shipment.orderId,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      shipment.username ??
                                                          'غير محدد',
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                                shipment.status)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: _getStatusColor(
                                                                  shipment
                                                                      .status)
                                                              .withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        shipment.status,
                                                        style: TextStyle(
                                                          color:
                                                              _getStatusColor(
                                                                  shipment
                                                                      .status),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on,
                                                            size: 14,
                                                            color: Colors.grey),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          shipment.city ??
                                                              'غير محدد',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '${shipment.weight ?? 0} كغ',
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      '${shipment.deliveryCost ?? 0} دينار',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    shipment.driverName !=
                                                                null &&
                                                            shipment.driverName!
                                                                .isNotEmpty
                                                        ? Row(
                                                            children: [
                                                              Icon(Icons.person,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .blue),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                shipment
                                                                    .driverName!,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : const Text(
                                                            'غير محدد',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                  ),
                                                  DataCell(
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.info_outline,
                                                          color: primary,
                                                          size: 18),
                                                      onPressed: () {
                                                        _showShipmentDetails(
                                                            context, shipment);
                                                      },
                                                      tooltip: 'عرض التفاصيل',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sort function for shipments
  void _onSortColumn(String columnName, bool ascending) {
    setState(() {
      _sortColumn = columnName;
      _sortAscending = ascending;
    });
  }

  // Get sorted shipments
  List<Shipment> _getSortedShipments(List<Shipment> shipments) {
    shipments.sort((a, b) {
      int compare = 0;
      switch (_sortColumn) {
        case 'orderId':
          compare = a.orderId.compareTo(b.orderId);
          break;
        case 'username':
          compare = (a.username ?? '').compareTo(b.username ?? '');
          break;
        case 'status':
          compare = a.status.compareTo(b.status);
          break;
        case 'city':
          compare = (a.city ?? '').compareTo(b.city ?? '');
          break;
        case 'weight':
          compare = (a.weight ?? 0).compareTo(b.weight ?? 0);
          break;
        case 'deliveryCost':
          compare = (a.deliveryCost ?? 0).compareTo(b.deliveryCost ?? 0);
          break;
        case 'driverName':
          compare = (a.driverName ?? '').compareTo(b.driverName ?? '');
          break;
      }
      return _sortAscending ? compare : -compare;
    });
    return shipments;
  }

  void _showAddShelfDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final capacityController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة رف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الرف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'السعة (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة')),
                );
                return;
              }

              final shelf = Shelf(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                capacity: capacityController.text.isNotEmpty
                    ? int.tryParse(capacityController.text)
                    : null,
                description: descriptionController.text.trim(),
                shipmentIds: [],
              );

              try {
                Provider.of<AppProvider>(context, listen: false)
                    .addShelf(shelf);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الرف بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء إضافة الرف: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShelf(BuildContext context, String shelfId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الرف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AppProvider>(context, listen: false)
                    .deleteShelf(shelfId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الرف بنجاح')),
                );
                // Clear selected shelf if it was the one being deleted
                if (selectedShelf?.id == shelfId) {
                  setState(() {
                    selectedShelf = null;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء حذف الرف: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showEditShelfDialog(BuildContext context, Shelf shelf) {
    final nameController = TextEditingController(text: shelf.name);
    final locationController = TextEditingController(text: shelf.location);
    final capacityController = TextEditingController(
        text: shelf.capacity != null ? shelf.capacity.toString() : '');
    final descriptionController =
        TextEditingController(text: shelf.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرف'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الرف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'السعة (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  locationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة')),
                );
                return;
              }

              final updatedShelf = Shelf(
                id: shelf.id,
                name: nameController.text.trim(),
                location: locationController.text.trim(),
                capacity: capacityController.text.isNotEmpty
                    ? int.tryParse(capacityController.text)
                    : null,
                description: descriptionController.text.trim(),
                shipmentIds: shelf.shipmentIds,
              );

              try {
                Provider.of<AppProvider>(context, listen: false)
                    .updateShelf(updatedShelf);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الرف بنجاح')),
                );
                // Update selected shelf if it was the one being edited
                if (selectedShelf?.id == shelf.id) {
                  setState(() {
                    selectedShelf = updatedShelf;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ أثناء تحديث الرف: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showShipmentDetails(BuildContext context, Shipment shipment) {
    showSideDrawerDialog(
      context: context,
      side: DrawerSide.left,
      width: MediaQuery.of(context).size.width > 850
          ? 850
          : MediaQuery.of(context).size.width,
      child: ShipmentDetails(shipment: shipment),
    );
  }
}
