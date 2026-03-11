import '../../../shared/constants.dart';

import '../../../main.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String? labelText;
  final IconData? prefixIcon;
  final double width;
  final String? hintText;
  final bool isExpanded;
  final bool? childRow;
  final void Function()? onClearPressed;

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.onChanged,
    this.value,
    this.labelText,
    this.prefixIcon,
    this.width = 150,
    this.hintText,
    this.isExpanded = true,
    this.onClearPressed,
    this.childRow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: (value != null && items.contains(value)) ? value : null,
        isExpanded: isExpanded,
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: value != null
              ? IconButton(
                  onPressed: onClearPressed, icon: const Icon(Icons.clear))
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelText: labelText,
          labelStyle: TextStyle(
            color: value == null ? Colors.black : primary,
          ),
          hintText: hintText,
        ),
        icon: const Icon(Icons.arrow_drop_down),
        items: items.toSet().map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: childRow == null
                ? Text(item)
                : Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: getStatusColor(item),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        width: 16,
                        height: 16,
                      ),
                      Text(item),
                    ],
                  ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

Widget buildDropdownField({
  required String label,
  required String hint,
  required void Function(dynamic)? onChanged,
  List<DropdownMenuItem<dynamic>>? items,
  dynamic? value,
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
        DropdownButtonFormField<dynamic>(
          items: items,
          onChanged: onChanged,
          value: (value != null &&
                  items != null &&
                  items.any((item) => item.value == value))
              ? value
              : null,
          decoration: InputDecoration(
            hintText: hint,
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
