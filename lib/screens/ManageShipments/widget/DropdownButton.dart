import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../main.dart';
import 'package:flutter/material.dart';

import '../../../fillters/costomername.dart';

class CustomForm extends StatefulWidget {
  final String title;
  final List<FormField> fields;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final Color backgroundColor;
  final double width;
  final double height;
  final String cancelButtonText;
  final String submitButtonText;
  final Color submitButtonColor;

  const CustomForm({
    Key? key,
    required this.title,
    required this.fields,
    this.onCancel,
    this.onSubmit,
    this.backgroundColor = Colors.black87,
    this.width = 200,
    this.height = 200,
    this.cancelButtonText = 'إلغاء',
    this.submitButtonText = 'تم',
    this.submitButtonColor = primary,
  }) : super(key: key);

  @override
  State<CustomForm> createState() => _CustomFormState();
}

class _CustomFormState extends State<CustomForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            ...widget.fields.map((field) => _buildFormField(field)).toList(),
            const SizedBox(height: 8),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FormField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          field.label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 30,
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
            child: field.buildField(context),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              widget.cancelButtonText,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        const SizedBox(width: 4),
        if (widget.onSubmit != null)
          ElevatedButton(
            onPressed: widget.onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.submitButtonColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              widget.submitButtonText,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
      ],
    );
  }
}

abstract class FormField {
  final String label;

  FormField({required this.label});

  Widget buildField(BuildContext context);
}

class TextFormField extends FormField {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  TextFormField({
    required String label,
    required this.controller,
    this.onChanged,
    this.hintText,
  }) : super(label: label);

  @override
  Widget buildField(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 10),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
    );
  }
}

class DropdownFormField extends FormField {
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? hintText;

  DropdownFormField({
    required String label,
    required this.items,
    this.value,
    this.onChanged,
    this.hintText,
  }) : super(label: label);

  @override
  Widget buildField(BuildContext context) {
    return DropdownButtonFormField2<String>(
      dropdownStyleData: DropdownStyleData(
        decoration: BoxDecoration(
          color: Colors.black87,
        ),
        offset: const Offset(-290, 0),
      ),
      alignment: AlignmentDirectional.centerEnd,
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      hint: Text(
        hintText ?? 'يرجى الاختيار او البحث',
        style: const TextStyle(color: Colors.grey, fontSize: 10),
        textAlign: TextAlign.right,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 10),
    );
  }
}

// Example usage:
class CustomSearchField extends FormField {
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;

  CustomSearchField({
    required String label,
    required this.controller,
    required this.onChanged,
  }) : super(label: label);

  @override
  Widget buildField(BuildContext context) {
    return CustomerNameSearchWidget(
      label: "al",
      onChanged: onChanged,
      customerNameController: controller,
    );
  }
}
