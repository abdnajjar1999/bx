import 'package:flutter/material.dart';

enum DrawerSide {
  left,
  right,
}

void showSideDrawerDialog({
  required BuildContext context,
  required Widget child,
  
  DrawerSide side = DrawerSide.left,
  double? width,
  Duration? duration,
  Color? barrierColor,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: duration ?? const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(side == DrawerSide.left ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: Align(
          alignment: side == DrawerSide.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: width ?? MediaQuery.of(context).size.width * 0.70,
              height: MediaQuery.of(context).size.height,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
