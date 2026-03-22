import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PriceSearchWidget extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final TextEditingController priceController;
  final String? label; // Add label parameter

  const PriceSearchWidget({
    Key? key,
    required this.onChanged,
    required this.priceController,
    this.label, // Make label optional
  }) : super(key: key);

  @override
  _PriceSearchWidgetState createState() => _PriceSearchWidgetState();
}

class _PriceSearchWidgetState extends State<PriceSearchWidget> {
  List<DocumentSnapshot> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.priceController.text.isNotEmpty) {
      _searchByPrice(widget.priceController.text);
    }
  }

  Future<void> _searchByPrice(String price) async {
    if (price.isEmpty || isDisposed) {
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
      double searchPrice = double.tryParse(price) ?? 0.0;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('السعر', isGreaterThanOrEqualTo: searchPrice)
          .where('السعر', isLessThanOrEqualTo: searchPrice + 0.1)
          .limit(10)
          .get();

      if (!isDisposed && mounted) {
        setState(() {
          searchResults = snapshot.docs;
          isLoading = false;
        });
        
        if (snapshot.docs.isNotEmpty) {
          widget.onChanged(price);
        } else {
          widget.onChanged(null);
        }
      }
    } catch (e) {
      print('Error searching orders by price: $e');
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
        _searchByPrice(value);
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
      controller: widget.priceController,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'Search by Price',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.attach_money),
        suffixIcon: widget.priceController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.priceController.clear();
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
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: _onSearchChanged,
    );
  }
}