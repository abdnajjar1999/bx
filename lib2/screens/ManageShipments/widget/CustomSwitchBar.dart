import '../../../main.dart';
import 'package:flutter/material.dart';

import 'CustomContainer.dart';

class CustomSwitchBar extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double switchScale;

  CustomSwitchBar({
    required this.label,
    required this.value,
    required this.onChanged,
    this.switchScale = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomContainer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
          ),
          const SizedBox(width: 8.0),
          Transform.scale(
            scale: switchScale, // تطبيق مقياس التصغير هنا
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: primary,
              activeTrackColor: primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
