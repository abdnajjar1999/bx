import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNumberSearchWidget extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final TextEditingController orderNumberController;
  final String? label;

  const OrderNumberSearchWidget({
    Key? key,
    required this.onChanged,
    required this.orderNumberController,
    this.label,
  }) : super(key: key);

  @override
  _OrderNumberSearchWidgetState createState() => _OrderNumberSearchWidgetState();
}

class _OrderNumberSearchWidgetState extends State<OrderNumberSearchWidget> {
  List<DocumentSnapshot> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderNumberController.text.isNotEmpty) {
      _searchOrders(widget.orderNumberController.text);
    }
  }

  Future<void> _searchOrders(String orderNumber) async {
    if (orderNumber.isEmpty || isDisposed) {
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
          .where('رقم الطلب', isGreaterThanOrEqualTo: orderNumber)
          .where('رقم الطلب', isLessThanOrEqualTo: orderNumber + '\uf8ff')
          .limit(10)
          .get();

      if (!isDisposed && mounted) {
        setState(() {
          searchResults = snapshot.docs;
          isLoading = false;
        });
        if (snapshot.docs.isNotEmpty) {
          widget.onChanged(orderNumber);
        } else {
          widget.onChanged(null);
        }
      }
    } catch (e) {
      print('Error searching orders: $e');
      if (!isDisposed && mounted) {
        setState(() {
          searchResults = [];
          isLoading = false;
        });
        widget.onChanged(null);
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!isDisposed) {
        _searchOrders(value);
      }
    });
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
      controller: widget.orderNumberController,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'Search order number',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.orderNumberController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.orderNumberController.clear();
                  widget.onChanged(null);
                  if (!isDisposed) {
                    setState(() {
                      searchResults = [];
                    });
                  }
                },
              )
            : (isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: _onSearchChanged,
    );
  }
}