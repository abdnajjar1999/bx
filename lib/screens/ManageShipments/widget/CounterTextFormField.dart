import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CounterTextFormField extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final double min;
  final double max;
  final double step;
  final bool isInteger;
  final double initialValue;
  const CounterTextFormField({
    Key? key,
    this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.min = 0,
    this.max = double.infinity,
    this.step = 1,
    this.isInteger = true,
    required this.initialValue,
  }) : super(key: key);

  @override
  State<CounterTextFormField> createState() => _CounterTextFormFieldState();
}

class _CounterTextFormFieldState extends State<CounterTextFormField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void didUpdateWidget(CounterTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (double.tryParse(_controller.text) != widget.initialValue) {
        _controller.text = widget.initialValue.toString();
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _increment() {
    double currentValue = double.tryParse(_controller.text) ?? widget.min;
    double newValue = currentValue + widget.step;

    if (newValue <= widget.max) {
      // String formattedValue = widget.isInteger
      //     ? newValue.toInt().toString()
      //     : newValue.toStringAsFixed(1);

      // _controller.text = formattedValue;
      widget.onChanged?.call(newValue.toString());
    }
  }

  void _decrement() {
    double currentValue = double.tryParse(_controller.text) ?? widget.min;
    double newValue = currentValue - widget.step;

    if (newValue >= widget.min) {
      String formattedValue = widget.isInteger
          ? newValue.toInt().toString()
          : newValue.toStringAsFixed(2);

      _controller.text = formattedValue;
      widget.onChanged?.call(formattedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      validator: widget.validator,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(widget.isInteger ? r'[0-9]' : r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: InputBorder.none,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 35.0),
          child: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _decrement,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(left: 35.0),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _increment,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      onChanged: (value) {
        double? numValue = double.tryParse(value);
        if (numValue != null) {
          if (numValue > widget.max) {
            _controller.text = widget.max.toString();
          } else if (numValue < widget.min) {
            _controller.text = widget.min.toString();
          }
          widget.onChanged?.call(_controller.text);
        }
      },
    );
  }
}
