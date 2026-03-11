import '../../shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';
import '../ManageShipments/widget/CustomTextField.dart';
import '../ManageShipments/widget/CustomDropdown.dart';

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({Key? key}) : super(key: key);

  @override
  _AddEmployeeDialogState createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  List<Driver> selectedEmployees = [];
  Driver? selectedEmployee;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _driverIdController = TextEditingController();
  final _branchController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _companyController = TextEditingController();
  final _driverShareController = TextEditingController();

  bool _allowDeliveryParcel = false;
  bool _hideDriverInfo = false;
  bool _hideRecipientInfo = false;
  bool _requireSignature = false;
  bool _allowDriverRefuse = false;
  bool _hideBarcode = false;
  bool _allowReturns = false;
  bool _allowDelayedDelivery = false;
  bool _deliverToWarehouse = false;
  List<String> selectedPermissions = [];
  List<String> selectedCities = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _driverIdController.dispose();
    _branchController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _companyController.dispose();
    _driverShareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final employees = appProvider.employees;
    final cities = appProvider.cities;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الموظفين'),
          actions: [
            if (selectedEmployees.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedEmployees,
                tooltip: 'حذف الموظفين المحددين',
              ),
          ],
        ),
        body: Row(
          children: [
            // Left side - Employee List
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    final isSelected = selectedEmployees.contains(employee);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedEmployees.add(employee);
                            } else {
                              selectedEmployees.remove(employee);
                            }
                          });
                        },
                      ),
                      title: Text(employee.username ?? ''),
                      subtitle: Text(employee.email ?? ''),
                      onTap: () => _selectEmployee(employee),
                      selected: selectedEmployee?.userid == employee.userid,
                    );
                  },
                ),
              ),
            ),
            // Right side - Employee Form
            Expanded(
              flex: 3,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              selectedEmployee != null
                                  ? 'تعديل موظف'
                                  : 'إضافة موظف جديد',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (selectedEmployee != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteEmployee(selectedEmployee!),
                                tooltip: 'حذف الموظف',
                              ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearForm,
                              tooltip: 'مسح النموذج',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                labelText: 'الاسم الأول',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'الرجاء إدخال الاسم الأول';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                labelText: 'اسم العائلة',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'الرجاء إدخال اسم العائلة';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _emailController,
                                labelText: 'اسم المستخدم او الايميل',
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'الرجاء إدخال البريد الإلكتروني';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _passwordController,
                                labelText: 'كلمة المرور',
                                // obscureText: true,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'الرجاء إدخال كلمة المرور';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _phoneController,
                                labelText: 'الهاتف',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'الرجاء إدخال رقم الهاتف';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _locationController,
                                labelText: 'العنوان',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown(
                                items: roles,
                                value: _categoryController.text.isEmpty
                                    ? null
                                    : _categoryController.text,
                                labelText: 'الوظيفة والصلاحيات',
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _categoryController.text = value;
                                    });
                                  }
                                },
                                onClearPressed: () {
                                  setState(() {
                                    _categoryController.text = '';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _addressController,
                                labelText: 'العنوان بالتفصيل',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _branchController,
                                labelText: 'الفرع',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _categoryController,
                                labelText: 'الفئة',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _companyController,
                                labelText: 'الشركة',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _driverIdController,
                                labelText: 'رقم تعريف الموظف',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_categoryController.text == "سائق")
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _driverShareController,
                                  labelText: 'نسبة السائق (%)',
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      try {
                                        double share = double.parse(value);
                                        if (share < 0 || share > 100) {
                                          return 'يجب أن تكون النسبة بين 0 و 100';
                                        }
                                      } catch (e) {
                                        return 'الرجاء إدخال رقم صحيح';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        if (_categoryController.text == "سائق")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'المدن التي يتم التوصيل إليها',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: cities.map((city) {
                                  final isSelected =
                                      selectedCities.contains(city);
                                  return FilterChip(
                                    label: Text(city),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedCities.add(city);
                                        } else {
                                          selectedCities.remove(city);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          "الصلاحيات",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_categoryController.text != "سائق")
                          for (var permission in permissions)
                            SwitchListTile(
                              title: Text(permission),
                              value: selectedPermissions.contains(permission),
                              onChanged: (value) => setState(() =>
                                  selectedPermissions.contains(permission)
                                      ? selectedPermissions.remove(permission)
                                      : selectedPermissions.add(permission)),
                            ),
                        const Text(
                          "الصفحات المحجوبه",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_categoryController.text != "سائق")
                          for (var page in drawerTitles)
                            SwitchListTile(
                              title: Text(page),
                              value: selectedPermissions.contains(page),
                              onChanged: (value) => setState(() =>
                                  selectedPermissions.contains(page)
                                      ? selectedPermissions.remove(page)
                                      : selectedPermissions.add(page)),
                            ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveEmployee,
                              child: Text(
                                  selectedEmployee != null ? 'تحديث' : 'إضافة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectEmployee(Driver employee) {
    setState(() {
      selectedEmployee = employee;
      _firstNameController.text = employee.username?.split(' ')[0] ?? '';
      _lastNameController.text =
          employee.username?.split(' ').skip(1).join(' ') ?? '';
      _emailController.text = employee.email?.replaceAll('.com', '') ?? '';
      _phoneController.text = employee.phone ?? '';
      _addressController.text = employee.address ?? '';
      _locationController.text = employee.location ?? '';
      _branchController.text = employee.branch ?? '';
      _categoryController.text = employee.category ?? '';
      _companyController.text = employee.company ?? '';
      _driverIdController.text = employee.driverId ?? '';
      _driverShareController.text = employee.driverShare?.toString() ?? '0.0';
      _allowDeliveryParcel = employee.allowDeliveryParcel;
      _allowDelayedDelivery = employee.allowDelayedDelivery;
      _allowReturns = employee.allowReturns;
      _deliverToWarehouse = employee.deliverToWarehouse;
      _hideDriverInfo = employee.hideDriverInfo;
      _hideRecipientInfo = employee.hideRecipientInfo;
      _requireSignature = employee.requireSignature;
      _allowDriverRefuse = employee.allowDriverRefuse;
      _hideBarcode = employee.hideBarcode;
      _driverShareController.text = employee.driverShare?.toString() ?? '0.0';
      _passwordController.text = employee.password ?? '';
      selectedPermissions = employee.permissions;
      selectedCities = employee.cities;
    });
  }

  void _clearForm() {
    setState(() {
      selectedEmployee = null;
      _formKey.currentState?.reset();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _addressController.clear();
      _locationController.clear();
      _branchController.clear();
      _categoryController.clear();
      _companyController.clear();
      _driverIdController.clear();
      _driverShareController.clear();
      _allowDeliveryParcel = false;
      _allowDelayedDelivery = false;
      _allowReturns = false;
      _deliverToWarehouse = false;
      _hideDriverInfo = false;
      _hideRecipientInfo = false;
      _requireSignature = false;
      _allowDriverRefuse = false;
      _hideBarcode = false;
      selectedPermissions = [];
      selectedCities = [];
    });
  }

  void _deleteEmployee(Driver employee) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف هذا الموظف؟'),
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
        await FirebaseHelper().deleteDriver(employee.email!);

        // Refresh the employees list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getEmployees();

        // Clear form
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الموظف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف الموظف: $e')),
        );
      }
    }
  }

  void _deleteSelectedEmployees() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content:
                Text('هل أنت متأكد من حذف ${selectedEmployees.length} موظفين؟'),
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
        for (var employee in selectedEmployees) {
          await FirebaseHelper().deleteDriver(employee.email!);
        }

        // Refresh the employees list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getEmployees();

        // Clear selection and form if selected employee was deleted
        setState(() {
          if (selectedEmployees.contains(selectedEmployee)) {
            _clearForm();
          }
          selectedEmployees.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الموظفين بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف الموظفين: $e')),
        );
      }
    }
  }

  Future<void> _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      try {
        String email = _emailController.text.trim() + ".com";
        double driverShare = _driverShareController.text.isEmpty
            ? 0.0
            : double.parse(_driverShareController.text);

        if (selectedEmployee == null) {
          // Create new employee
          final userCredential = await FirebaseHelper.registerUserAsAdmin(
              email, _passwordController.text.trim());

          if (userCredential == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('هناك خطأ ما في إنشاء المستخدم')),
            );
            return;
          }

          final employee = Driver(
            userid: userCredential.user!.uid,
            username:
                '${_firstNameController.text} ${_lastNameController.text}',
            email: email,
            password: _passwordController.text,
            phone: _phoneController.text,
            address: _addressController.text,
            detailedAddress: _addressController.text,
            location: _locationController.text,
            branch: _branchController.text,
            category: _categoryController.text,
            company: _companyController.text,
            driverId: _driverIdController.text,
            jobRole: _categoryController.text,
            profileImage: '',
            cashBalance: 0.0,
            driverShare: driverShare,
            allowDeliveryParcel: _allowDeliveryParcel,
            allowDelayedDelivery: _allowDelayedDelivery,
            allowReturns: _allowReturns,
            deliverToWarehouse: _deliverToWarehouse,
            hideDriverInfo: _hideDriverInfo,
            hideRecipientInfo: _hideRecipientInfo,
            requireSignature: _requireSignature,
            allowDriverRefuse: _allowDriverRefuse,
            hideBarcode: _hideBarcode,
            permissions: selectedPermissions,
            cities: selectedCities,
          );

          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(employee.userid)
              .set(employee.toMap());
        } else {
          // Update existing employee
          final employee = Driver(
            userid: selectedEmployee!.userid,
            username:
                '${_firstNameController.text} ${_lastNameController.text}',
            email: selectedEmployee!.email,
            password: selectedEmployee!.password,
            phone: _phoneController.text,
            address: _addressController.text,
            detailedAddress: _addressController.text,
            location: _locationController.text,
            branch: _branchController.text,
            category: _categoryController.text,
            company: _companyController.text,
            driverId: _driverIdController.text,
            jobRole: _categoryController.text,
            profileImage: selectedEmployee!.profileImage,
            cashBalance: selectedEmployee!.cashBalance,
            driverShare: driverShare,
            allowDeliveryParcel: _allowDeliveryParcel,
            allowDelayedDelivery: _allowDelayedDelivery,
            allowReturns: _allowReturns,
            deliverToWarehouse: _deliverToWarehouse,
            hideDriverInfo: _hideDriverInfo,
            hideRecipientInfo: _hideRecipientInfo,
            requireSignature: _requireSignature,
            allowDriverRefuse: _allowDriverRefuse,
            hideBarcode: _hideBarcode,
            permissions: selectedPermissions,
            cities: selectedCities,
          );

          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(employee.userid)
              .update(employee.toMap());
        }

        // Refresh the employees list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getEmployees();

        // Clear form after successful save
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(selectedEmployee == null
                  ? 'تم إضافة الموظف بنجاح'
                  : 'تم تحديث الموظف بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
