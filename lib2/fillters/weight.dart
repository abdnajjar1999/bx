import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightSearchWidget extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  final TextEditingController weightController;
  final String? label;

  const WeightSearchWidget({
    Key? key,
    required this.onChanged,
    required this.weightController,
    this.label,
  }) : super(key: key);

  @override
  _WeightSearchWidgetState createState() => _WeightSearchWidgetState();
}

class _WeightSearchWidgetState extends State<WeightSearchWidget> {
  List<DocumentSnapshot> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.weightController.text.isNotEmpty) {
      _searchByWeight(widget.weightController.text);
    }
  }

  Future<void> _searchByWeight(String weight) async {
    if (weight.isEmpty || isDisposed) {
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
      double searchWeight = double.tryParse(weight) ?? 0.0;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('الوزن', isGreaterThanOrEqualTo: searchWeight)
          .where('الوزن', isLessThanOrEqualTo: searchWeight + 0.1)
          .limit(10)
          .get();

      if (!isDisposed && mounted) {
        setState(() {
          searchResults = snapshot.docs;
          isLoading = false;
        });
        
        if (snapshot.docs.isNotEmpty) {
          widget.onChanged(weight);
        } else {
          widget.onChanged(null);
        }
      }
    } catch (e) {
      print('Error searching orders by weight: $e');
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
        _searchByWeight(value);
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
      controller: widget.weightController,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'ادخل الوزن',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.scale),
        suffixIcon: widget.weightController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.weightController.clear();
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
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }
}