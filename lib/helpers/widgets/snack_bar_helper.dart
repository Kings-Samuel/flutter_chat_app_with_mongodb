import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';

snackBarHelper(BuildContext context, {required String message, AnimatedSnackBarType type = AnimatedSnackBarType.success}) {
  return AnimatedSnackBar.material(
    message,
    type: type,
    mobileSnackBarPosition: MobileSnackBarPosition.bottom,
    duration: const Duration(seconds: 5),
  ).show(context);
}
