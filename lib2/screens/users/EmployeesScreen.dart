import '../../main.dart';
import '../ManageShipments/widget/CustomButton.dart';
import 'AddEmployeeDialog.dart';
import 'DriverDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/appProvider.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _isTableView = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "اداره الموظفين",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CustomButton(
                  text: 'اضافه موظف',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddEmployeeDialog(),
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
        // DataColumn(label: Text('نسبة السائق (%)')), // Removed as it might not be relevant for all employees
        // DataColumn(label: Text('المدن')), // Removed
        DataColumn(label: Text('الصلاحيات / الوظيفة')),
      ],
      rows: appProvider.employees.map<DataRow>((employee) {
        return DataRow(
          cells: [
            DataCell(Text(employee.username ?? "")),
            DataCell(Text(employee.phone ?? "")),
            DataCell(Text(employee.email ?? "")),
            DataCell(Text(employee.address ?? "")),
            // DataCell(Text(employee.driverShare?.toString() ?? "0.0")),
            // DataCell(
            //   SizedBox(
            //     width: 150,
            //     child: Wrap(
            //       spacing: 4,
            //       runSpacing: 4,
            //       children: employee.cities.map((city) {
            //         return Container(
            //           padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //           decoration: BoxDecoration(
            //             color: primary.withOpacity(0.1),
            //             borderRadius: BorderRadius.circular(8),
            //             border: Border.all(
            //               color: primary.withOpacity(0.3),
            //             ),
            //           ),
            //           child: Text(
            //             city,
            //             style: TextStyle(
            //               color: primary,
            //               fontSize: 11,
            //             ),
            //           ),
            //         );
            //       }).toList(),
            //     ),
            //   ),
            // ),
            DataCell(Text(employee.jobRole ?? "موظف")),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCardView(AppProvider appProvider) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: appProvider.employees
          .map((employee) => _buildUserCard(
                name: employee.username ?? "",
                phone: employee.phone ?? "",
                email: employee.email ?? "",
                address: employee.address ?? "",
                driverShare: employee.driverShare?.toString() ?? "0.0",
                role: employee.jobRole ?? "موظف",
                cities: employee.cities,
                onTapDetails: () {
                  showDialog(
                    context: context,
                    builder: (context) => DriverDetailsScreen(
                        driver: employee), // Reuse details screen
                  );
                },
              ))
          .toList()
          .cast<Widget>(),
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
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
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
                      // Container(
                      //   padding:
                      //       EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: Color(0xFF4F46E5).withOpacity(0.2),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Text(
                      //     "نسبة: $driverShare%",
                      //     style: TextStyle(
                      //       color: Color(0xFF4F46E5),
                      //       fontSize: 12,
                      //     ),
                      //   ),
                      // ),
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
                  // if (cities.isNotEmpty) ...[
                  //   const SizedBox(height: 8),
                  //   Row(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Icon(Icons.location_city, size: 16, color: Colors.grey),
                  //       const SizedBox(width: 8),
                  //       Expanded(
                  //         child: Wrap(
                  //           spacing: 4,
                  //           runSpacing: 4,
                  //           children: cities.map((city) {
                  //             return Container(
                  //               padding: EdgeInsets.symmetric(
                  //                   horizontal: 6, vertical: 2),
                  //               decoration: BoxDecoration(
                  //                 color: primary.withOpacity(0.1),
                  //                 borderRadius: BorderRadius.circular(8),
                  //                 border: Border.all(
                  //                   color: primary.withOpacity(0.3),
                  //                 ),
                  //               ),
                  //               child: Text(
                  //                 city,
                  //                 style: TextStyle(
                  //                   color: primary,
                  //                   fontSize: 11,
                  //                 ),
                  //               ),
                  //             );
                  //           }).toList(),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  const SizedBox(height: 8),
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
                          Icon(Icons.person_outline, size: 16, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'تفاصيل الموظف',
                            style: TextStyle(
                              color: primary,
                              fontSize: 12,
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
}
