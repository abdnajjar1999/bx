import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerNameSearchWidget extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final TextEditingController customerNameController;
  final String? label;

  const CustomerNameSearchWidget({
    Key? key,
    required this.onChanged,
    required this.customerNameController,
    this.label,
  }) : super(key: key);

  @override
  _CustomerNameSearchWidgetState createState() => _CustomerNameSearchWidgetState();
}

class _CustomerNameSearchWidgetState extends State<CustomerNameSearchWidget> {
  List<DocumentSnapshot> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerNameController.text.isNotEmpty) {
      _searchByCustomerName(widget.customerNameController.text);
    }
  }

  Future<void> _searchByCustomerName(String name) async {
    if (name.isEmpty || isDisposed) {
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
      final queryText = name.toLowerCase().trim();

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('اسم العميل', isGreaterThanOrEqualTo: queryText)
          .where('اسم العميل', isLessThanOrEqualTo: queryText + '\uf8ff')
          .limit(10)
          .get();

      if (!isDisposed && mounted) {
        setState(() {
          searchResults = snapshot.docs;
          isLoading = false;
        });
        
        if (snapshot.docs.isNotEmpty) {
          widget.onChanged(name);
        } else {
          widget.onChanged(null);
        }
      }
    } catch (e) {
      print('Error searching orders by customer name: $e');
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
        _searchByCustomerName(value);
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
      controller: widget.customerNameController,
      decoration: InputDecoration(
        labelText: widget.label ?? 'اسم العميل',
        hintText: 'ادخل اسم العميل',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.person),
        suffixIcon: widget.customerNameController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.customerNameController.clear();
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
      onChanged: (value) {
        _onSearchChanged(value);
      },
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }
}
