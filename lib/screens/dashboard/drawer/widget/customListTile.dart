import '../../../../main.dart';
import 'package:flutter/material.dart';

class customListTile extends StatelessWidget {
  bool selected;
  IconData icon;
  String title;
  List<Widget> children;
  final VoidCallback? onTap;
  customListTile(
      {super.key,
      this.selected = false,
      required this.icon,
      required this.title,
      this.children = const [],
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return children.isEmpty
        ? ListTile(
            selected: selected,
            leading: Icon(
              icon,
              color: selected ? primary : const Color(0xff8f8f8f),
            ),
            //iconColor:Color(0xff8f8f8f),
            selectedTileColor: const Color(0xfff7f7f7),
            title: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? primary : const Color(0xff8f8f8f),
                  fontSize: 12),
            ),
            onTap: onTap,
          )
        : ExpansionTile(
            initiallyExpanded: true,
            leading: Icon(
              icon,
              color: selected ? primary : const Color(0xff8f8f8f),
            ),
            title: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? primary : const Color(0xff8f8f8f),
                  fontSize: 12),
            ),
            children: children,
          );
  }
}
