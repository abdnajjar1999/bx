import '../../../../main.dart';
import '../../../../sadrad/colors.dart';
import 'package:flutter/material.dart';

class customListTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final List<Widget> children;
  final VoidCallback? onTap;

  const customListTile({
    super.key,
    this.selected = false,
    required this.icon,
    required this.title,
    this.children = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          selected: selected,
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            icon,
            color: selected ? primary : SadradColors.textSecondary,
            size: 20,
          ),
          selectedTileColor: primary.withOpacity(0.08),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? primary : SadradColors.textPrimary,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
        ),
      );
    } else {
      return ExpansionTile(
        initiallyExpanded: false,
        shape: const Border(),
        leading: Icon(
          icon,
          color: SadradColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: SadradColors.textPrimary,
            fontSize: 13,
          ),
        ),
        children: children,
      );
    }
  }
}
