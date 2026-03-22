import '../../shared/firebaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../shared/appProvider.dart';
import '../../main.dart';
import '../ManageShipments/widget/CustomTextField.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({Key? key}) : super(key: key);

  @override
  _ManageCustomersScreenState createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<AddCustomerDialog> {
  List<Customer> selectedCustomers = [];
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? selectedCity;
  bool _allowAdminModification = false;
  bool _allowOtherAdminsModification = false;
  bool _showPriceInApp = false;
  bool _showDriverInApp = false;
  bool _showAddressInApp = false;
  bool _showPhoneInApp = false;
  bool _obscurePassword = true;
  CustomerType _customerType = CustomerType.shop;
  Customer? selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final customers = appProvider.customers;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة العملاء'),
          actions: [
            if (selectedCustomers.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedCustomers,
                tooltip: 'حذف العملاء المحددين',
              ),
          ],
        ),
        body: Row(
          children: [
            // Left side - Customer List
            Expanded(
              flex: 2,
              child: Card(
                margin: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final isSelected = selectedCustomers.contains(customer);

                    return ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedCustomers.add(customer);
                            } else {
                              selectedCustomers.remove(customer);
                            }
                          });
                        },
                      ),
                      title: Text(customer.username),
                      subtitle: Text(customer.email),
                      onTap: () => _selectCustomer(customer),
                      selected: selectedCustomer?.userid == customer.userid,
                    );
                  },
                ),
              ),
            ),
            // Right side - Customer Form
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
                              selectedCustomer != null
                                  ? 'تعديل عميل'
                                  : 'إضافة عميل جديد',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (selectedCustomer != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCustomer(selectedCustomer!),
                                tooltip: 'حذف العميل',
                              ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearForm,
                              tooltip: 'مسح النموذج',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _firstNameController,
                          labelText: 'الاسم الترويجي',
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'الرجاء إدخال الاسم الترويجي';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _emailController,
                                labelText: 'البريد الإلكتروني',
                                readOnly: selectedCustomer !=
                                    null, // Only enable for new customers
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                controller: _passwordController,
                                labelText: 'كلمة المرور',
                                obscureText: _obscurePassword,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                validator: selectedCustomer == null
                                    ? (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'الرجاء إدخال كلمة المرور';
                                        }
                                        if (value!.length < 6) {
                                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneController,
                          labelText: 'رقم الهاتف',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'الرجاء إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'المدينة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: primary),
                            ),
                          ),
                          value: selectedCity != null &&
                                  appProvider.cities.contains(selectedCity)
                              ? selectedCity
                              : null,
                          items: appProvider.cities.isEmpty
                              ? [
                                  DropdownMenuItem<String>(
                                    value: 'لا توجد مدن متاحة',
                                    child: Text('لا توجد مدن متاحة'),
                                  )
                                ]
                              : appProvider.cities.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          onChanged: appProvider.cities.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedCity = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _addressController,
                          labelText: 'العنوان التفصيلي',
                        ),
                        const SizedBox(height: 16),
                        // Switches section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الصلاحيات:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SwitchListTile(
                                  title:
                                      const Text('السماح للمستخدمين الفرعيين'),
                                  value: _allowAdminModification,
                                  onChanged: (value) => setState(
                                      () => _allowAdminModification = value),
                                ),
                                SwitchListTile(
                                  title: const Text(
                                      'السماح للمستخدمين الفرعيين بإضافة أو تعديل الطرود'),
                                  value: _allowOtherAdminsModification,
                                  onChanged: (value) => setState(() =>
                                      _allowOtherAdminsModification = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('إظهار معلومات في التطبيق:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SwitchListTile(
                                  title: const Text('إظهار السعر'),
                                  value: _showPriceInApp,
                                  onChanged: (value) =>
                                      setState(() => _showPriceInApp = value),
                                ),
                                SwitchListTile(
                                  title: const Text('إظهار السائق'),
                                  value: _showDriverInApp,
                                  onChanged: (value) =>
                                      setState(() => _showDriverInApp = value),
                                ),
                                SwitchListTile(
                                  title: const Text('إظهار العنوان'),
                                  value: _showAddressInApp,
                                  onChanged: (value) =>
                                      setState(() => _showAddressInApp = value),
                                ),
                                SwitchListTile(
                                  title: const Text('إظهار رقم الهاتف'),
                                  value: _showPhoneInApp,
                                  onChanged: (value) =>
                                      setState(() => _showPhoneInApp = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveCustomer,
                          child: Text(
                              selectedCustomer != null ? 'تحديث' : 'إضافة'),
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

  void _selectCustomer(Customer customer) {
    setState(() {
      selectedCustomer = customer;
      _firstNameController.text = customer.username;
      _emailController.text = customer.email.replaceAll('.com', '');
      _phoneController.text = customer.phoneNumber;
      _addressController.text = customer.address;
      // Only set selectedCity if it exists in the cities list
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      selectedCity =
          (customer.city != null && appProvider.cities.contains(customer.city))
              ? customer.city
              : null;
      _allowAdminModification = customer.allowAdminModification!;
      _allowOtherAdminsModification = customer.allowOtherAdminsModification!;
      _showPriceInApp = customer.showPriceInApp!;
      _showDriverInApp = customer.showDriverInApp!;
      _showAddressInApp = customer.showAddressInApp!;
      _showPhoneInApp = customer.showPhoneInApp!;
      _customerType = customer.customerType;
    });
  }

  void _clearForm() {
    setState(() {
      selectedCustomer = null;
      _formKey.currentState?.reset();
      _firstNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _addressController.clear();
      selectedCity = null;
      _allowAdminModification = false;
      _allowOtherAdminsModification = false;
      _showPriceInApp = false;
      _showDriverInApp = false;
      _showAddressInApp = false;
      _showPhoneInApp = false;
      _customerType = CustomerType.shop; // Default value
    });
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        String email = _emailController.text.trim() + ".com";

        if (selectedCustomer == null) {
          // Create new customer
          final userCredential = await FirebaseHelper.registerUserAsAdmin(
              email, _passwordController.text.trim());

          if (userCredential == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('هناك خطأ ما في إنشاء المستخدم')),
            );
            return;
          }

          final customer = Customer(
            userid: userCredential.user!.uid,
            username: _firstNameController.text,
            email: email,
            password: _passwordController.text,
            phoneNumber: _phoneController.text,
            city: selectedCity,
            address: _addressController.text,
            profileImage: '',
            cashBalance: 0.0,
            allowAdminModification: _allowAdminModification,
            allowOtherAdminsModification: _allowOtherAdminsModification,
            showPriceInApp: _showPriceInApp,
            showDriverInApp: _showDriverInApp,
            showAddressInApp: _showAddressInApp,
            showPhoneInApp: _showPhoneInApp,
            customerType: _customerType,
            status: 'مقبول',
          );

          await FirebaseHelper().addCustomer(customer);
        } else {
          // Update existing customer
          final customer = Customer(
            userid: selectedCustomer!.userid,
            username: _firstNameController.text,
            email: selectedCustomer!.email,
            password: selectedCustomer!.password,
            phoneNumber: _phoneController.text,
            city: selectedCity,
            address: _addressController.text,
            profileImage: selectedCustomer!.profileImage,
            cashBalance: selectedCustomer!.cashBalance,
            allowAdminModification: _allowAdminModification,
            allowOtherAdminsModification: _allowOtherAdminsModification,
            showPriceInApp: _showPriceInApp,
            showDriverInApp: _showDriverInApp,
            showAddressInApp: _showAddressInApp,
            showPhoneInApp: _showPhoneInApp,
            customerType: _customerType,
          );

          await FirebaseHelper().updateCustomer(customer);
        }

        // Clear form after successful save
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selectedCustomer == null
                ? 'تم إضافة العميل بنجاح'
                : 'تم تحديث العميل بنجاح'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _deleteCustomer(Customer customer) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل أنت متأكد من حذف هذا العميل؟'),
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
        // Use customer ID for deletion instead of email
        await FirebaseHelper().deleteCustomerById(customer.userid);

        // Clear form
        _clearForm();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف العميل بنجاح'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف العميل: $e')),
        );
      }
    }
  }

  void _deleteSelectedCustomers() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content:
                Text('هل أنت متأكد من حذف ${selectedCustomers.length} عملاء؟'),
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
        for (var customer in selectedCustomers) {
          // Use customer ID for deletion instead of email
          await FirebaseHelper().deleteCustomerById(customer.userid);
        }

        // Clear selection and form if selected customer was deleted
        setState(() {
          if (selectedCustomers.contains(selectedCustomer)) {
            _clearForm();
          }
          selectedCustomers.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف ${selectedCustomers.length} عميل بنجاح'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حذف العملاء: $e')),
        );
      }
    }
  }
}
