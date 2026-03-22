import 'package:flutter/material.dart';
import 'package:sadrad/main.dart';
import '../../models/supply_order.dart';
import '../../shared/appProvider.dart';
import 'package:provider/provider.dart';
import '../../models/Driver.dart';
import '../../shared/constants.dart';

class SupplyOrdersScreen extends StatefulWidget {
  const SupplyOrdersScreen({super.key});

  @override
  State<SupplyOrdersScreen> createState() => _SupplyOrdersScreenState();
}

class _SupplyOrdersScreenState extends State<SupplyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider.of<AppProvider>(context, listen: false).listenToSupplyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // Filter or use supplyOrders from AppProvider
    // For now, assuming appProvider.supplyOrders exists (will add next)
    // final orders = appProvider.supplyOrders;
    // Mock data for initial UI test if needed, or wait for stream

    return Scaffold(
      backgroundColor: background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  Icon(Icons.shopping_basket, size: 28, color: primary),
                  const SizedBox(width: 12),
                  const Text(
                    'طلبات التوريد',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Add metrics or filter buttons here if needed
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Orders List
            Expanded(
              child: StreamBuilder<List<SupplyOrder>>(
                  stream: appProvider.firebaseHelper.getSupplyOrdersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                    }

                    final orders = snapshot.data ?? [];

                    if (orders.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات توريد',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, order, appProvider);
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, SupplyOrder order, AppProvider appProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${order.id.substring(0, 8)}', // Display simplified ID
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('العميل: ${order.userName ?? "غير معروف"}'),
              ],
            ),
            const SizedBox(height: 4),
            if (order.createdAt != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                      'التاريخ: ${order.createdAt!.split('T')[0]}'), // Simple formatting
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'العناصر:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...order.items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(right: 16.0, top: 4.0),
                      child: Text('- ${item.title} (الكمية: ${item.quantity})'),
                    ))
                .toList(),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.driverId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Chip(
                      avatar: const Icon(Icons.drive_eta, size: 16),
                      label: Text('السائق: ${order.driverName}'),
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                if (order.status == SupplyOrderStatus.pending) ...[
                  if (order.driverId == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('تعيين سائق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _showAssignDriverDialog(context, order, appProvider),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('قبول الطلب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors
                          .green, // Disabled color handled by onPressed being null? No, explicit check best.
                      foregroundColor: Colors.white,
                    ),
                    // Only enable if driver is assigned
                    onPressed: order.driverId == null
                        ? null
                        : () {
                            _confirmAcceptOrder(context, order, appProvider);
                          },
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SupplyOrderStatus status) {
    Color color;
    String label;
    switch (status) {
      case SupplyOrderStatus.pending:
        color = Colors.orange;
        label = 'قيد الانتظار';
        break;
      case SupplyOrderStatus.accepted:
        color = Colors.green;
        label = 'مقبول';
        break;
      default:
        color = Colors.grey;
        label = 'غير معروف';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  void _showAssignDriverDialog(
      BuildContext context, SupplyOrder order, AppProvider appProvider) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('تعيين سائق'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: appProvider.drivers.length,
                  itemBuilder: (context, index) {
                    final driver = appProvider.drivers[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(driver.username ?? 'Unknown'),
                      subtitle: Text(driver.phone ?? ''),
                      onTap: () async {
                        // Update Logic Here
                        try {
                          // We need a method in AppProvider/FirebaseHelper to update JUST the driver
                          // reusing updateSupplyOrder for now.
                          final updatedOrder = SupplyOrder(
                            id: order.id,
                            items: order.items,
                            status: order.status,
                            userId: order.userId,
                            userName: order.userName,
                            createdAt: order.createdAt,
                            driverId: driver.userid,
                            driverName: driver.username,
                          );

                          await appProvider.firebaseHelper
                              .updateSupplyOrder(updatedOrder);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم تعيين السائق بنجاح')),
                          );
                        } catch (e) {
                          print('Error assigning driver: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ في تعيين السائق: $e')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ],
            ));
  }

  void _confirmAcceptOrder(
      BuildContext context, SupplyOrder order, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد قبول الطلب'),
        content:
            const Text('هل أنت متأكد من قبول هذا الطلب؟ سيتم إشعار السائق.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedOrder = SupplyOrder(
                  id: order.id,
                  items: order.items,
                  status: SupplyOrderStatus.accepted, // Update Status
                  userId: order.userId,
                  userName: order.userName,
                  createdAt: order.createdAt,
                  driverId: order.driverId,
                  driverName: order.driverName,
                );

                await appProvider.firebaseHelper
                    .updateSupplyOrder(updatedOrder);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم قبول الطلب بنجاح')),
                );
              } catch (e) {
                print('Error accepting order: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في قبول الطلب: $e')),
                );
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
