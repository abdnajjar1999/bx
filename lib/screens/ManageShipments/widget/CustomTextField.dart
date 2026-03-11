import 'package:flutter/material.dart';

import '../../../main.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function(String)? onEditingComplete;
  final String? Function(String?)? validator;
  final double width;
  final VoidCallback? onTap; // Add this
  final bool readOnly; // Add this

  const CustomTextField({
    Key? key,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.width = 150,
    this.onTap, // Add this
    this.readOnly = false, // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        readOnly: readOnly, // Add this
        onTap: onTap, // Add this
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          labelStyle: TextStyle(
            color: controller!.text.isEmpty ? Colors.black : primary,
          ),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller!.text.isNotEmpty)
                IconButton(
                  onPressed: () => controller!.clear(),
                  icon: const Icon(Icons.clear),
                ),
              if (onEditingComplete != null && controller!.text.isNotEmpty)
                IconButton(
                  onPressed: () => onEditingComplete!(controller!.text),
                  icon: const Icon(Icons.check),
                ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
