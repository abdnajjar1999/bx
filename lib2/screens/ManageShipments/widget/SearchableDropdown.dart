import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../main.dart';
import '../../../models/customer.dart';
import '../../../models/Driver.dart';

Widget SearchableDropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required Function(T?) onChanged,
  required TextEditingController searchController,
  String? hint,
  bool isRequired = true,
  IconData? prefixIcon,
  VoidCallback? onClearPressed,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField2<T>(
      isExpanded: true,
      hint: Text(hint ?? 'اختر $label'),
      value: (value != null && items.contains(value)) ? value : null,
      buttonStyleData: const ButtonStyleData(
        padding: EdgeInsets.symmetric(horizontal: 16),
        height: 40,
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: value != null && onClearPressed != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClearPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dropdownSearchData: DropdownSearchData(
        searchController: searchController,
        searchInnerWidgetHeight: 50,
        searchInnerWidget: Container(
          height: 50,
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 4,
            right: 8,
            left: 8,
          ),
          child: TextField(
            autofocus: true,
            expands: true,
            maxLines: null,
            controller: searchController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: 'البحث عن $label...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) {
          if (T == Customer) {
            final customer = item.value as Customer;
            return customer.username
                .toLowerCase()
                .contains(searchValue.toLowerCase());
          } else if (T == Driver) {
            final driver = item.value as Driver;
            return (driver.username ?? '')
                .toLowerCase()
                .contains(searchValue.toLowerCase());
          }

          return item.value
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase());
        },
      ),
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            T == Customer
                ? (item as Customer).username
                : T == Driver
                    ? (item as Driver).username ?? ''
                    : item.toString(),
          ),
        );
      }).toList(),
      validator: isRequired
          ? (value) {
              if (value == null) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            }
          : null,
    ),
  );
}
