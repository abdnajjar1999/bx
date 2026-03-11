import '../../../main.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets padding;
  final IconData? icon;
  final Color? iconColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final bool enabled;

  const CustomButton(
      {Key? key,
      required this.text,
      this.onPressed,
      this.color = primary,
      this.textColor = Colors.white,
      this.fontSize = 16.0,
      this.borderRadius = 8.0,
      this.padding = const EdgeInsets.all(10.0),
      this.icon,
      this.iconColor,
      this.width,
      this.height,
      this.isLoading = false,
      this.enabled = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5.0, left: 5.0),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          onPressed: (enabled && !isLoading) ? onPressed : null,
          child: isLoading
              ? CircularProgressIndicator(color: textColor)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor ?? textColor),
                      const SizedBox(width: 8.0),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
