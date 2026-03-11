import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../ManageShipments/widget/CustomButton.dart';

import 'AddDriverDialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';
import 'AddCustomerDialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _limitIncrement = 20;
  int _limit = 20;

  List<DocumentSnapshot> users = [];

  bool _isTableView = false;
  
  // Selection state management
  Set<String> _selectedDrivers = {};
  Set<String> _selectedCustomers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    //_fetchUsers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchMoreUsers();
    }
  }

  Future<void> _fetchUsers() async {

    QuerySnapshot snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(_limit)
          .get();
    } catch (error) {
      print('Error fetching users: $error');
      return;
    }

    snapshot.docs.map((e) {}).toList();

    setState(() {
      users = snapshot.docs;
    });
  }


  Future<void> _fetchMoreUsers() async {
    setState(() {
      _limit += _limitIncrement;
    });
    await _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return SingleChildScrollView(
        //controller: _scrollController,
        //horizontalScrollController: _horizontalScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "اداره المستخدمين",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CustomButton(
                  text: 'اضافه زبون',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddCustomerDialog(),
                    );
                  },
                ),
                CustomButton(
                  text: 'اضافه موظف',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddDriverDialog(),
                    );
                  },
                ),
                if (_selectedDrivers.isNotEmpty || _selectedCustomers.isNotEmpty)
                  CustomButton(
                    text: 'حذف المحدد (${_selectedDrivers.length + _selectedCustomers.length})',
                    onPressed: _deleteSelectedUsers,
                    color: Colors.red,
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
        DataColumn(label: Text('تحديد')),
        DataColumn(label: Text('اسم مستخدم')),
        DataColumn(label: Text('رقم الجوال')),
        DataColumn(label: Text('الايميل')),
        DataColumn(label: Text('عنوان')),
        DataColumn(label: Text('الصلاحيات / الوظيفة')),
      ], 
      rows: [
        ...appProvider.drivers.map<DataRow>((driver) {
          bool isSelected = _selectedDrivers.contains(driver.userid);
          return DataRow(
            selected: isSelected,
            onSelectChanged: (selected) {
              setState(() {
                if (selected == true && driver.userid != null) {
                  _selectedDrivers.add(driver.userid!);
                } else if (driver.userid != null) {
                  _selectedDrivers.remove(driver.userid!);
                }
              });
            },
            cells: [
              DataCell(Checkbox(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true && driver.userid != null) {
                      _selectedDrivers.add(driver.userid!);
                    } else if (driver.userid != null) {
                      _selectedDrivers.remove(driver.userid!);
                    }
                  });
                },
                activeColor: primary,
              )),
              DataCell(Text(driver.username ?? "")),
              DataCell(Text(driver.phone ?? "")),
              DataCell(Text(driver.email ?? "")),
              DataCell(Text(driver.address ?? "")),
              DataCell(Text("سائق")),
            ],
          );
        }),
        ...appProvider.customers.map<DataRow>((customer) {
          bool isSelected = _selectedCustomers.contains(customer.userid);
          return DataRow(
            selected: isSelected,
            onSelectChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedCustomers.add(customer.userid);
                } else {
                  _selectedCustomers.remove(customer.userid);
                }
              });
            },
            cells: [
              DataCell(Checkbox(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedCustomers.add(customer.userid);
                    } else {
                      _selectedCustomers.remove(customer.userid);
                    }
                  });
                },
                activeColor: primary,
              )),
              DataCell(Text(customer.username)),
              DataCell(Text(customer.phoneNumber)),
              DataCell(Text(customer.email)),
              DataCell(Text(customer.address)),
              DataCell(Text("زبون")),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCardView(AppProvider appProvider) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ...appProvider.drivers.map((driver) => _buildUserCard(
              name: driver.username ?? "",
              phone: driver.phone ?? "",
              email: driver.email ?? "",
              address: driver.address ?? "",
              role: "سائق",
              isSelected: _selectedDrivers.contains(driver.userid),
              onSelectionChanged: (selected) {
                setState(() {
                  if (selected && driver.userid != null) {
                    _selectedDrivers.add(driver.userid!);
                  } else if (driver.userid != null) {
                    _selectedDrivers.remove(driver.userid!);
                  }
                });
              },
            )),
        ...appProvider.customers.map((customer) => _buildUserCard(
              name: customer.username,
              phone: customer.phoneNumber,
              email: customer.email,
              address: customer.address,
              role: "زبون",
              isSelected: _selectedCustomers.contains(customer.userid),
              onSelectionChanged: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCustomers.add(customer.userid);
                  } else {
                    _selectedCustomers.remove(customer.userid);
                  }
                });
              },
            )),
      ],
    );
  }

  Widget _buildUserCard({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String role,
    bool isSelected = false,
    Function(bool)? onSelectionChanged,
  }) {
    return Card(
      elevation: isSelected ? 4 : 2,
      color: isSelected ? primary.withOpacity(0.1) : null,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => onSelectionChanged?.call(value ?? false),
              activeColor: primary,
            ),
            // Profile Circle
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
            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Role Tags
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
                  // Tags Row
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
                      if (role == "مدير فرع")
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            KcompanyName,
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Contact Info
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
                  const SizedBox(height: 8),
                  // Employee Details Button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get_str(String value) {
    if (value != "") {
      return value;
    }
    return "null";
  }

  Future<void> _deleteSelectedUsers() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف ${_selectedDrivers.length + _selectedCustomers.length} مستخدم؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final firebaseHelper = FirebaseHelper();

        // Delete selected drivers by ID
        for (String driverId in _selectedDrivers) {
          if (driverId.isNotEmpty) {
            await firebaseHelper.deleteDriverById(driverId);
          }
        }

        // Delete selected customers by ID
        for (String customerId in _selectedCustomers) {
          if (customerId.isNotEmpty) {
            await firebaseHelper.deleteCustomerById(customerId);
          }
        }

        // Refresh the data
        appProvider.getDrivers();
        appProvider.getCustomers();

        // Clear selection
        setState(() {
          _selectedDrivers.clear();
          _selectedCustomers.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستخدمين بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف المستخدمين: $e')),
        );
      }
    }
  }
}
