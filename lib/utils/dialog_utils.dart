import 'package:flutter/material.dart';

Future<T?> showFadeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration transitionDuration = const Duration(milliseconds: 300),
}) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: transitionDuration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child, // Using ScaleTransition here as well for "zoom-in" effect? User asked for fade. Web has fade+zoom.
        // Let's add a subtle scale to match web's zoom-in-95?
      );
    },
  );
}
