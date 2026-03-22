import 'package:sadrad/models/customer.dart';
import 'package:sadrad/shared/PrintHelper.dart';

import '../ManageShipments/widget/CustomButton.dart';
import 'AddCustomerDialog.dart';
import 'CustomerDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

import 'package:sadrad/shared/appProvider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool _isTableView = false;
  String _selectedStatus = 'الكل'; // 'الكل', 'معلق', 'مقبول'

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      final filteredCustomers = appProvider.customers.where((c) {
        String status = c.status;
        bool matchStatus = _selectedStatus == 'الكل' ||
            (_selectedStatus == 'معلق' && status == 'معلق') ||
            (_selectedStatus == 'مقبول' && status == 'مقبول');
        return matchStatus;
      }).toList();
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "اداره الزبائن",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows),
                  onPressed: () => setState(() => _isTableView = !_isTableView),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        }
                      },
                      items: ['الكل', 'معلق', 'مقبول'].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CustomButton(
                  text: 'اضافه زبون',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddCustomerDialog(),
                    );
                  },
                ),

                // طباعه بوليصه
                CustomButton(
                  text: 'طباعه بوليصه',
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        Customer? selectedCustomer;
                        int? times;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'اختر الزبون',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Customer dropdown
                                    DropdownButtonFormField<Customer>(
                                      value: selectedCustomer,
                                      decoration: InputDecoration(
                                        labelText: 'الزبون',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                      ),
                                      items: appProvider.customers
                                          .map<DropdownMenuItem<Customer>>(
                                            (Customer customer) =>
                                                DropdownMenuItem<Customer>(
                                              value: customer,
                                              child: Text(customer.username),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (Customer? value) {
                                        setState(
                                            () => selectedCustomer = value);
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Times input
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          times = int.tryParse(value);
                                        });
                                      },
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'عدد المرات',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        prefixIcon: const Icon(Icons.repeat),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (selectedCustomer != null &&
                                        times != null &&
                                        times! > 0) {
                                      PrintHandler().printEmpty10x9Receipt(
                                        customer: selectedCustomer!,
                                        times: times!,
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'الرجاء اختيار الزبون وادخال عدد المرات'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('طباعة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            _isTableView
                ? _buildDataTable(appProvider, filteredCustomers)
                : _buildCardView(appProvider, filteredCustomers),
          ],
        ),
      );
    });
  }

  Widget _buildDataTable(AppProvider appProvider, List<Customer> customers) {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text('اسم مستخدم')),
        DataColumn(label: Text('رقم الجوال')),
        DataColumn(label: Text('الايميل')),
        DataColumn(label: Text('عنوان')),
        DataColumn(label: Text('الحالة')),
        DataColumn(label: Text('الإجراءات')),
      ],
      rows: customers.map<DataRow>((customer) {
        return DataRow(
          cells: [
            DataCell(Text(customer.username)),
            DataCell(Text(customer.phoneNumber)),
            DataCell(Text(customer.email)),
            DataCell(Text(customer.address)),
            DataCell(Text(customer.status)),
            DataCell(const SizedBox.shrink()),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCardView(AppProvider appProvider, List<Customer> customers) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: customers
          .map((customer) => _buildUserCard(
                name: customer.username,
                phone: customer.phoneNumber,
                email: customer.email,
                address: customer.address,
                role: "زبون",
                status: customer.status,
                onTapDetails: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        CustomerDetailsScreen(customer: customer),
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
    required String role,
    required String status,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              (status == 'معلق' ? Colors.orange : Colors.green)
                                  .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: (status == 'معلق'
                                ? Colors.orange
                                : Colors.green),
                            fontSize: 12,
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
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: onTapDetails,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                                'تفاصيل الزبون',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
