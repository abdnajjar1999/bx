import '../../main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Driver.dart';
import '../../shared/appProvider.dart';
import '../ManageShipments/widget/CustomDropdown.dart';

class AddVehicleDialog extends StatefulWidget {
  const AddVehicleDialog({Key? key}) : super(key: key);

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? insuranceEndDate;
  DateTime? licenseEndDate;
  bool _isLoading = false;
  String? selectedBrand;
  String? selectedFuelType;
  Driver? selectedDriver;
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _sizeController =
      TextEditingController(text: '1');
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();

  Future<void> _addVehicle(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      var ref = FirebaseFirestore.instance.collection('vehicles').doc();
      final vehicleData = {
        'id': ref.id,
        'brand': selectedBrand,
        'model': _modelController.text,
        'size': _sizeController.text,
        'plateNumber': _plateNumberController.text,
        'driverId': selectedDriver?.userid,
        'driverName': selectedDriver?.username,
        'vehicleType': _vehicleTypeController.text,
        'fuelType': selectedFuelType,
        'insuranceEndDate': insuranceEndDate?.toIso8601String(),
        'licenseEndDate': licenseEndDate?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active'
      };

      await ref.set(vehicleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة المركبة بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, appProvider, child) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                  const Text(
                    'إضافة مركبة جديدة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    buildDropdownField(
                      items: carBrands
                          .map((brand) => DropdownMenuItem<String>(
                                value: brand,
                                child: Text(brand),
                              ))
                          .toList(),
                      label: 'الماركه',
                      hint: 'الماركه',
                      value: selectedBrand,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() => selectedBrand = value as String?);
                            },
                    ),
                    _buildTextField(
                      label: 'الموديل',
                      controller: _modelController,
                    ),
                    _buildTextField(
                      label: 'الحجم',
                      controller: _sizeController,
                    ),
                    _buildTextField(
                      label: 'رقم اللوحة',
                      controller: _plateNumberController,
                      isRequired: true,
                    ),
                    buildDropdownField(
                      items: appProvider.drivers
                          .map((driver) => DropdownMenuItem<Driver>(
                                value: driver,
                                child: Text(driver.username ?? ""),
                              ))
                          .toList(),
                      label: 'السائق',
                      hint: 'اختر سائق',
                      value: appProvider.selectedDriver,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                appProvider.selectedDriver = value as Driver?;
                                selectedDriver = value;
                              });
                            },
                    ),
                    _buildTextField(
                      label: 'نوع المركبة',
                      controller: _vehicleTypeController,
                    ),
                    buildDropdownField(
                      label: 'نوع الوقود',
                      hint: 'اختر نوع الوقود',
                      value: selectedFuelType,
                      items: fuelTypes
                          .map((fuelType) => DropdownMenuItem<String>(
                                value: fuelType,
                                child: Text(fuelType),
                              ))
                          .toList(),
                      isRequired: true,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(
                                  () => selectedFuelType = value as String?);
                            },
                    ),
                    _buildDateField(
                      label: 'تاريخ انتهاء التأمين',
                      isRequired: true,
                      selectedDate: insuranceEndDate,
                      onTap: _isLoading
                          ? null
                          : () => _selectDate(context, (date) {
                                setState(() => insuranceEndDate = date);
                              }),
                    ),
                    _buildDateField(
                      label: 'تاريخ انتهاء الرخصة',
                      isRequired: true,
                      selectedDate: licenseEndDate,
                      onTap: _isLoading
                          ? null
                          : () => _selectDate(context, (date) {
                                setState(() => licenseEndDate = date);
                              }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _addVehicle(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('تم'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // Rest of your widget building methods (_buildTextField, _buildDropdownField, _buildDateField) remain the same
  // Make sure to add controller parameter to _buildTextField
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: !_isLoading,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'هذا الحقل مطلوب';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

Widget _buildTextField({
  required String label,
  String? initialValue,
  bool isRequired = false,
}) {
  return SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                }
              : null,
        ),
      ],
    ),
  );
}

Widget _buildDateField({
  required String label,
  required DateTime? selectedDate,
  required void Function()? onTap,
  bool isRequired = false,
}) {
  return SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(
              selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate)
                  : 'تحديث',
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _selectDate(
  BuildContext context,
  Function(DateTime) onDateSelected,
) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );
  if (picked != null) {
    onDateSelected(picked);
  }
}

const carBrands = [
  'Acura',
  'Alfa Romeo',
  'Aston Martin',
  'Audi',
  'BAIC',
  'Bestune',
  'BMW',
  'Bugatti',
  'Buick',
  'BYD',
  'Cadillac',
  'Changan',
  'Chery',
  'Chevrolet',
  'Chrysler',
  'Citroen',
  'CMC',
  'Daewoo',
  'Daihatsu',
  'Dodge',
  'Dongfeng',
  'Fiat',
  'Ford',
  'Foton',
  'GAC',
  'Geely',
  'GMC',
  'Great Wall',
  'Hafei',
  'Haval',
  'Hawtai',
  'Honda',
  'Hongqi',
  'Hummer',
  'Hunaghai',
  'Hyundai',
  'Infiniti',
  'Isuzu',
  'Iveco',
  'Jac',
  'Jaguar',
  'Jeep',
  'JMC',
  'Kaiyi',
  'Kia',
  'Lada',
  'Lancia',
  'Land Rover',
  'Lexus',
  'Lifan',
  'Lincoln',
  'Mahindra',
  'Maserati',
  'Mazda',
  'Mercedes Benz',
  'Mercury',
  'MG',
  'MINI',
  'Mitsubishi',
  'Mitsuoka',
  'Nissan',
  'Opel',
  'Other',
  'Peugeot',
  'Porsche',
  'Proton',
  'Renault',
  'Rover',
  'Saab',
  'Saic',
  'Samsung',
  'Saturn',
  'SEAT',
  'Skoda',
  'Skywell',
  'Smart',
  'SsangYong',
  'Subaru',
  'Suzuki',
  'TATA',
  'Tesla',
  'Toyota',
  'Volkswagen',
  'Volvo',
  'ZXAUTO',
  'اخرى'
];
const fuelTypes = [
  'هايبرد', // Hybrid
  'كهربائي', // Electric
  'ديزل', // Diesel
  'غاز', // Gas
  'بنزين' // Petrol/Gasoline
];
