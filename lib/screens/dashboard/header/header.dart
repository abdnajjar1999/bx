// import 'package:durub_ali/aiAgent/aiAgentSidePanal.dart';
// import 'package:durub_ali/aiAgent/tools.dart';

import 'showSideDrawerDialog.dart';

import '../../../main.dart';
import '../../ManageShipments/ShipmentDetails.dart';
import 'NotificationButton.dart';
import '../../../shared/appProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../AddOrder/AddOrderFormOne.dart';
import '../../settings/SettingsScreen.dart';

class header extends StatelessWidget {
  const header({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 70,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Material(
                    elevation: 0.5,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        SvgPicture.asset("assets/package-icon.svg"),
                        const SizedBox(width: 10),
                        Container(
                          color: secprimary,
                          child: const SizedBox(
                            height: 30.0,
                            width: 3.0,
                            child: Divider(
                              thickness: 10,
                              color: secprimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'أدخل رقم الطرد',
                              labelStyle: TextStyle(fontSize: 12),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) async {
                              if (value.isEmpty) {
                                _showErrorSnackBar(
                                    context, 'الرجاء إدخال رقم الطرد');
                                return;
                              }

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );

                              try {
                                final shipment =
                                    await appProvider.getOrder(value);

                                // Remove loading indicator
                                Navigator.pop(context);

                                if (shipment != null) {
                                  showSideDrawerDialog(
                                    context: context,
                                    side: DrawerSide.left,
                                    width:
                                        MediaQuery.of(context).size.width > 850
                                            ? 850
                                            : MediaQuery.of(context).size.width,
                                    child: ShipmentDetails(shipment: shipment),
                                  );
                                } else {
                                  _showErrorSnackBar(
                                    context,
                                    'لم يتم العثور على الطرد برقم: $value',
                                  );
                                }
                              } catch (e) {
                                // Remove loading indicator
                                Navigator.pop(context);

                                _showErrorSnackBar(
                                  context,
                                  'حدث خطأ أثناء البحث عن الطرد',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const NotificationButton(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const SettingsScreen();
                    },
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      FirebaseAuth.instance.currentUser?.photoURL ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: AddOrderFormOne(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'إضافة طلب',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open the same drawer as the regular add order button
                      Scaffold.of(context).openEndDrawer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.orange, // Different color to distinguish
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text(
                      'إضافة طلبات بالجملة',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
