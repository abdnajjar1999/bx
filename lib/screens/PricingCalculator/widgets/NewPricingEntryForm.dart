import '../../../shared/appProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/PriceCalculators.dart';
import '../PricingCalculator.dart';

class NewPricingEntryForm extends StatefulWidget {
  final VoidCallback onClose;
  final Function(ShippingRoute) onSubmit;
  final AppProvider appProvider;
  final ShippingRoute? initialRoute;

  const NewPricingEntryForm({
    Key? key,
    required this.onClose,
    required this.onSubmit,
    required this.appProvider,
    this.initialRoute,
  }) : super(key: key);

  @override
  State<NewPricingEntryForm> createState() => _NewPricingEntryFormState();
}

class _NewPricingEntryFormState extends State<NewPricingEntryForm> {
  final _formKey = GlobalKey<FormState>();
  String? fromRegion;
  String? toRegion;
  final TextEditingController _deliveryPriceController = TextEditingController();
  final TextEditingController _returnPriceController = TextEditingController();
  final TextEditingController _returnBeforeDeliveryPriceController = TextEditingController();
  String packageTypeName = 'العادية';

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      fromRegion = widget.initialRoute!.from;
      toRegion = widget.initialRoute!.to;
      _deliveryPriceController.text = widget.initialRoute!.deliveryPrice.toString();
      _returnPriceController.text = widget.initialRoute!.returnPrice.toString();
      _returnBeforeDeliveryPriceController.text = widget.initialRoute!.returnBeforeDeliveryPrice.toString();
      packageTypeName = widget.initialRoute!.packageTypeName ?? 'العادية';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: packageTypeName,
                  decoration: const InputDecoration(labelText: 'نوع الطرد', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: 'العادية', child: Text('العادية')),
                    ...widget.appProvider.packageTypes.map((pt) {
                      return DropdownMenuItem(value: pt.name, child: Text(pt.name));
                    }).toList(),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => packageTypeName = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: fromRegion,
                  decoration: const InputDecoration(labelText: 'من المنطقة', border: OutlineInputBorder()),
                  items: widget.appProvider.cities.map((String region) {
                    return DropdownMenuItem<String>(value: region, child: Text(region));
                  }).toList(),
                  validator: (value) => value == null ? 'الرجاء اختيار المنطقة' : null,
                  onChanged: (newValue) => setState(() => fromRegion = newValue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: toRegion,
                  decoration: const InputDecoration(labelText: 'إلى المنطقة', border: OutlineInputBorder()),
                  items: widget.appProvider.cities.map((String region) {
                    return DropdownMenuItem<String>(value: region, child: Text(region));
                  }).toList(),
                  validator: (value) => value == null ? 'الرجاء اختيار المنطقة' : null,
                  onChanged: (newValue) => setState(() => toRegion = newValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryPriceController,
                  decoration: const InputDecoration(labelText: 'سعر التوصيل', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال السعر';
                    if (double.tryParse(value) == null) return 'الرجاء إدخال رقم صحيح';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _returnPriceController,
                  decoration: const InputDecoration(labelText: 'سعر الإرجاع', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال السعر';
                    if (double.tryParse(value) == null) return 'الرجاء إدخال رقم صحيح';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _returnBeforeDeliveryPriceController,
                  decoration: const InputDecoration(labelText: 'سعر الإرجاع قبل التوصيل', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.check, color: Color(0xFFDC2626)), onPressed: _submitForm),
                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: widget.onClose),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newRoute = ShippingRoute(
        from: fromRegion!,
        to: toRegion!,
        deliveryPrice: double.parse(_deliveryPriceController.text),
        returnPrice: double.parse(_returnPriceController.text),
        returnBeforeDeliveryPrice: _returnBeforeDeliveryPriceController.text.isEmpty ? 0 : double.parse(_returnBeforeDeliveryPriceController.text),
        packageTypeName: packageTypeName,
      );

      widget.onSubmit(newRoute);
      widget.onClose();
    }
  }

  @override
  void dispose() {
    _deliveryPriceController.dispose();
    _returnPriceController.dispose();
    _returnBeforeDeliveryPriceController.dispose();
    super.dispose();
  }
}
