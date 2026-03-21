import '../../../main.dart';
import 'package:flutter/material.dart';

class customBox extends StatelessWidget {
  String title;
  bool is_color;
  String count;
  customBox(
      {super.key,
      required this.title,
      this.is_color = false,
      this.count = '0'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(right: 10, left: 10),
      decoration: is_color
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: const LinearGradient(
                colors: [primary, Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(16.0), color: primary),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                //fontSize: 14,
                //fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                color: Colors.white,
                // fontSize: 32,
                // fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
