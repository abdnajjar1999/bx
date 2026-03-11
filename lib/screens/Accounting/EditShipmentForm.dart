import '../../shared/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../../models/Shipment.dart';
import '../../models/Driver.dart';
import '../../main.dart';

class EditShipmentForm extends StatefulWidget {
  final Shipment shipment;

  const EditShipmentForm({Key? key, required this.shipment}) : super(key: key);

  @override
  _EditShipmentFormState createState() => _EditShipmentFormState();
}

class _EditShipmentFormState extends State<EditShipmentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers
  late TextEditingController recipientNameController;
  late TextEditingController phoneController;
  late TextEditingController addressDescController;
  late TextEditingController notesController;
  late TextEditingController deliveryCostController;
  late TextEditingController codAmountController;

  // Dropdown values
  String? selectedStatus;
  Driver? selectedDriver;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    recipientNameController =
        TextEditingController(text: widget.shipment.recipientName);
    phoneController = TextEditingController(text: widget.shipment.phoneNumber);
    addressDescController =
        TextEditingController(text: widget.shipment.addressDescription);
    notesController = TextEditingController(text: widget.shipment.notes);
    deliveryCostController =
        TextEditingController(text: widget.shipment.deliveryCost.toString());
    codAmountController =
        TextEditingController(text: widget.shipment.codAmount.toString());
    selectedStatus = widget.shipment.status;

    // Initialize selectedDriver if driverId exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shipment.driverId != null) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        selectedDriver = appProvider.drivers.firstWhere(
          (driver) => driver.userid == widget.shipment.driverId,
          orElse: () => Driver(
              userid: '', username: ''), // Return empty Driver instead of null
        );
      }
    });
  }

  @override
  void dispose() {
    recipientNameController.dispose();
    phoneController.dispose();
    addressDescController.dispose();
    notesController.dispose();
    deliveryCostController.dispose();
    codAmountController.dispose();
    super.dispose();
  }

  void _handleSubmit(AppProvider appProvider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedShipment = widget.shipment.copyWith(
        recipientName: recipientNameController.text,
        phoneNumber: phoneController.text,
        addressDescription: addressDescController.text,
        notes: notesController.text,
        deliveryCost: double.parse(deliveryCostController.text),
        codAmount: double.parse(codAmountController.text),
        status: selectedStatus ?? widget.shipment.status,
        driverId: selectedDriver?.userid,
        driverName: selectedDriver?.username,
        lastUpdated: DateTime.now(),
      );

      appProvider.updateOrder(updatedShipment.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الشحنة بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildCustomerInfo(),
                    const SizedBox(height: 16),
                    _buildRecipientFields(),
                    const SizedBox(height: 16),
                    _buildStatusAndDriverFields(appProvider),
                    const SizedBox(height: 24),
                    _buildSubmitButton(appProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'تعديل الشحنة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معلومات العميل',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('اسم العميل: ${widget.shipment.username}'),
            Text('رقم التتبع: ${widget.shipment.trackingNumber}'),
            Text(
                'تاريخ الإنشاء: ${intl.DateFormat('yyyy-MM-dd').format(widget.shipment.createdAt)}'),
            Text('مبلغ التحصيل: ${widget.shipment.codAmount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: recipientNameController,
          label: 'اسم المستلم',
        ),
        _buildTextField(
          controller: phoneController,
          label: 'رقم الهاتف',
        ),
        _buildTextField(
          controller: addressDescController,
          label: 'وصف العنوان',
        ),
        _buildTextField(
          controller: deliveryCostController,
          label: 'تكلفة التوصيل',
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: codAmountController,
          label: 'مبلغ التحصيل',
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: notesController,
          label: 'ملاحظات',
          maxLines: 3,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildStatusAndDriverFields(AppProvider appProvider) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedStatus,
          decoration: InputDecoration(
            labelText: 'الحالة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            'طلبات جديدة',
            'في المركبة',
            'في الفرع',
            'تم توصيلها',
            'مرتجع',
          ]
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: (value) => setState(() => selectedStatus = value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Driver>(
          value: selectedDriver,
          decoration: InputDecoration(
            labelText: 'السائق',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            // Add null option to clear driver
            DropdownMenuItem<Driver>(
              value: null,
              child: Text('بدون سائق'),
            ),
            ...appProvider.drivers
                .map((driver) => DropdownMenuItem(
                      value: driver,
                      child: Text(driver.username ?? ''),
                    ))
                .toList(),
          ],
          onChanged: (value) => setState(() => selectedDriver = value),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = true,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: keyboardType,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildSubmitButton(AppProvider appProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _isLoading ? null : () => _handleSubmit(appProvider),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('حفظ التعديلات',
                style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
