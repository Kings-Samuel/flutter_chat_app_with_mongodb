import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget loadingAnimation() {
  return Center(child: LoadingAnimationWidget.threeArchedCircle(color: Palette.green, size: 30));
}