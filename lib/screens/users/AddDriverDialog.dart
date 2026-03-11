import '../../shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import '../../shared/firebaseHelper.dart';
import '../ManageShipments/widget/CustomTextField.dart';
import '../ManageShipments/widget/CustomDropdown.dart';

class AddDriverDialog extends StatefulWidget {
  const AddDriverDialog({Key? key}) : super(key: key);

  @override
  _AddDriverDialogState createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  List<Driver> selectedDrivers = [];
  Driver? selectedDriver;
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
    final drivers = appProvider.drivers;
    final cities = appProvider.cities;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة السائقين'),
          actions: [
            if (selectedDrivers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedDrivers,
                tooltip: 'حذف السائقين المحددين',
              ),
          ],
        ),
        body: Row(
          children: [
            // Left side - Driver List
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = selectedDrivers.contains(driver);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedDrivers.add(driver);
                            } else {
                              selectedDrivers.remove(driver);
                            }
                          });
                        },
                      ),
                      title: Text(driver.username ?? ''),
                      subtitle: Text(driver.email ?? ''),
                      onTap: () => _selectDriver(driver),
                      selected: selectedDriver?.userid == driver.userid,
                    );
                  },
                ),
              ),
            ),
            // Right side - Driver Form
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
                              selectedDriver != null
                                  ? 'تعديل سائق'
                                  : 'إضافة سائق جديد',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (selectedDriver != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDriver(selectedDriver!),
                                tooltip: 'حذف السائق',
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
                       if(_categoryController.text == "سائق") 
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
                        if(_categoryController.text == "سائق")
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
                                final isSelected = selectedCities.contains(city);
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
                        if(_categoryController.text != "سائق") 
                        for (var permission in permissions)
                        SwitchListTile(
                          title: Text(permission),
                          value: selectedPermissions.contains(permission),
                          onChanged: (value) =>
                              setState(() => selectedPermissions.contains(permission) ? selectedPermissions.remove(permission) : selectedPermissions.add(permission)),
                        ),
                        const Text(
                          "الصفحات المحجوبه",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if(_categoryController.text != "سائق") 
                        for (var page in drawerTitles)
                        SwitchListTile(
                          title: Text(page),
                          value: selectedPermissions.contains(page),
                          onChanged: (value) =>
                              setState(() => selectedPermissions.contains(page) ? selectedPermissions.remove(page) : selectedPermissions.add(page)),
                        ),
                        // SwitchListTile(
                        //   title: const Text('السماح بتأجيل طرود'),
                        //   value: _allowDelayedDelivery,
                        //   onChanged: (value) =>
                        //       setState(() => _allowDelayedDelivery = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('السماح بتسليم الرجيع للمرسل'),
                        //   value: _allowReturns,
                        //   onChanged: (value) =>
                        //       setState(() => _allowReturns = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('السماح بتسليم كشوفات التحصيل'),
                        //   value: _deliverToWarehouse,
                        //   onChanged: (value) =>
                        //       setState(() => _deliverToWarehouse = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('إخفاء معلومات مرسلي الطرود'),
                        //   value: _hideDriverInfo,
                        //   onChanged: (value) =>
                        //       setState(() => _hideDriverInfo = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('إخفاء معلومات مستلمي الطرود'),
                        //   value: _hideRecipientInfo,
                        //   onChanged: (value) =>
                        //       setState(() => _hideRecipientInfo = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('إخفاء التوقيع عند تسليم الطرود'),
                        //   value: _requireSignature,
                        //   onChanged: (value) =>
                        //       setState(() => _requireSignature = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text('السماح للسائق برفض الطلبات'),
                        //   value: _allowDriverRefuse,
                        //   onChanged: (value) =>
                        //       setState(() => _allowDriverRefuse = value),
                        // ),
                        // SwitchListTile(
                        //   title: const Text(
                        //       'إخفاء خيار مسح الباركود لتحصيل الطرود'),
                        //   value: _hideBarcode,
                        //   onChanged: (value) =>
                        //       setState(() => _hideBarcode = value),
                        // ),
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
                              onPressed: _saveDriver,
                              child: Text(
                                  selectedDriver != null ? 'تحديث' : 'إضافة'),
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

  void _selectDriver(Driver driver) {
    setState(() {
      selectedDriver = driver;
      _firstNameController.text = driver.username?.split(' ')[0] ?? '';
      _lastNameController.text =
          driver.username?.split(' ').skip(1).join(' ') ?? '';
      _emailController.text = driver.email?.replaceAll('.com', '') ?? '';
      _phoneController.text = driver.phone ?? '';
      _addressController.text = driver.address ?? '';
      _locationController.text = driver.location ?? '';
      _branchController.text = driver.branch ?? '';
      _categoryController.text = driver.category ?? '';
      _companyController.text = driver.company ?? '';
      _driverIdController.text = driver.driverId ?? '';
      _driverShareController.text = driver.driverShare?.toString() ?? '0.0';
      _allowDeliveryParcel = driver.allowDeliveryParcel;
      _allowDelayedDelivery = driver.allowDelayedDelivery;
      _allowReturns = driver.allowReturns;
      _deliverToWarehouse = driver.deliverToWarehouse;
      _hideDriverInfo = driver.hideDriverInfo;
      _hideRecipientInfo = driver.hideRecipientInfo;
      _requireSignature = driver.requireSignature;
      _allowDriverRefuse = driver.allowDriverRefuse;
      _hideBarcode = driver.hideBarcode;
      _driverShareController.text = driver.driverShare?.toString() ?? '0.0';
      _passwordController.text = driver.password ?? '';
      selectedPermissions = driver.permissions;
      selectedCities = driver.cities;
    });
  }

  void _clearForm() {
    setState(() {
      selectedDriver = null;
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

  void _deleteDriver(Driver driver) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف هذا السائق؟'),
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
        await FirebaseHelper()
            .deleteDriver(driver.email!); // Added null check operator

        // Refresh the drivers list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getDrivers();

        // Clear form
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السائق بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف السائق: $e')),
        );
      }
    }
  }

  void _deleteSelectedDrivers() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content:
                Text('هل أنت متأكد من حذف ${selectedDrivers.length} سائقين؟'),
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
        for (var driver in selectedDrivers) {
          await FirebaseHelper()
              .deleteDriver(driver.email!); // Add null check operator
        }

        // Refresh the drivers list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getDrivers();

        // Clear selection and form if selected driver was deleted
        setState(() {
          if (selectedDrivers.contains(selectedDriver)) {
            _clearForm();
          }
          selectedDrivers.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السائقين بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف السائقين: $e')),
        );
      }
    }
  }

  Future<void> _saveDriver() async {
    if (_formKey.currentState!.validate()) {
      try {
        String email = _emailController.text.trim() + ".com";
        double driverShare = _driverShareController.text.isEmpty
            ? 0.0
            : double.parse(_driverShareController.text);

        if (selectedDriver == null) {
          // Create new driver
          final userCredential = await FirebaseHelper.registerUserAsAdmin(
              email, _passwordController.text.trim());

          if (userCredential == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('هناك خطأ ما في إنشاء المستخدم')),
            );
            return;
          }

          final driver = Driver(
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
              .doc(driver.userid)
              .set(driver.toMap());
        } else {
          // Update existing driver
          final driver = Driver(
            userid: selectedDriver!.userid,
            username:
                '${_firstNameController.text} ${_lastNameController.text}',
            email: selectedDriver!.email,
            password: selectedDriver!.password,
            phone: _phoneController.text,
            address: _addressController.text,
            detailedAddress: _addressController.text,
            location: _locationController.text,
            branch: _branchController.text,
            category: _categoryController.text,
            company: _companyController.text,
            driverId: _driverIdController.text,
            jobRole: _categoryController.text,
            profileImage: selectedDriver!.profileImage,
            cashBalance: selectedDriver!.cashBalance,
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
              .doc(driver.userid)
              .update(driver.toMap());
        }

        // Refresh the drivers list
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.getDrivers();

        // Clear form after successful save
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(selectedDriver == null
                  ? 'تم إضافة السائق بنجاح'
                  : 'تم تحديث السائق بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
