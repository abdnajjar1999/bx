import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../main.dart';
import '../ManageShipments/widget/CustomButton.dart';
import 'AddDriverDialog.dart';
import 'DriverDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/appProvider.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "اداره السائقين",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CustomButton(
                  text: 'اضافه موظف',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddDriverDialog(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows),
                  onPressed: () => setState(() => _isTableView = !_isTableView),
                ),
              ],
            ),
            _isTableView
                ? _buildDataTable(appProvider)
                : _buildCardView(appProvider),
          ],
        ),
      );
    });
  }

  Widget _buildDataTable(AppProvider appProvider) {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text('اسم مستخدم')),
        DataColumn(label: Text('رقم الجوال')),
        DataColumn(label: Text('الايميل')),
        DataColumn(label: Text('عنوان')),
        DataColumn(label: Text('نسبة السائق (%)')),
        DataColumn(label: Text('المدن')),
        DataColumn(label: Text('الصلاحيات / الوظيفة')),
      ],
      rows: appProvider.drivers.map<DataRow>((driver) {
        return DataRow(
          cells: [
            DataCell(Text(driver.username ?? "")),
            DataCell(Text(driver.phone ?? "")),
            DataCell(Text(driver.email ?? "")),
            DataCell(Text(driver.address ?? "")),
            DataCell(Text(driver.driverShare?.toString() ?? "0.0")),
            DataCell(
              SizedBox(
                width: 150,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: driver.cities.map((city) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            DataCell(Text("سائق")),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCardView(AppProvider appProvider) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: appProvider.drivers
          .map((driver) => _buildUserCard(
                name: driver.username ?? "",
                phone: driver.phone ?? "",
                email: driver.email ?? "",
                address: driver.address ?? "",
                driverShare: driver.driverShare?.toString() ?? "0.0",
                role: "سائق",
                cities: driver.cities,
                profileImage: driver.profileImage,
                driverId: driver.driverId,
                onTapAccept: driver.status == "داخل الخدمة"
                    ? null
                    : () async{
                        final driversSnap = await FirebaseFirestore.instance
                            .collection("drivers")
                            .get();
                        int maxId = 0;
                        for (var doc in driversSnap.docs) {
                          var data = doc.data();
                          if (data.containsKey('driverId') && data['driverId'] != null) {
                            int? id = int.tryParse(data['driverId'].toString());
                            if (id != null && id > maxId) {
                              maxId = id;
                            }
                          }
                        }
                        String newDriverId = (maxId + 1).toString();

                        await FirebaseFirestore.instance
                            .collection("drivers")
                            .doc(driver.userid)
                            .update({
                              "status": "داخل الخدمة",
                              "driverId": newDriverId,
                            });
                        appProvider.getDrivers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('تم قبول السائق بنجاح')),
                        );
                      },
                onTapDetails: () {
                  showDialog(
                    context: context,
                    builder: (context) => DriverDetailsScreen(driver: driver),
                  );
                },
              ))
          .toList(),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String driverShare,
    required String role,
    required List<String> cities,
    required VoidCallback onTapDetails,
    VoidCallback? onTapAccept,
    String? profileImage,
    String? driverId,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (profileImage != null && profileImage.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(profileImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  image: (profileImage != null && profileImage.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(profileImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (profileImage != null && profileImage.isNotEmpty)
                    ? null
                    : Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: primary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFDC2626).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "نسبة: $driverShare%",
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (driverId != null && driverId.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ID: $driverId",
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        address,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (cities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_city, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: cities.map((city) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: onTapDetails,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: primary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline,
                                  size: 16, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                'تفاصيل السائق',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      if (onTapAccept != null)
                      InkWell(
                        onTap: onTapAccept,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'قبول',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
