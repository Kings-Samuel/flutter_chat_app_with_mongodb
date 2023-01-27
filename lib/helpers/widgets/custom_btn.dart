import 'package:flutter/material.dart';
import '../utils/color_palette.dart';
import 'custom_texts.dart';
import 'loading_animation.dart';

Widget customButton(
  BuildContext context, {
  required IconData icon,
  required String text,
  required bool isLoading,
  required VoidCallback onPressed,
  Color? backgroundColor,
  Color? textColor,
}) {
  if (isLoading == true) {
    return loadingAnimation();
  } else {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Palette.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            fixedSize: const Size(double.infinity, 50)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? Colors.white),
            const SizedBox(width: 10),
            bodyText(text: text, bold: true, color: Colors.white, fontSize: 17)
          ],
        ),
      ),
    );
  }
}