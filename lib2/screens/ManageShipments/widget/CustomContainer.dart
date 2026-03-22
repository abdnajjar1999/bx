import 'package:flutter/material.dart';

class CustomContainer extends StatelessWidget {
  Widget child;
  CustomContainer({super.key,required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
    margin: const EdgeInsets.only(right: 5.0,left: 5.0),
    padding: const EdgeInsets.all(5.0),
    decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(8.0),
    ),
    child:child ,
    );
  }
}
