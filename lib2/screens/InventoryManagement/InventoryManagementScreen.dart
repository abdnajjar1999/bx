import '../../main.dart';
import '../../models/Inventory.dart';
import '../../models/Shipment.dart';
import '../../shared/appProvider.dart';
import '../../shared/PrintHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Inventory? inventory;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final customers = appProvider.customers;
    final selectedCustomer = appProvider.selectedCustomer;

    // Filter customers based on search query
    final filteredCustomers = searchQuery.isEmpty
        ? customers
        : customers
            .where((customer) =>
                customer.username
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                customer.phoneNumber
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
              margin: const EdgeInsets.only(bottom: 16),
              child: const Text(
                'إدارة المخزون',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Customer selection section
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                  const Text(
                    'اختر العميل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن عميل...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Customers list
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: filteredCustomers.isEmpty
                        ? const Center(child: Text('لا يوجد عملاء'))
                        : ListView.separated(
                            itemCount: filteredCustomers.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final isSelected =
                                  selectedCustomer?.userid == customer.userid;

                              return ListTile(
                                title: Text(customer.username),
                                subtitle: Text(customer.phoneNumber),
                                selected: isSelected,
                                tileColor: isSelected
                                    ? Color(0xFF4F46E5).withOpacity(0.1)
                                    : null,
                                onTap: () {
                                  appProvider.setSelectedCustomer(customer);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Show inventory if customer is selected
            if (selectedCustomer != null)
              Expanded(
                child: StreamBuilder<Inventory>(
                  stream: appProvider
                      .getCustomerInventoryStream(selectedCustomer.userid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    inventory = snapshot.data;
                    final items = inventory?.items ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'مخزون ${selectedCustomer.username}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة منتج'),
                              onPressed: () {
                                _showAddItemDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Add button for showing shipments with items
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.local_shipping),
                            label: const Text('عرض الشحنات مع البضائع'),
                            onPressed: () {
                              _showDateRangePickerAndShipments(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Text('لا يوجد منتجات في المخزون'))
                              : ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(item.name),
                                        subtitle: Text(
                                            'الكمية: ${item.quantity}${item.price != null ? ' - السعر: ${item.price}' : ''}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Color(0xFF4F46E5)),
                                              onPressed: () {
                                                _showEditItemDialog(
                                                    context, item);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                _confirmDeleteItem(
                                                    context, item.id!);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة منتج جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                  quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة')),
                );
                return;
              }

              final item = InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? 0,
                price: priceController.text.isNotEmpty
                    ? double.tryParse(priceController.text)
                    : null,
                description: descriptionController.text.trim(),
              );

              Provider.of<AppProvider>(context, listen: false)
                  .addInventoryItem(item);
              Navigator.of(context).pop();
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

  void _showEditItemDialog(BuildContext context, InventoryItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController =
        TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(
        text: item.price != null ? item.price.toString() : '');
    final descriptionController =
        TextEditingController(text: item.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المنتج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر (اختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                  quantityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة')),
                );
                return;
              }

              final updatedItem = InventoryItem(
                id: item.id,
                name: nameController.text.trim(),
                quantity: int.tryParse(quantityController.text) ?? 0,
                price: priceController.text.isNotEmpty
                    ? double.tryParse(priceController.text)
                    : null,
                description: descriptionController.text.trim(),
                createdAt: item.createdAt,
              );

              Provider.of<AppProvider>(context, listen: false)
                  .updateInventoryItem(updatedItem);
              Navigator.of(context).pop();
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

  void _confirmDeleteItem(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false)
                  .deleteInventoryItem(itemId);
              Navigator.of(context).pop();
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

  void _showDateRangePickerAndShipments(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (appProvider.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار عميل أولاً')),
      );
      return;
    }

    // Show date range picker
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.input,
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Fetch shipments with items in the selected date range
        final shipments = await appProvider.getCustomerShipmentsWithItems(
          appProvider.selectedCustomer!.userid,
          dateRange.start,
          dateRange.end,
        );

        // Close loading dialog
        Navigator.of(context).pop();

        // Show shipments in bottom sheet
        _showShipmentsSheet(context, shipments, dateRange);
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e')),
        );
      }
    }
  }

  void _showShipmentsSheet(
      BuildContext context, List<Shipment> shipments, DateTimeRange dateRange) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الشحنات مع البضائع',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة التقرير'),
                      onPressed: () async {
                        final appProvider =
                            Provider.of<AppProvider>(context, listen: false);
                        final inventoryItems = inventory?.items ?? [];
                        final customerName =
                            appProvider.selectedCustomer?.username ?? '';

                        final printHandler = PrintHandler();
                        await printHandler.printInventoryAndShipmentsDocument(
                          inventoryItems,
                          shipments,
                          customerName,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'من ${dateRange.start.day}/${dateRange.start.month}/${dateRange.start.year} إلى ${dateRange.end.day}/${dateRange.end.month}/${dateRange.end.year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Shipments list
            Expanded(
              child: shipments.isEmpty
                  ? const Center(
                      child: Text('لا توجد شحنات مع بضائع في هذه الفترة'),
                    )
                  : ListView.builder(
                      itemCount: shipments.length,
                      itemBuilder: (context, index) {
                        final shipment = shipments[index];
                        final selectedItemsCount =
                            shipment.selectedItems?.length ?? 0;
                        final totalQuantity = shipment.selectedItems?.values
                                .fold(0, (sum, qty) => sum + qty) ??
                            0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            title: SelectableText('طلب #${shipment.orderId}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'التاريخ: ${shipment.createdAt.day}/${shipment.createdAt.month}/${shipment.createdAt.year}'),
                                Text('الحالة: ${shipment.status}'),
                                Text(
                                    'عدد البضائع: $selectedItemsCount | إجمالي الكمية: $totalQuantity'),
                              ],
                            ),
                            children: [
                              if (shipment.selectedItems != null)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'البضائع المحددة:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...shipment.selectedItems!.entries.map(
                                        (entry) {
                                          final itemId = entry.key;
                                          final quantity = entry.value;

                                          // Find item name from inventory
                                          String itemName = itemId;
                                          if (inventory?.items != null) {
                                            try {
                                              final item =
                                                  inventory!.items.firstWhere(
                                                (item) => item.id == itemId,
                                              );
                                              itemName = item.name;
                                            } catch (e) {
                                              // Item not found in current inventory
                                            }
                                          }

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(itemName),
                                                Text('الكمية: $quantity'),
                                              ],
                                            ),
                                          );
                                        },
                                      ).toList(),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              'المستلم: ${shipment.recipientName}'),
                                          Text(
                                              'المبلغ: ${shipment.codAmount} دينار'),
                                        ],
                                      ),
                                      if (shipment.notes.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                              'ملاحظات: ${shipment.notes}'),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
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
