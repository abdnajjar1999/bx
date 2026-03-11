import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneNumberSearchWidget extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final TextEditingController phoneNumberController;
  final String? label;

  const PhoneNumberSearchWidget({
    Key? key,
    required this.onChanged,
    required this.phoneNumberController,
    this.label,
  }) : super(key: key);

  @override
  _PhoneNumberSearchWidgetState createState() => _PhoneNumberSearchWidgetState();
}

class _PhoneNumberSearchWidgetState extends State<PhoneNumberSearchWidget> {
  List<DocumentSnapshot> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumberController.text.isNotEmpty) {
      _searchOrdersByPhone(widget.phoneNumberController.text);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!isDisposed) {
        _searchOrdersByPhone(query);
      }
    });
  }

  Future<void> _searchOrdersByPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty || isDisposed) {
      if (!isDisposed) {
        setState(() {
          searchResults = [];
          isLoading = false;
        });
      }
      return;
    }

    if (!isDisposed) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('رقم الهاتف', isGreaterThanOrEqualTo: phoneNumber)
          .where('رقم الهاتف', isLessThan: phoneNumber + 'z')
          .limit(10)
          .get();

      if (!isDisposed && mounted) {
        setState(() {
          searchResults = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching orders: $e');
      if (!isDisposed && mounted) {
        setState(() {
          searchResults = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    isDisposed = true;
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.phoneNumberController,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'Search by phone number',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.phone),
        suffixIcon: widget.phoneNumberController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.phoneNumberController.clear();
                  widget.onChanged(null);
                  if (!isDisposed) {
                    setState(() {
                      searchResults = [];
                    });
                  }
                },
              )
            : (isLoading ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ) : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: (value) {
        _onSearchChanged(value);
        widget.onChanged(value);
      },
    );
  }
}