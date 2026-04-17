import 'showSideDrawerDialog.dart';
import '../../../main.dart';
import '../../ManageShipments/ShipmentDetails.dart';
import 'NotificationButton.dart';
import '../../../shared/appProvider.dart';
import '../../../sadrad/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../AddOrder/AddOrderFormOne.dart';
import '../../settings/SettingsScreen.dart';

class header extends StatelessWidget {
  const header({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SadradColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
          ),
          child: Row(
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'البحث عن رقم الطرد...',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    onSubmitted: (value) =>
                        _handleSearch(context, appProvider, value),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Action Buttons
              Row(
                children: [
                  NotificationButton(onTap: (notification) {
                    switch (notification.type) {
                      case 'order':
                        if (notification.orderId != null) {
                          _handleSearch(
                              context, appProvider, notification.orderId!);
                        }
                        break;
                      case "chat":
                        if (notification.orderId != null) {
                          _handleSearch(
                              context, appProvider, notification.orderId!);
                        }
                        break;
                    }
                  }),
                  const SizedBox(width: 16),
                  _buildProfileButton(context),
                  const SizedBox(width: 16),
                  _buildAddOrderButton(context),
                  const SizedBox(width: 12),
                  _buildBulkOrderButton(context),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSearch(
      BuildContext context, AppProvider appProvider, String value) async {
    if (value.isEmpty) {
      _showErrorSnackBar(context, 'الرجاء إدخال رقم الطرد');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final shipment = await appProvider.getOrder(value);
      Navigator.pop(context); // Remove loading

      if (shipment != null) {
        showSideDrawerDialog(
          context: context,
          side: DrawerSide.left,
          width: MediaQuery.of(context).size.width > 850
              ? 850
              : MediaQuery.of(context).size.width,
          child: ShipmentDetails(shipment: shipment),
        );
      } else {
        _showErrorSnackBar(context, 'لم يتم العثور على الطرد بذا الرقم');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar(context, 'حدث خطأ أثناء البحث');
    }
  }

  Widget _buildProfileButton(BuildContext context) {
    return InkWell(
      onTap: () => showDialog(
          context: context, builder: (context) => const SettingsScreen()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: primary.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: primary),
            ),
            const SizedBox(width: 8),
            Text(
              FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
                  'المسؤول',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOrderButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: AddOrderFormOne(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('إضافة طلب'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minimumSize: const Size(0, 44),
      ),
    );
  }

  Widget _buildBulkOrderButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Scaffold.of(context).openEndDrawer(),
      icon: const Icon(Icons.grid_view_rounded, size: 18),
      label: const Text('طلب بالجملة'),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
