import 'package:flutter/material.dart';

class Customtext extends StatelessWidget {
  String title;
  Color? color;
  Customtext({super.key,required this.title,this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SelectableText(get_str(title),
      textAlign: TextAlign.center,
      style: TextStyle(color: color),),

    );
  }
  String get_str(String value){
    if(value!="" && value!=null){
      return value;
    }
    return "";
  }
}
